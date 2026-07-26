Shader "Tutorial/6_SpaceShield"
{
    Properties
    {
		_Color("Color", Color) = (1,1,1,1)
		_Falloff("Falloff", Float) = 8
    }
	
    SubShader 
    {
        Tags 
        { 
            "RenderPipeline" = "UniversalPipeline" 
            "RenderType" = "Transparent" 
            "Queue" = "Transparent" 
        }

        Pass
        {
        	Blend SrcAlpha OneMinusSrcAlpha
        	ZWrite Off
        	
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
			struct Attributes
            {
                float4 positionOS : POSITION;
            	float3 normalOS : NORMAL;	// We can also access the normal of a vertex with this semantic
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 viewDirWS : TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)
				float4 _Color;
				float _Falloff;
            CBUFFER_END

            
			Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
            	
            	// Once again transform from object to world, but this time, using the Normal function for it
            	OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
            	
            	// For this effect, we also need the view direction, i.e. the direction from the camera to the vertex
            	OUT.viewDirWS = GetWorldSpaceViewDir(OUT.positionWS);
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
				float3 normalDir = normalize(IN.normalWS); // Because we don't know what Unity does in the background, for safety!
				float3 viewDir = normalize(IN.viewDirWS); // FOR SAFETY!!


            	// dot between normal and view is 1 when looking exactly at surface, goes to 0 towards the edge
            	float NdotV = dot(normalDir, viewDir);
            	
            	// 1 - () to flip it, so that we get 1 towards edges
				// saturate, so it gets clamped between 0 and 1
            	float fresnel = saturate( 1 - NdotV);

            	// pow(a, b) raises a to the b-th power, the higher the falloff, the thinner the edges get
				float alpha = saturate(pow(fresnel, _Falloff));
						
				return float4(_Color.rgb, alpha);
			}
			
			ENDHLSL
        }
    }
}