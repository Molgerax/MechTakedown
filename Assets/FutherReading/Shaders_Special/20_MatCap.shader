Shader "Tutorial/20_MatCap"
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
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalVS : TEXCOORD2;
                float3 normalWS : TEXCOORD3;
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

			    OUT.normalWS = TransformObjectToWorldNormal(IN.normal.xyz);
                OUT.normalVS = TransformWorldToViewNormal(OUT.normalWS);

                float3 viewDir = normalize( OUT.positionWS - GetCameraPositionWS() );
			    float3 up = GetWorldToViewMatrix()._m10_m11_m12;
                float3 right = normalize(cross(up, viewDir));
                up = normalize(cross(viewDir, right));

                float3x3 pixelViewMatrix = float3x3(right, up, viewDir);

                OUT.normalVS = mul(pixelViewMatrix, OUT.normalWS);
			    
			    return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
				float4 output = 0;
				
				
                float3 viewNormal = IN.normalVS;
                float2 uv = viewNormal.xy / 2.0 + 0.5;

              
                
                uv *= _MainTex_ST.xy;
                
				output = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
                clip(output.a - _AlphaCutoff);

                return output;
			}
			
			ENDHLSL
        }
    }
}