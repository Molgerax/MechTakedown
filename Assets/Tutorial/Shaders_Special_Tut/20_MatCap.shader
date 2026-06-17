Shader "Tutorial/20_MatCap_Tut"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white"{}
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
            
			struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normal : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 normalVS : TEXCOORD3;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
            CBUFFER_END
            
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
			Varyings vert(Attributes IN)
            {
                Varyings OUT;

			    OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
			    OUT.positionWS = TransformObjectToWorld(IN.positionOS);
			    OUT.normalWS = TransformObjectToWorldNormal(IN.normal);
			    OUT.normalVS = TransformWorldToViewDir(IN.normal);
			    
			    return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
				float4 output = 0;

                float2 sampleUV = IN.normalVS.xy * 0.5 + 0.5;
                
                output = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, sampleUV);
                
                return output;
			}
			
			ENDHLSL
        }
    }
}