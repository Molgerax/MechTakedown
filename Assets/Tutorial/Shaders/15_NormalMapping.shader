Shader "Tutorial/15_NormalMapping" 
{
    Properties
    {
		_MainTex("Main Texture", 2D) = "white" {}
		[Normal] _BumpMap("Normal", 2D) = "bump" {} // Bump is the default texture for normal maps
		_Shininess("Shiny", Float) = 8
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
			Tags {"LightMode" = "UniversalForward"}

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            
            struct Attributes
            {
            	float4 pos : POSITION;
            	float4 uv : TEXCOORD0;
            	float3 normal : NORMAL;
            	float4 tangent : TANGENT;
            };
            
            struct Varyings
            {
            	float4 positionHCS : SV_POSITION;
            	float2 uv : TEXCOORD0;
            	float3 positionWS : TEXCOORD1;
            	float4 tangentWS : TEXCOORD2;
            	float3 normalWS : TEXCOORD3;
            };

            
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_BumpMap);
            SAMPLER(sampler_BumpMap);
			
            CBUFFER_START(UnityPerMaterial)
				float4 _MainTex_ST;
            	float4 _BumpMap_ST;
            	float _Shininess;
            CBUFFER_END
            
            // Shader Functions-----------------------
            Varyings vert(Attributes IN)
            {
            	Varyings OUT;
            	

				// New way of doing it
            	VertexNormalInputs inputs = GetVertexNormalInputs(IN.normal, IN.tangent);
            	OUT.tangentWS = float4(inputs.tangentWS, IN.tangent.w);
            	OUT.normalWS = inputs.normalWS;

            	
            	OUT.positionHCS = TransformObjectToHClip(IN.pos);
            	OUT.positionWS = TransformObjectToWorld(IN.pos);
            	OUT.uv = IN.uv;
            	
            	return OUT;
            }
            
            float4 frag(Varyings IN) : COLOR 
            {	
            	// First we sample the normal texture
            	float4 encodedNormal = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, TRANSFORM_TEX(IN.uv, _BumpMap));

            	// Then we decode it from the texture, Unity takes care of the way the textures are packed here
            	float3 decodedNormal = UnpackNormal(encodedNormal);
            	// Then we construct the TangentToWorld transformation matrix at this specific pixel
            	float3x3 tangentToWorld = CreateTangentToWorld(IN.normalWS, IN.tangentWS.xyz, IN.tangentWS.w);
            	// At last, we transform the decoded normal from tangent space to world space, so we can use it as usual
            	float3 normalWS = TransformTangentToWorldDir(decodedNormal, tangentToWorld, true);
            	

            	
            	// Now just the same as usual (seen in 9_PixelPhongLight), using the new "normalWS" constructed from the normal map
            	Light light = GetMainLight();
            	float3 viewDir = GetWorldSpaceNormalizeViewDir(IN.positionWS);
            
            	float NdotL = saturate(dot(light.direction, normalWS));
            	
            	float3 objectColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, TRANSFORM_TEX(IN.uv, _MainTex));
            	float3 diffuseReflection = objectColor * NdotL * light.color;
            	
            	float3 reflectedLightVector = reflect(light.direction, normalWS);
            	float VdotL = saturate(dot(-viewDir, reflectedLightVector));
            	float3 specularReflection = pow(VdotL, _Shininess) * light.color;
            	float3 ambientLight = EvaluateAmbientProbe(normalWS) * objectColor;
            	
            	float3 color = diffuseReflection + specularReflection + ambientLight;
            
            	return float4(color, 1);
            }
            	
			ENDHLSL
        }
    }
}