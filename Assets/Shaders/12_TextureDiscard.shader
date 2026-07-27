Shader "Tutorial/12_TextureDiscard"
{
    Properties
    {
        // We use a second texture for an "erosion" effect that dissolves the object
        // I suggest using a noise texture for this   
        _MainTex("Main Texture", 2D) = "white"{}
        _ErosionTex("Erosion Texture", 2D) = "white"{}
        _ErosionCutoff("Erosion Cutoff", Range(0,1)) = 0
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
            // Turn off backface culling, so we can see into the mesh when it dissolves
            Cull Off
            
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
            
            TEXTURE2D(_ErosionTex);
            SAMPLER(sampler_ErosionTex);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _ErosionTex_ST;
                float _ErosionCutoff;
            CBUFFER_END
            
            
            
            
			Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                
                OUT.uv = IN.uv; // we can keep the UVs as is and then transform them in the fragment shader
                
			    return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
                float2 uvMain = TRANSFORM_TEX(IN.uv, _MainTex);
				float4 colorSample = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvMain);
                
                // Here we just sample a second texture for the erosion effect
                float2 uvErosion = TRANSFORM_TEX(IN.uv, _ErosionTex);
				float4 erosionSample = SAMPLE_TEXTURE2D(_ErosionTex, sampler_ErosionTex, uvErosion);
                
                // The erosion sample is just used for the cutoff effect. The red channel is usually used for mono-chromatic textures,
                // so we can use a simple black-and-white noise texture for it
                clip(erosionSample.r - _ErosionCutoff);
                
                return colorSample;
			}
			
			ENDHLSL
        }
    }
}