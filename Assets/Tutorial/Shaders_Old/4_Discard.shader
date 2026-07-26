Shader "Tutorial/4_Discard"
{
    Properties
    {
		_Cutoff("Cutoff", Float) = 0
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
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
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
				float4 output = 1;

                // If value passed to clip() is below 0, the pixel is discarded and not rendered
                // With a _Cutoff of 0, this means all pixel below the y-Plane of 0 are discarded
                // _Cutoff of 5 makes it discard all pixels below 5, etc.
                clip(IN.positionWS.y - _Cutoff);
                
				return output;
			}
			
			ENDHLSL
        }
    }
}