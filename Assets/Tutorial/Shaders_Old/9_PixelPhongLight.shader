Shader "Tutorial/9_PixelPhongLight"
{
    Properties
    {
		_Color("Color", Color) = (1,1,1,1)
		_Shininess("Shininess", Float) = 4
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
        	Cull Back
        	ZWrite On
        	
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
			struct Attributes
            {
                float4 positionOS : POSITION;
            	float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
            	float3 positionWS : TEXCOORD0;
            	float3 normalWS : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
				float4 _Color;
				float _Shininess;
            CBUFFER_END

            
			Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
            	OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
            	OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
            	
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
            	float3 normalWS = normalize(IN.normalWS);
            	float3 viewDir = GetWorldSpaceNormalizeViewDir(IN.positionWS);
            	
            	// The same as the previous one, but now, all calculations are done per pixel! :O
            	
            	
            	Light mainLight = GetMainLight();
            	
            	float NdotL = saturate(dot(mainLight.direction, normalWS));
            	
            	float3 diffuseReflection = _Color.rgb * NdotL * mainLight.color;
            	
            	float3 reflectedLightVector = reflect(mainLight.direction, normalWS);
            	float VdotL = saturate(dot(-viewDir, reflectedLightVector));
            	
            	float3 specularReflection = pow(VdotL, _Shininess) * mainLight.color;
            	
            	float3 ambientLight = EvaluateAmbientProbe(normalWS) * _Color.rgb;
            	
            	float3 color = diffuseReflection + specularReflection + ambientLight;
            	
				return float4(color, 1);
			}
			
			ENDHLSL
        }
    }
}