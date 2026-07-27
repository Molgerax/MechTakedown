Shader "Tutorial/2_WorldPosition"
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

            // When we want to transfer more data from vertex to fragment stage, we can use the "TEXCOORD#" semantic
            // They are numbered from 0 to 7 and can hold at most a float4 value, 
            // though we can also truncate it to a float3, like in this example.
            // Usually you would use it for UVs, (i.e. texture coordinates), but we can use it for whatever we want!
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
                
                // Another helpful function from "Core.hlsl", this time for converting from object to world space
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
                // We are now using the vertex' world position as input for its color. This means moving the object around
                // will change its color, as its world position changes. By multiplying it with "_Color", we can also 
                // "mask away" some channels, e.g. by setting the red part to 0, we no longer get red in our final color.
                
                float3 color = IN.positionWS * _Color;
                return float4(color.rgb, 1);
            }
            ENDHLSL
        }
    }
}
