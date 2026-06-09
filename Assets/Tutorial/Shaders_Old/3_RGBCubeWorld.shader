Shader "Tutorial/3_RGBCube_Fancy" //define the name & folders of our Shader (SurfaceShader)
{
    Properties
    {
        _ColorA("Color A", color) = (1, 1, 1, 1)
		_ColorB("Color B", color) = (0, 0, 0, 1)
		_MaxDist("Maximum Distance", Float) = 5
		_BorderWidth("Border Width", Float) = 1

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
				float _MaxDist;
				float _BorderWidth;
				float4 _ColorA;
				float4 _ColorB;
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
				float4 output;
				float dist = distance(IN.positionWS, float4(0,0,0,1));
				
				float colorCoefficient = clamp((dist - _MaxDist + _BorderWidth * 0.5) * (1/_BorderWidth), 0, 1);

				output = colorCoefficient * _ColorA + (1 - colorCoefficient) * _ColorB;

				//clip(colorCoefficient - 0.1f);

				return output;
			}
			
			ENDHLSL
        }
    }
}