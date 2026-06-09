Shader "Tutorial/10_BasicTexture"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white"{}
        _AlphaCutoff("Cutoff", Range(0,1)) = 0.5
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
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float _AlphaCutoff;
            CBUFFER_END
            
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
			Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.uv = IN.uv * _MainTex_ST.xy + _MainTex_ST.zw;
			    return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
				float4 output = 0;
				
				output = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                clip(output.a - _AlphaCutoff);

                return output;
			}
			
			ENDHLSL
        }
    }
}