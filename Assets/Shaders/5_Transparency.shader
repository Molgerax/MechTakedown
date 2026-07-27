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
            Cull Back                           // Can be Back, Front or Off. Default is Back, so the backside of triangles are not rendered.
            ZWrite Off                          // Turn off ZWrite, so no depth gets written anymore
            Blend SrcAlpha OneMinusSrcAlpha     // Blend function, this is typical alpha blending
            // SrcAlpha OneMinusSrcAlpha acts as a simple lerp blend: finalCol = lerp(source, destination, sourceAlpha)
            // where "source" is the currently rendered pixel and destination is the pixel we are writing to
            
            // For more blending functions, see the Unity documentation: https://docs.unity3d.com/6000.3/Documentation/Manual/SL-Blend.html
            
            
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

                // here, we just set the alpha to the y-position in world space and clamping it to 0 and 1 with saturate().
                float alpha = saturate(IN.positionWS.y);
                
				return float4(color, alpha);
			}
			
			ENDHLSL
        }
    }
}