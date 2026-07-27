Shader "Tutorial/18_CelShading" 
{
	// Back to a more chill shader, this one is all about making light more stylized.
	
    Properties
    {
		_Color("Diff Color", Color) = (1, 1, 1, 1)
    	_StepSize("Step Size", Range(0, 1)) = 0.5
    	_ShadowEdge("ShadowEdge", Range(-1, 1)) = 0.5
    	_Shininess("Shininess", Float) = 8
    	_SpecularStrength("Specular Strength", Range(0,1)) = 1
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
            
            
            struct Attributes
            {
            	float4 positionOS : POSITION;
            	float4 uv : TEXCOORD0;
            	float3 normalOS : NORMAL;
            };
            
            struct Varyings
            {
            	float4 positionHCS : SV_POSITION;
            	float4 uv : TEXCOORD0;
            	float3 positionWS : TEXCOORD1;
            	float3 normalWS : TEXCOORD2;
            };

            
            CBUFFER_START(UnityPerMaterial)
            	float4 _Color;
				float _StepSize;
				float _ShadowEdge;
				float _Shininess;
				float _SpecularStrength;
            CBUFFER_END
            
            // Shader Functions-----------------------
            Varyings vert(Attributes IN)
            {
            	Varyings output;
            	
            	output.positionHCS = TransformObjectToHClip(IN.positionOS);
            	output.positionWS = TransformObjectToWorld(IN.positionOS);
            	output.normalWS = TransformObjectToWorldNormal(IN.normalOS);
            	output.uv = IN.uv;
            	
            	return output;
            }
            
            
            // This function is meant to remap the normal NdotL product from {-1,1} to {_ShadowEdge,1}
            // _ShadowEdge should tell 
            float RemapDotProduct(float input)
            {
            	// Remap value from {-1,1} to {_ShadowEdge,1}
	            float output = (input - _ShadowEdge) / (1 - _ShadowEdge);
            	
            	// saturate() to also clamp it between {0,1}
            	return saturate(output);
            }
            
            // Quantizing means to turn a continuous spectrum into discrete chunks.
            // By dividing our value x by the StepSize, and then multiplying the result, we should just get the same value.
            // But because we round it to the nearest integer inbetween these two steps, the values are not split up into
            // solid chunks of color.
            float QuantizeValue(float x)
            {
            	if (_StepSize == 0)
            		return x;
            	
            	return round(x / _StepSize) * _StepSize;
            }
            
            
            float4 frag(Varyings IN) : COLOR 
            {	
            	float3 normalWS = normalize(IN.normalWS);
				float3 viewDirWS = GetWorldSpaceNormalizeViewDir(IN.positionWS);
            	
            	Light mainLight = GetMainLight();
            	
            	float lightSum = 0;
            	
            	float NdotL = RemapDotProduct(dot(mainLight.direction, normalWS));
            	lightSum += NdotL;
            	
            	
            	float3 reflectedLightVector = reflect(mainLight.direction, normalWS);
            	float VdotL = saturate(dot(-viewDirWS, reflectedLightVector));
            	
            	float specular = pow(VdotL, _Shininess);
            	lightSum += specular * _SpecularStrength;
            	
            	float3 ambientLight = EvaluateAmbientProbe(normalWS) * _Color.rgb;
            	
            	float3 color = QuantizeValue(lightSum) * mainLight.color * _Color.rgb + ambientLight;
            	
            	return float4(color, 1);
            }
            	
			ENDHLSL
        }
    }
}