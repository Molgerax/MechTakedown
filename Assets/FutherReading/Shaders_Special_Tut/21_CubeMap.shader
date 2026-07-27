Shader "Tutorial/21_CubeMap_Tut"
{
    Properties
    {
        _MainTex("Texture", Cube) = "white"{}
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
            
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
			struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normal : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 viewDirWS : TEXCOORD3;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
            CBUFFER_END
            
            
            TEXTURECUBE(_MainTex);
            SAMPLER(sampler_MainTex);
            
			Varyings vert(Attributes IN)
            {
                Varyings OUT;

			    OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
			    OUT.positionWS = TransformObjectToWorld(IN.positionOS);
			    OUT.normalWS = TransformObjectToWorldNormal(IN.normal);
			    OUT.viewDirWS = normalize( GetCameraPositionWS() - OUT.positionWS );
			    
			    return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
				float4 output = 0;

                float3 sampleDirection = reflect(-IN.viewDirWS, IN.normalWS);
                output = SAMPLE_TEXTURECUBE(_MainTex, sampler_MainTex, sampleDirection);
                
                return output;
			}
			
			ENDHLSL
        }
    }
}