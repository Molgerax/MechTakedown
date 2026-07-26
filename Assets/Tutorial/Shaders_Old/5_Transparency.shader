Shader "Tutorial/5_Transparency"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
		_Cutoff("Cutoff", Float) = 0
    }
	
    SubShader 
    {
        Tags 
        { 
            "RenderPipeline" = "UniversalPipeline" 
            "RenderType" = "Transparent"  // Change RenderType 
            "Queue" = "Transparent"       // Change Queue, so it gets rendered after all opaque shaders
        }

        Pass
        {
            ZWrite Off                          // Turn off ZWrite, so no depth gets written anymore
            Blend SrcAlpha OneMinusSrcAlpha     // Blend function, this is typical alpha blending
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
			struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
				float4 _Color;
				float _Cutoff;
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
				float3 color = 1;

                float alpha = saturate(IN.positionWS.y);
                
				return float4(color, alpha);
			}
			
			ENDHLSL
        }
    }
}