Shader "Tutorial/16_ParallaxMapping"
{
    Properties
    {
		_MainTex("Main Texture", 2D) = "white" {}
		[Normal] _BumpMap("Normal", 2D) = "bump" {}
		_Shininess("Shiny", Float) = 8
		[NoScaleOffset] _ParallaxMap("Heightmap", 2D) = "black" {}
		_Parallax("Height Factor", Range(0.0, 0.5)) = 0.01
		_MaxOffset("Max Offset", Range(0.0, 0.5)) = 0.01
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

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            // --- NEW ---
            // We need this one for just once function
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
            
            
            // This is where we now use a new function to clean up the fragment shader, as stuff like this can get very long 
            float2 ParallaxMapping(float2 uv, float3 viewDirTS)
            {
            	// we simply sample the depth of the parallax/height map at the current uv coordinate
	            float depth = SAMPLE_TEXTURE2D(_ParallaxMap, sampler_ParallaxMap, TRANSFORM_TEX(uv, _BumpMap));
            	
            	// using the view direction in tangent space, we determine how far we look "into" the texture
				float2 texCoordOffset = viewDirTS.xy / viewDirTS.z * depth * _Parallax;
				
            	// now we just subtract the new offset from the original UVs. We also clamp the offset, so it doesn't get beyond
            	// the point where the effect breaks apart
            	return uv - clamp(texCoordOffset, -_MaxOffset, _MaxOffset);
            }

            
            float4 frag(Varyings IN) : COLOR 
            {
            	float3 viewDirWS = GetWorldSpaceNormalizeViewDir(IN.positionWS);
            	
            	// This is the new function we the include file for
				float3 viewDirTS = GetViewDirectionTangentSpace(IN.tangentWS, IN.normalWS, viewDirWS);
            	
            	// This is where the magic happens, everything else is the same
				float2 uv = ParallaxMapping(IN.uv, viewDirTS);
            	
            	float4 encodedNormal = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, TRANSFORM_TEX(uv, _BumpMap));
				
            	float3 normalTS = UnpackNormal(encodedNormal);
            	float3x3 tangentToWorld = CreateTangentToWorld(IN.normalWS, IN.tangentWS.xyz, IN.tangentWS.w);
            	float3 normalWS = TransformTangentToWorldDir(normalTS, tangentToWorld, true);
            	
            	
            	Light light = GetMainLight();
            	float3 viewDir = GetWorldSpaceNormalizeViewDir(IN.positionWS);
            
            	float NdotL = saturate(dot(light.direction, normalWS));
            	
            	float3 objectColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, TRANSFORM_TEX(uv, _MainTex));
            	float3 diffuseReflection = objectColor * NdotL * light.color;
            	
            	float3 reflectedLightVector = reflect(light.direction, normalWS);
            	float VdotL = saturate(dot(-viewDir, reflectedLightVector));
            	float3 specularReflection = pow(VdotL, _Shininess) * light.color;
            	float3 ambientLight = EvaluateAmbientProbe(normalWS) * objectColor;
            	
            	float3 color = diffuseReflection + specularReflection + ambientLight;
            	
            	return float4(color, 1);
            }
            	
			ENDHLSL
        }
    }
}