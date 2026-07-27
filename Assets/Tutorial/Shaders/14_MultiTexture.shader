Shader "Tutorial/14_MultiTexture"
{
	// For this shader, let us combine two textures in an interesting way!
	
    Properties
    {
    	_DayTex("Day Texture", 2D) = "white" {}
    	_NightTex("Night Texture", 2D) = "black" {}
    	_TransitionThickness("Transition Thickness", Range(0, 1)) = 1
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
			struct Attributes
            {
                float4 positionOS : POSITION;
            	float3 normalOS : NORMAL;
            	float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
            	float3 normalWS : TEXCOORD0;
            	float2 uv : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
				float4 _DayTex_ST;
				float4 _NightTex_ST;
				float _TransitionThickness;
            CBUFFER_END

            TEXTURE2D(_DayTex);
            SAMPLER(sampler_DayTex);
            TEXTURE2D(_NightTex);
            SAMPLER(sampler_NightTex);
            
			Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
            	OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
            	OUT.uv = IN.uv;
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
            	float3 normalWS = normalize(IN.normalWS);
            	
            	float2 uvDay = TRANSFORM_TEX(IN.uv, _DayTex);
            	float3 daySample = SAMPLE_TEXTURE2D(_DayTex, sampler_DayTex, uvDay).rgb;
            	
            	float2 uvNight = TRANSFORM_TEX(IN.uv, _NightTex);
            	float3 nightSample = SAMPLE_TEXTURE2D(_NightTex, sampler_NightTex, uvNight).rgb;
            	
            	
            	Light mainLight = GetMainLight();
            	float NdotL = dot(mainLight.direction, normalWS);
            	
            	// smoothstep(a, b, x) does a few things:
            	// It uses a and b as bottom and top limits. if x is below a, it returns 0, and if it is above b, it returns 1.
            	// All values of x between a and b are then smoothly interpolated between 0 and 1, so you get a nice transition.
            	// Play around with the _TransitionThickness slider and try to get a feel for it
            	float remapped = smoothstep(-1 * _TransitionThickness, 1 * _TransitionThickness, NdotL);
            	
            	// Because the result of smoothstep() is always between 0 and 1, we can plug it in nicely into a lerp function
            	float3 color = lerp(nightSample, daySample, remapped);
            	
				return float4(color, 1);
			}
			
			ENDHLSL
        }
    }
}