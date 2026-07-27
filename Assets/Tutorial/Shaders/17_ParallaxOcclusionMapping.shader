Shader "Tutorial/17_ParallaxOcclusionMapping"
{
	// This one is going to be crazy. Don't use this as a standard of what you should do, but instead, what is possible.
	
    Properties
    {
		_MainTex("Main Texture", 2D) = "white" {}
		[Normal] _BumpMap("Normal", 2D) = "bump" {}
		_Shininess("Shiny", Float) = 8
		[NoScaleOffset] _ParallaxMap("Heightmap", 2D) = "black" {}
		_Parallax("Height", Range(0.0, 0.5)) = 0.01
    	
    	_NumSteps("Parallax Step Limit", Range(1, 32)) = 16
		
        [Toggle] _FLIP_HEIGHT("Flip Height Texture", Int) = 0
    }
    

    SubShader 
    {
    	Tags 
        { 
            "RenderPipeline" = "UniversalPipeline" 
            "RenderType" = "Opaque" 
            "Queue" = "Geometry" 
        }

        Pass 
        {
            HLSLPROGRAM 

            #pragma shader_feature _ _FLIP_HEIGHT_ON
            
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"
            
            
            struct Attributes
            {
            	float4 positionOS : POSITION;
            	float4 uv : TEXCOORD0;
            	float3 normal : NORMAL;
            	float4 tangent : TANGENT;
            };
            
            struct Varyings
            {
            	float4 positionHCS : SV_POSITION;
            	float4 uv : TEXCOORD0;
            	float3 positionWS : TEXCOORD1;
            	float4 tangentWS : TEXCOORD2;
            	float3 normalWS : TEXCOORD3;
            };

            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_BumpMap);
            SAMPLER(sampler_BumpMap);
            TEXTURE2D(_ParallaxMap);
            SAMPLER(sampler_ParallaxMap);
			
            CBUFFER_START(UnityPerMaterial)
            	float4 _MainTex_ST;
            	float4 _BumpMap_ST;
            	float _Shininess;
            	float _Parallax;
            	float _MaxOffset;
				float _NumSteps;
            CBUFFER_END
            
            // Shader Functions-----------------------
            Varyings vert(Attributes IN)
            {
            	Varyings OUT;
            	
				// New way of doing it
            	VertexNormalInputs inputs = GetVertexNormalInputs(IN.normal, IN.tangent);
            	OUT.tangentWS = float4(inputs.tangentWS, IN.tangent.w * GetOddNegativeScale());
            	OUT.normalWS = inputs.normalWS;

            	float3 viewDirObj = TransformWorldToObject(GetCameraPositionWS()) - IN.positionOS.xyz;
            	
            	OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
            	OUT.positionWS = TransformObjectToWorld(IN.positionOS);
            	OUT.uv = IN.uv;
            	
            	return OUT;
            }

            // Some height map textures act more as depth map, i.e. they cave inwards. For this, we made this function
            // so that we can apply the flip to it, if it has been selected in the material properties
            float SampleHeightMap(float2 uv)
            {
            	float sample = SAMPLE_TEXTURE2D_LOD(_ParallaxMap, sampler_ParallaxMap, TRANSFORM_TEX(uv, _BumpMap), 0).r;
#ifdef _FLIP_HEIGHT_ON
            	sample = 1 - sample;
#endif
            	return sample;
            }

			// This is going to be a big one
            // It's really complicated and I had to look up how it works and how to write your own, so don't be discouraged if you don't get it!
            // A lot of advanced shader stuff is just faking it till you are making it, and that means finding stuff on GitHub and rolling with it.
            // The basic gist is, we step through the texture layer by layer and see, if the current height map sample is above the current depth
            // of our loop. If that is the case, then we have "hit" the height map and close out of the loop, meaning we found our perceived uv
			float2 ParallaxOcclusionMapping(float2 uv, float3 viewDirTS)
            {
            	int numLayers = _NumSteps;
            	
				// Calculate the size of a single layer
				float layerDepth = 1.0 / numLayers;
            	
            	// Determine the step vector based on our view angle
            	float2 P = viewDirTS.xy / viewDirTS.z * _Parallax;
            	float2 stepVector = P / numLayers;
            	
				// Initialise and set starting values before the loop
            	float currentLayerDepth = 0;
				float2 currentUV = uv;
            	float currentDepthMap = SampleHeightMap(currentUV);
            	
            	int i = 0;
            	while(currentLayerDepth < currentDepthMap && i < numLayers)
            	{
            		// stepping through the texture
            		currentUV -= stepVector;
            		currentDepthMap = SampleHeightMap(currentUV);
            		
            		// Also 
            		currentLayerDepth += layerDepth;
            		i++;
            	}

            	float2 previousUV = currentUV + stepVector;
				// get depth after and before collision for linear interpolation
				float surfaceOffsetAfterDepth = currentDepthMap - currentLayerDepth;
				float surfaceOffsetBeforeDepth = SampleHeightMap(previousUV) - currentLayerDepth + layerDepth;
            	
            	// interpolation of texture coordinates
				float weight = surfaceOffsetAfterDepth / (surfaceOffsetAfterDepth - surfaceOffsetBeforeDepth);
				float2 finalUV = previousUV * weight + currentUV * (1.0 - weight);
            	
				return finalUV;
            }
            
            
            // I found this online and this is very similar, this time, we can even find out if the height map is supposed
            // to occlude the light, so we get self-shadowing from the height map as well.
            // We can use this to multiple with our light results in the specular and diffuse reflection.
            float ParallaxSelfShadowing(float2 uv, float3 lightDirTS)
			{
            	int numLayers = _NumSteps;
            	
			    if (lightDirTS.z <= 0) return 0.0;
			
			    float layerDepth = 1.0 / numLayers;
			
			    float2 p = lightDirTS.xy / lightDirTS.z * _Parallax; // Normalize step size
			    float2 stepVector = p / numLayers;
			
			    float2 currentUV = uv;
			    float currentDepthMapValue = SampleHeightMap(uv);
			    float currentLayerDepth = currentDepthMapValue;
			
			    float shadowBias = 0.05; // Bias to reduce self-shadowing
			    int maxIterations = 32; // Cap iterations
			    int iterationCount = 0;
			
			    // Traverse along the light direction
			    while (currentLayerDepth <= currentDepthMapValue + shadowBias && currentLayerDepth > 0.0 && iterationCount < maxIterations)
			    {
			        currentUV += stepVector;
			        currentDepthMapValue = SampleHeightMap(currentUV);
			        currentLayerDepth -= layerDepth;
			        iterationCount++;
			    }
			
			    return currentLayerDepth > currentDepthMapValue ? 0.0 : 1.0; // No occlusion = fully lit
			}

            
            
            float4 frag(Varyings IN) : COLOR 
            {
            	float3 viewDirWS = GetWorldSpaceNormalizeViewDir(IN.positionWS);
				float3 viewDirTS = GetViewDirectionTangentSpace(IN.tangentWS, IN.normalWS, viewDirWS);
            	
            	// This is where the magic happens, everything else is the same
				float2 uv = ParallaxOcclusionMapping(IN.uv, viewDirTS);
            	
            	float4 encodedNormal = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, TRANSFORM_TEX(uv, _BumpMap));
				
            	float3 normalTS = UnpackNormal(encodedNormal);
            	float3x3 tangentToWorld = CreateTangentToWorld(IN.normalWS, IN.tangentWS.xyz, IN.tangentWS.w);
            	float3 normalWS = TransformTangentToWorldDir(normalTS, tangentToWorld, true);
            	
            	
            	Light light = GetMainLight();
            	float3 viewDir = GetWorldSpaceNormalizeViewDir(IN.positionWS);
            	
            	// This is the part for the self-shadowing.
            	float3 lightDirTS = GetViewDirectionTangentSpace(IN.tangentWS, IN.normalWS, light.direction);
				float selfShadowing = ParallaxSelfShadowing(uv, lightDirTS);
            	
            	float NdotL = saturate(dot(light.direction, normalWS));
            	
            	float3 objectColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, TRANSFORM_TEX(uv, _MainTex));
            	// Here I'm just multipling the light results with the selfShadowing factor.
            	float3 diffuseReflection = objectColor * NdotL * light.color * selfShadowing;
            	
            	float3 reflectedLightVector = reflect(light.direction, normalWS);
            	float VdotL = saturate(dot(-viewDir, reflectedLightVector));
            	// Same here.
            	float3 specularReflection = pow(VdotL, _Shininess) * light.color * selfShadowing;
            	float3 ambientLight = EvaluateAmbientProbe(normalWS) * objectColor;
            	
            	float3 color = diffuseReflection + specularReflection + ambientLight;
            	
            	return float4(color, 1);
            }
            	
			ENDHLSL
        }
    }
}