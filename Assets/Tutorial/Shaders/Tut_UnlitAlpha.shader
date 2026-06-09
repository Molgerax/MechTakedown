Shader "Custom/Tut_UnlitAlpha"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _Alpha("Alpha", Range(0,1)) = 0.5
    }

    

    SubShader
    {
        Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent" }

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            
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
                float3 worldPos : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float _Alpha;
            CBUFFER_END


            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
                float4 color = 1;
                color.rgb = saturate( IN.worldPos);

                float yHeight = IN.worldPos.y;

                float remappedHeight = saturate(yHeight / 10);
                
                return float4(color.rgb, remappedHeight);
            }
            ENDHLSL
        }
    }
}
