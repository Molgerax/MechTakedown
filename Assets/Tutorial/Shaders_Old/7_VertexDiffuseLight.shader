Shader "Tutorial/7_VertexDiffuseLight"
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
        	Cull Back
        	ZWrite On
        	
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            // --- NEW ---
            // for everything lighting-related, we need to include this file
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            // --- NEW ---
            
			struct Attributes
            {
                float4 positionOS : POSITION;
            	float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
            	float3 color : COLOR;
            };

            CBUFFER_START(UnityPerMaterial)
				float4 _Color;
            CBUFFER_END

            
			Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
            	
            	// Get normal vector in world space as before
                float3 normalWS = TransformObjectToWorldNormal(IN.normalOS);
            	
            	// Get main light of the scene. Requires a new include file above
            	Light mainLight = GetMainLight();
            	
            	// Dot-product of the light direction and the normal gives us how "lit" that vertex is.
            	float NdotL = dot(mainLight.direction, normalWS);
            	
            	// When facing away from the light, dot products become negative 
            	// so we use saturate() to clamp the value between 0 and 1
            	OUT.color = _Color * saturate(NdotL);
            	
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
				float3 color = IN.color;
						
				return float4(color, 1);
			}
			
			ENDHLSL
        }
    }
}