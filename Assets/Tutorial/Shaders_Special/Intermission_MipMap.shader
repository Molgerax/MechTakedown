Shader "Tutorial/Intermission_MipMap"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white"{}
        _MipLevel("Mip Level", Range(0, 10)) = 0
        [Toggle] _MIP("MipMap On", Int) = 0
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
            
            HLSLPROGRAM

            #pragma shader_feature _MIP_ON
            
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
			struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float _MipLevel;
            CBUFFER_END
            
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
			Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.uv = IN.uv * _MainTex_ST.xy + _MainTex_ST.zw;
                
                OUT.normalWS = (TransformObjectToWorldNormal(IN.normal.xyz));
                
			    return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
				float4 output = 0;

            #ifdef _MIP_ON
                
                output = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                
            #else
                
                output = SAMPLE_TEXTURE2D_LOD(_MainTex, sampler_MainTex, IN.uv, _MipLevel);
                
            #endif

                return output;
			}
			
			ENDHLSL
        }
    }
}