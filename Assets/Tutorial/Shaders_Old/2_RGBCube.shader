Shader "Tutorial/2_RGBCube"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
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
                float4 positionOS : POSITION; // OS -> Object Space
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION; // HCS -> Homogenous Clip Space
                float3 positionWS : TEXCOORD0; // WS -> World Space
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
            CBUFFER_END


            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
                float3 color = IN.positionWS * _Color;
                return float4(color.rgb, 1);
            }
            ENDHLSL
        }
    }
}
