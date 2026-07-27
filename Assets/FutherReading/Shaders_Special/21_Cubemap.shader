Shader "Tutorial/21_Cubemap"
{
    Properties
    {
        _MainTex("Texture", Cube) = "white"{}
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
                float _AlphaCutoff;
            CBUFFER_END
            
            
            TEXTURECUBE(_MainTex);
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
				
				float3 viewDir = normalize( IN.positionWS - GetCameraPositionWS() );
                float3 sampleDir = reflect(viewDir, IN.normalWS);

                //sampleDir = IN.normalWS;
                output = SAMPLE_TEXTURECUBE(_MainTex, sampler_MainTex, sampleDir);
                
                return output;
			}
			
			ENDHLSL
        }
    }
}