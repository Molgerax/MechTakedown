// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Tutorial/22_CubeMap_Reflection_Tut" //define the name & folders of our Shader (SurfaceShader)
{
    Properties
    {
		_BumpMap("Normal", 2D) = "bump" {}
    	_Bump("Normal Strength", Range(0, 5)) = 1
        _ReflectionMap("Reflection", Cube) = "black"{}
		_Color("Diff Color", Color) = (1, 1, 1, 1)
		_Shininess("Shiny", Float) = 8
    	_MipLevel("Mip Level", Range(0, 8)) = 0
    }
    

    SubShader //multiple subshaders for different GPUs, Unity will choose the most suited one for current application
    {
    	Tags 
        { 
            "RenderPipeline" = "UniversalPipeline" 
            "RenderType" = "Opaque" 
            "Queue" = "Geometry" 
        }

        Pass //PASS 0 -- BASE with Ambient Light
        {
			Tags {"LightMode" = "UniversalForward"}

            HLSLPROGRAM //here starts the pure Cg shader code

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
            	float4 pos : SV_POSITION;
            	float4 uv : TEXCOORD0;
            	float3 posWS : TEXCOORD1;
            	float4 tangentWS : TEXCOORD2;
            	float3 normalWS : TEXCOORD3;
            	float3 viewDirWS : TEXCOORD4;
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
            CBUFFER_END
            
            // Shader Functions-----------------------
            Varyings vert(Attributes IN)
            {
            	Varyings output;
            	
				// New way of doing it
            	VertexNormalInputs inputs = GetVertexNormalInputs(IN.normal, IN.tangent);
            	output.tangentWS = float4(inputs.tangentWS, IN.tangent.w);
            	output.normalWS = inputs.normalWS;
            	
            	output.pos = TransformObjectToHClip(IN.pos);
            	output.posWS = TransformObjectToWorld(IN.pos);
            	output.uv = IN.uv;
            	output.viewDirWS = GetWorldSpaceNormalizeViewDir(output.posWS);
            	
            	return output;
            }
            
            float4 frag(Varyings input) : COLOR 
            {	
            	float4 encodedNormal = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.uv.xy * _BumpMap_ST.xy + _BumpMap_ST.zw);

            	// New way
            	float3 normalTS = UnpackNormal(encodedNormal);
            	normalTS.xy *= _Bump;
            	
            	float3x3 tangentToWorld = CreateTangentToWorld(input.normalWS, input.tangentWS.xyz, input.tangentWS.w);
            	float3 normalDir = TransformTangentToWorldDir(normalTS, tangentToWorld, true);
            	
            	
            	float3 viewDir = normalize(_WorldSpaceCameraPos - input.posWS.xyz);

            	Light light = GetMainLight();
            
            	float3 diffRefl = _LightColor0.rgb * _Color.rgb * max(0, dot(normalDir, light.direction));
            	float3 ambientLight = UNITY_LIGHTMODEL_AMBIENT.rgb * _Color.rgb;
            	float specCutOff = step(0, dot(normalDir, light.direction));
            	
            	float3 specRefl = pow(max(0, dot(viewDir, reflect(-light.direction, normalDir))), _Shininess) 
            						  * _LightColor0.rgb * specCutOff;

            	float3 sampleDir = reflect(-input.viewDirWS, normalDir);
            	specRefl = SAMPLE_TEXTURECUBE_LOD(_ReflectionMap, sampler_ReflectionMap, sampleDir, _MipLevel);

            	ambientLight *= 0.5;
            	diffRefl *= 0.5;
            	specRefl *= 0.5;
            	
            	return float4(specRefl + ambientLight + diffRefl, 1);
            }
            	
			ENDHLSL
        }
    }
}