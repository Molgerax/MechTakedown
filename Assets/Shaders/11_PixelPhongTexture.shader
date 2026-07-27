Shader "Tutorial/11_PixelPhongTexture"
{
	// For this shader, we just combine the texture with the Phong lighting from before
	
    Properties
    {
    	_MainTex("Main Texture", 2D) = "white" {}
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
            	float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
            	float3 positionWS : TEXCOORD0;
            	float3 normalWS : TEXCOORD1;
            	float2 uv : TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)
				float4 _MainTex_ST;
				float4 _Color;
				float _Shininess;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
			Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
            	OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
            	OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
            	OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
            	float3 normalWS = normalize(IN.normalWS);
            	float3 viewDir = GetWorldSpaceNormalizeViewDir(IN.positionWS);
            	
            	float3 objectColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
            	
            	// Let's multiply the texture color with our _Color property, so we can tint it
            	objectColor *= _Color.rgb;
            	
            	Light mainLight = GetMainLight();
            	
            	float NdotL = saturate(dot(mainLight.direction, normalWS));
            	
            	// Now, we just replace every instance of "_Color" with "objectColor", so it uses the texture as the color
            	// at any given pixel
            	float3 diffuseReflection = objectColor * NdotL * mainLight.color;
            	
            	float3 reflectedLightVector = reflect(mainLight.direction, normalWS);
            	float VdotL = saturate(dot(-viewDir, reflectedLightVector));
            	
            	float3 specularReflection = pow(VdotL, _Shininess) * mainLight.color;
            	
            	float3 ambientLight = EvaluateAmbientProbe(normalWS) * objectColor;
            	
            	float3 color = diffuseReflection + specularReflection + ambientLight;
            	
				return float4(color, 1);
			}
			
			ENDHLSL
        }
    }
}