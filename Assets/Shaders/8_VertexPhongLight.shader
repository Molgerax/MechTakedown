Shader "Tutorial/8_VertexPhongLight"
{
    Properties
    {
		_Color("Color", Color) = (1,1,1,1)
		_Shininess("Shininess", Float) = 4
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
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
            	float3 color : COLOR;
            };

            CBUFFER_START(UnityPerMaterial)
				float4 _Color;
				float _Shininess;
            CBUFFER_END

            
			Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
            	
            	float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
            	float3 normalWS = TransformObjectToWorldNormal(IN.normalOS);
            	float3 viewDir = GetWorldSpaceNormalizeViewDir(positionWS);
            	
            	
            	// Phong lighting consists of diffuse, specular and ambient lighting
            	
            	Light mainLight = GetMainLight();
            	float NdotL = saturate(dot(mainLight.direction, normalWS));
            	
            	// Diffuse reflection is just the normal NdotL factor multiplied by the surface color and the light color
				float3 diffuseReflection = _Color.rgb * NdotL * mainLight.color;
            	
            	
            	// We reflect the light along the normal of the surface
            	float3 reflectedLightVector = reflect(mainLight.direction, normalWS);
            	
            	
            	// now we can use the dot-product between the reflected light (often L) and the view vector
            	// !!Mind the minus!! This is important, because usually, the two vectors are opposed, i.e. the light is going
            	// the other way than the camera is looking, so one of them needs to get flipped so we have the correct sign
            	float VdotL = saturate(dot(-viewDir, reflectedLightVector));
            	
            	// Specular reflection is how much reflected light gets into our eye, raised to some power
				float3 specularReflection = pow(VdotL, _Shininess) * mainLight.color;
            	
            	// Ambient light is basically the environment light, i.e. global illumination from the sky, the objects around it, etc.
            	// This can be simply sampled by calling this function using the world-space normal as an input.
            	// Ambient light gives us something to fill the otherwise pitch-black shadows
            	float3 ambientLight = EvaluateAmbientProbe(normalWS) * _Color.rgb;
            	
            	// add it all together and we get our final output
				OUT.color = float4(diffuseReflection + specularReflection + ambientLight, 1);
            	
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