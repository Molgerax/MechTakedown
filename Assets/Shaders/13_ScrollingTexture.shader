Shader "Tutorial/13_ScrollingTexture"
{
    Properties
    {
        _MainTex("Main Texture", 2D) = "white"{}
        _ScrollSpeed("Scrolling Speed", Float) = 1
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
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float _ScrollSpeed;
            CBUFFER_END
            
            
            
            
			Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                
                float2 uv = IN.uv;
                
                // The built-in variable "_Time" gives us the current time in-game. Each component has a different scaling.
                // x = (t / 20), y = (t), z = (t * 2), w = (t * 3)
                float uvOffset = _Time.x * _ScrollSpeed;
                
                // We add this offset to our UVs, and now the texture should scroll along the x-axis of the UVs
                uv.x += uvOffset;
                
                // By applying the offset before the texture transform, it now always scrolls with the same speed regardless
                // of the texture scaling
                OUT.uv = TRANSFORM_TEX(uv, _MainTex);
                
			    return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
                float2 uv = IN.uv;
                
				float4 colorSample = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
                
                return colorSample;
			}
			
			ENDHLSL
        }
    }
}