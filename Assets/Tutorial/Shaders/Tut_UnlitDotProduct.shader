Shader "Custom/Tut_UnlitDotProduct"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
    }

    

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

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
                float3 worldPos : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 viewWS : TEXCOORD3;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
            CBUFFER_END


            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normal);
                OUT.viewWS = GetCameraPositionWS() - OUT.worldPos;
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
                float3 color = _Color;
                
                //clip(-IN.worldPos.y);

                float d = 1 - saturate(dot(normalize(IN.normalWS), normalize(IN.viewWS)));

                color *= d;
                
                return float4(color, 1);
            }
            ENDHLSL
        }
    }
}
