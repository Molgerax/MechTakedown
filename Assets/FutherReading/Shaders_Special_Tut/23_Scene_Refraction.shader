Shader "Tutorial/23_Scene_Refraction_Tut" //define the name & folders of our Shader (SurfaceShader)
{
    Properties
    {
		_BumpMap("Normal", 2D) = "bump" {}
    	_Bump("Normal Strength", Range(0, 5)) = 1
        _ReflectionMap("Reflection", Cube) = "black"{}
		_Color("Diff Color", Color) = (1, 1, 1, 1)
		_Shininess("Shiny", Float) = 8
    	_MipLevel("Mip Level", Range(0, 8)) = 0
    	_IOR("Index of Refraction", Range(-1, 3)) = 1
    }
    

    SubShader //multiple subshaders for different GPUs, Unity will choose the most suited one for current application
    {
    	Tags 
        { 
            "RenderPipeline" = "UniversalPipeline" 
            "RenderType" = "Transparent" 
            "Queue" = "Transparent" 
        }

        Pass //PASS 0 -- BASE with Ambient Light
        {
			Tags {"LightMode" = "UniversalForward"}

            HLSLPROGRAM //here starts the pure Cg shader code

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
            
            
            struct Attributes
            {
            	float4 pos : POSITION;
            	float4 uv : TEXCOORD0;
            	float3 normal : NORMAL;
            	float4 tangent : TANGENT;
            };
            
            struct Varyings
            {
            	float4 pos : SV_POSITION;
            	float4 uv : TEXCOORD0;
            	float3 posWS : TEXCOORD1;
            	float4 tangentWS : TEXCOORD2;
            	float3 normalWS : TEXCOORD3;
            	float3 viewDirWS : TEXCOORD4;
            	float4 screenUV : TEXCOORD5;
            	float3 normalVS : TEXCOORD6;
            };

            
            TEXTURE2D(_BumpMap);
            SAMPLER(sampler_BumpMap);
            
            TEXTURECUBE(_ReflectionMap);
            SAMPLER(sampler_ReflectionMap);
			
            CBUFFER_START(UnityPerMaterial)
            	float4 _LightColor0;
            	float4 _BumpMap_ST;
            	float4 _Color;
            	float _Shininess;
            	float _Bump;
				float _MipLevel;
				float _IOR;
            CBUFFER_END
            
            // Shader Functions-----------------------
            Varyings vert(Attributes IN)
            {
            	Varyings OUT;
            	
				// New way of doing it
            	VertexNormalInputs inputs = GetVertexNormalInputs(IN.normal, IN.tangent);
            	OUT.tangentWS = float4(inputs.tangentWS, IN.tangent.w);
            	OUT.normalWS = inputs.normalWS;
            	
            	OUT.pos = TransformObjectToHClip(IN.pos);
            	OUT.posWS = TransformObjectToWorld(IN.pos);
            	OUT.uv = IN.uv;
            	OUT.viewDirWS = GetWorldSpaceNormalizeViewDir(OUT.posWS);
            	OUT.screenUV = ComputeScreenPos(OUT.pos);


            	float3 viewDir = normalize( OUT.posWS - GetCameraPositionWS() );
			    float3 up = GetWorldToViewMatrix()._m10_m11_m12;
                float3 right = normalize(cross(up, viewDir));
                up = normalize(cross(viewDir, right));

                float3x3 pixelViewMatrix = float3x3(right, up, viewDir);

                OUT.normalVS = mul(pixelViewMatrix, refract(-OUT.viewDirWS, OUT.normalWS, _IOR));
            	
            	
            	return OUT;
            }
            
            float4 frag(Varyings input) : COLOR 
            {	
            	float4 encodedNormal = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.uv.xy * _BumpMap_ST.xy + _BumpMap_ST.zw);

            	float3 normalTS = UnpackNormal(encodedNormal);
            	normalTS.xy *= _Bump;
            	
            	float3x3 tangentToWorld = CreateTangentToWorld(input.normalWS, input.tangentWS.xyz, input.tangentWS.w);
            	float3 normalDir = TransformTangentToWorldDir(normalTS, tangentToWorld, true);
            	
            	

            	float3 viewDir = normalize( input.posWS - GetCameraPositionWS() );
			    float3 up = GetWorldToViewMatrix()._m10_m11_m12;
                float3 right = normalize(cross(up, viewDir));
                up = normalize(cross(viewDir, right));

                float3x3 pixelViewMatrix = float3x3(right, up, viewDir);
            	
            	float3 refractDir = refract(viewDir, normalDir, 1.0 / _IOR);

            	float3 sampleDir = mul(pixelViewMatrix, refractDir);

            	
            	float2 screenUV = input.screenUV.xy / input.screenUV.w;
            	screenUV += sampleDir.xy;
            	
            	float3 refractCol = SampleSceneColor(screenUV);


            	float fresnel = 1 - saturate(dot(-viewDir, normalDir));

            	fresnel = pow(fresnel, _Shininess);
            	
            	float3 reflectDir = reflect(viewDir, normalDir);
            	float3 specRefl = SAMPLE_TEXTURECUBE_LOD(_ReflectionMap, sampler_ReflectionMap, reflectDir, _MipLevel);

            	specRefl *= fresnel;

            	
            	
            	return float4(refractCol + specRefl, 1);
            }
            	
			ENDHLSL
        }
    }
}