Shader "Tutorial/23_CubemapRefraction"
{
    Properties
    {
		_BumpMap("Normal", 2D) = "bump" {}
		_ReflectionMap("Reflection", CUBE) = "black" {}
		_Color("Diff Color", Color) = (1, 1, 1, 1)
		_Shininess("Shiny", Float) = 8
    	_MipMapLevel("Mip Level", Range(0, 8)) = 0
    	_IOR("Index of Refraction", Range(-0.25, 1)) = 0
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

        	Cull Back
        	ZWrite On
        	
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
            	float3 binormalWS : TEXCOORD4;
            	float4 screenUV : TEXCOORD5;
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
            	float _MipMapLevel;
            	float _IOR;
            CBUFFER_END
            
            // Shader Functions-----------------------
            Varyings vert(Attributes IN)
            {
            	Varyings output;


            	// Old way of doing it
            	output.tangentWS = float4(TransformObjectToWorld(IN.tangent.xyz), IN.tangent.w);
            	output.normalWS = TransformObjectToWorldNormal(IN.normal);
            	output.binormalWS = normalize(cross(output.normalWS, output.tangentWS) 
            							* IN.tangent.w); //input.tangent.w specific to unity

				// New way of doing it
            	VertexNormalInputs inputs = GetVertexNormalInputs(IN.normal, IN.tangent);
            	output.tangentWS = float4(inputs.tangentWS, IN.tangent.w);
            	output.normalWS = inputs.normalWS;
            	output.binormalWS = inputs.tangentWS;

            	
            	output.pos = TransformObjectToHClip(IN.pos);
            	output.posWS = TransformObjectToWorld(IN.pos);
            	output.uv = IN.uv;

				output.screenUV = ComputeScreenPos(output.pos);
            	
            	return output;
            }
            
            float4 frag(Varyings input) : COLOR 
            {	
            	float4 encodedNormal = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.uv.xy * _BumpMap_ST.xy + _BumpMap_ST.zw);

				// Old way
            	float3 localCoord = float3(2 * encodedNormal.r - 1, 2 * encodedNormal.g - 1, 0);
            	localCoord.z = sqrt(1 - dot(localCoord, localCoord));
            	
            	float3x3 local2WorldTranspose = float3x3(
            			input.tangentWS.xyz,
            			input.binormalWS * input.tangentWS.w,
            			input.normalWS);

            	float3 normalDir = normalize(mul(localCoord, local2WorldTranspose));

            	// New way
            	localCoord = UnpackNormal(encodedNormal);
            	local2WorldTranspose = CreateTangentToWorld(input.normalWS, input.tangentWS.xyz, input.tangentWS.w);
            	normalDir = TransformTangentToWorldDir(localCoord, local2WorldTranspose, true);
            	
            	
            	float3 viewDir = normalize(_WorldSpaceCameraPos - input.posWS.xyz);

            	Light light = GetMainLight();
            	
            
            	float3 diffRefl = _LightColor0.rgb * _Color.rgb * max(0, dot(normalDir, light.direction));
            	
            	float3 ambientLight = UNITY_LIGHTMODEL_AMBIENT.rgb * _Color.rgb;
            
            	float specCutOff = step(0, dot(normalDir, light.direction)); //if dot is bigger than 0, return 1, else 0
            
            	float3 specRefl = pow(max(0, dot(viewDir, reflect(-light.direction, normalDir))), _Shininess) 
            						  * _LightColor0.rgb * specCutOff;



            	float2 screenUV = input.screenUV.xy / input.screenUV.w;
            	
            	float3 refractionVector = refract(viewDir, normalDir, _IOR);

            	float3 sampleCubeDir = TransformWorldToTangentDir(refractionVector, local2WorldTranspose, true);
            	float3 cubemapRefl = SAMPLE_TEXTURECUBE_LOD(_ReflectionMap, sampler_ReflectionMap, sampleCubeDir, _MipMapLevel);

            	screenUV += sampleCubeDir.xy;
            	cubemapRefl = SampleSceneColor(screenUV);
            	
            	ambientLight = 0;
            	diffRefl = 0;

            	
            	return float4(ambientLight + diffRefl + cubemapRefl, 1);
            }
            	
			ENDHLSL
        }
    }
}