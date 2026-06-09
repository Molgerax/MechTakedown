// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Tutorial/16_ParallaxMapping" //define the name & folders of our Shader (SurfaceShader)
{
    Properties
    {
		_BumpMap("Normal", 2D) = "bump" {}
		_Color("Diff Color", Color) = (1, 1, 1, 1)
		_Shininess("Shiny", Float) = 8
		_ParallaxMap("Heightmap", 2D) = "black" {}
		_Parallax("Height", Range(0.0, 0.5)) = 0.01
		_MaxOffset("Max Offset", Range(0.0, 0.5)) = 0.01
    }
    

    SubShader //multiple subshaders for different GPUs, Unity will choose the most suited one for current application
    {
    	Tags 
        { 
            "RenderPipeline" = "UniversalPipeline" 
            "RenderType" = "Opaque" 
            "Queue" = "Geometry" 
        }

        Pass //PASS 0 -- BASE with Ambient Light
        {
			Tags {"LightMode" = "UniversalForward"}

            HLSLPROGRAM //here starts the pure Cg shader code

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"
            
            
            struct Attributes
            {
            	float4 pos : POSITION;
            	float4 uv : TEXCOORD0;
            	float3 normal : NORMAL;
            	float4 tangent : TANGENT;
            };
            
            struct Varyings
            {
            	float4 pos : SV_POSITION;
            	float4 uv : TEXCOORD0;
            	float3 posWS : TEXCOORD1;
            	float4 tangentWS : TEXCOORD2;
            	float3 normalWS : TEXCOORD3;
            	float3 binormalWS : TEXCOORD4;
				float3 viewDirWS : TEXCOORD5;
            	float3 viewDirSSC : TEXCOORD6; //scaled surface coords
            };

            
            TEXTURE2D(_BumpMap);
            SAMPLER(sampler_BumpMap);
            TEXTURE2D(_ParallaxMap);
            SAMPLER(sampler_ParallaxMap);
			
            CBUFFER_START(UnityPerMaterial)
            	float4 _LightColor0;
            	float4 _BumpMap_ST;
				float4 _ParallaxMap_ST;
            	float4 _Color;
            	float _Shininess;
            	float _Parallax;
            	float _MaxOffset;
            CBUFFER_END
            
            // Shader Functions-----------------------
            Varyings vert(Attributes IN)
            {
            	Varyings output;


            	// Old way of doing it
            	output.tangentWS = float4(TransformObjectToWorld(IN.tangent.xyz), IN.tangent.w);
            	output.normalWS = TransformObjectToWorldNormal(IN.normal);
            	output.binormalWS = normalize(cross(output.normalWS, output.tangentWS) 
            							* IN.tangent.w); //input.tangent.w specific to unity

				// New way of doing it
            	VertexNormalInputs inputs = GetVertexNormalInputs(IN.normal, IN.tangent);
            	output.tangentWS = float4(inputs.tangentWS, IN.tangent.w);
            	output.normalWS = inputs.normalWS;
            	output.binormalWS = inputs.tangentWS;

            	float3 viewDirObj = TransformWorldToObject(GetCameraPositionWS()) - IN.pos.xyz;
            	
            	output.pos = TransformObjectToHClip(IN.pos);
            	output.posWS = TransformObjectToWorld(IN.pos);
            	output.uv = IN.uv;
				output.viewDirWS = GetCameraPositionWS() - output.posWS;
				output.viewDirSSC = TransformObjectToTangent(viewDirObj, CreateTangentToWorld(IN.normal, IN.tangent.xyz, IN.tangent.w));
            	
            	return output;
            }

            float2 ParallaxMapping(float2 uv, float3 viewDirTS)
            {
	            float height = _Parallax * (SAMPLE_TEXTURE2D(_ParallaxMap, sampler_ParallaxMap, uv.xy 
						* _BumpMap_ST.xy + _BumpMap_ST.zw).x);
		
				float2 texCoordOffset = clamp(height * viewDirTS.xy / viewDirTS.z, -_MaxOffset, _MaxOffset);
				return texCoordOffset + uv;
            }

			float2 ParallaxOcclusionMapping(float2 uv, float3 viewDirTS)
            {
            	int numLayers = 5;
				float layerDepth = 1.0 / numLayers;
            	float currentLayerDepth = 0;

            	float2 P = viewDirTS.xy * _Parallax;
            	float2 deltaUV = P / numLayers;

				float2 currentUV = uv;
            	float currentDepthMap = SAMPLE_TEXTURE2D(_ParallaxMap, sampler_ParallaxMap, currentUV.xy * _BumpMap_ST.xy + _BumpMap_ST.zw).r;
            	int i = 0;

            	while(currentLayerDepth < currentDepthMap && i < numLayers)
            	{
            		currentUV += deltaUV;
            		currentDepthMap =  SAMPLE_TEXTURE2D(_ParallaxMap, sampler_ParallaxMap, currentUV.xy * _BumpMap_ST.xy + _BumpMap_ST.zw).r;
            		currentLayerDepth += layerDepth;
            		i++;
            	}

            	float2 prevTexCoords = currentUV - deltaUV;
				// get depth after and before collision for linear interpolation
				float afterDepth = currentDepthMap - currentLayerDepth;
				float beforeDepth = SAMPLE_TEXTURE2D(_ParallaxMap, sampler_ParallaxMap, prevTexCoords.xy * _BumpMap_ST.xy + _BumpMap_ST.zw).r - currentLayerDepth + layerDepth;
				// interpolation of texture coordinates
				float weight = afterDepth / (afterDepth - beforeDepth);
				float2 finalUV = prevTexCoords * weight + currentUV * (1.0 - weight);
            	
				return finalUV;
            }
            
            
            float4 frag(Varyings input) : COLOR 
            {
				float3 viewDirTS = GetViewDirectionTangentSpace(input.tangentWS, input.normalWS, input.viewDirWS);
				//viewDirTS = input.viewDirSSC;
            	
            	float height = _Parallax * (SAMPLE_TEXTURE2D(_ParallaxMap, sampler_ParallaxMap, input.uv.xy 
						* _BumpMap_ST.xy + _BumpMap_ST.zw).x);
		
				float2 texCoordOffset = clamp(height * viewDirTS.xy / viewDirTS.z, -_MaxOffset, _MaxOffset);

            	texCoordOffset = ParallaxOcclusionMapping(input.uv, viewDirTS);
            	
            	float4 encodedNormal = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, (texCoordOffset) * _BumpMap_ST.xy + _BumpMap_ST.zw);
				
            	// New way
            	float3 normalTS = UnpackNormal(encodedNormal);
            	float3x3 tangentToWorld = CreateTangentToWorld(input.normalWS, input.tangentWS.xyz, input.tangentWS.w);
            	float3 normalDir = TransformTangentToWorldDir(normalTS, tangentToWorld, true);
            	
            	
            	float3 viewDir = normalize(_WorldSpaceCameraPos - input.posWS.xyz);

            	Light light = GetMainLight();
            	
            
            	float3 diffRefl = _LightColor0.rgb * _Color.rgb * max(0, dot(normalDir, light.direction));
            	
            	float3 ambientLight = UNITY_LIGHTMODEL_AMBIENT.rgb * _Color.rgb;
            
            	float specCutOff = step(0, dot(normalDir, light.direction)); //if dot is bigger than 0, return 1, else 0
            
            	float3 specRefl = pow(max(0, dot(viewDir, reflect(-light.direction, normalDir))), _Shininess) 
            						  * _LightColor0.rgb * specCutOff;
            
            	return float4(specRefl + ambientLight + diffRefl, 1);
            }
            	
			ENDHLSL
        }
    }
}