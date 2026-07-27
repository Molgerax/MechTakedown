Shader "Tutorial/10_BasicTexture"
{
    Properties
    {
        // "2D" is the property type for textures, their default colors are "black", "white", "gray", "red", "bump"
        _MainTex("Main Texture", 2D) = "white"{}
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
                float2 uv : TEXCOORD0; // UVs come from TEXCOORD0
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            
            
            // Declare a texture like this
            TEXTURE2D(_MainTex);
            
            // You also need a sampler for it, follow the naming convention of "sampler_<MyTextureName>"
            // Samplers, also known as SamplerState, tell the shader how to sample the texture, i.e. point-filtering,
            // liner interpolation, if it repeats or clamps at the edges, etc.
            // "sampler_<MyTextureName>" uses the settings on the texture itself
            SAMPLER(sampler_MainTex);
            
            // Every texture also assigns automatically the float4 <MyTextureName>_ST
            // It holds the Scale and Translation from the material inspector
            // We can use that to scale the UVs later for more control per material
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
            CBUFFER_END
            
            
            
            
			Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                
                // Here we scale the UVs by the scaling factor and add the offset factor
                OUT.uv = IN.uv * _MainTex_ST.xy + _MainTex_ST.zw;
                
                // This is the same as using this macro:
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                
			    return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
				float4 color = 0;
				
                // To sample the texture, we use this macro
                // It needs the texture, the sampler, and the UV input
				color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

                return color;
			}
			
			ENDHLSL
        }
    }
}