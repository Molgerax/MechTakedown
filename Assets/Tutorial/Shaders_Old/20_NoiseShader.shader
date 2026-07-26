Shader "hda/Exam/Noise"   //define the name of our Shader (SurfaceShader)
{
	Properties
	{
	   _Color("Color", Color) = (1, 1, 1, 1)
	   _Noise("Noise", 2D) = "bump" {}
	   _Cube("Reflection Map", Cube) = "" {}
	   _NormalStrength("Normal Strength", Range(0.0, 1.0)) = 1
	   _ScrollSpeed("Scrolling Speed", Float) = 1
	   _Shininess("Shininess", Float) = 8
	}

	// FUNCTIONS FOR PASSES OF ALL SUBSHADERS
	CGINCLUDE

	#include "UnityCG.cginc"
	uniform float4 _LightColor0;
	uniform float4 _Color;
	uniform sampler2D _Noise;
	uniform float4 _Noise_ST;
	uniform samplerCUBE _Cube;
	uniform float _NormalStrength;
	uniform float _ScrollSpeed;
	uniform float _Shininess;

	float WhiteNoise(float2 UV)
	{
		return frac(sin(dot(UV, float2(12.9898, 78.233))) * 43758.5453);
	}

	ENDCG



	SubShader  //Different shaders for different platforms
					//Unity chooses the subshader that fits the GPU the best
	{

		Pass //BASE PASS FRONT
		{		 
			Tags {"LightMode" = "ForwardBase"}
			
			ZWrite On
			Cull Back 

			CGPROGRAM //here starts the pure Cg shader code
			//----------------------------------------------------------
			#pragma vertex VS
			#pragma fragment PS
			#include "UnityCG.cginc"

			// GLOBAL VARS
			
		

			// DATA STRUCTURES
			struct vertexIn
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
				float4 tangent : TANGENT;
				
			};
			struct vertexOut
			{
				float4 pos : SV_POSITION;
				float3 normalDir : TEXCOORD0;
				float4 posWorld : TEXCOORD1;
				float4 tex : TEXCOORD2;
				float3 tangentWorld : TEXCOORD3;
				float3 normalWorld : TEXCOORD4;
				float3 binormalWorld : TEXCOORD5;
			};

			
			vertexOut VS(vertexIn input)
			{
				vertexOut output;

				float4x4 modelMatrix = unity_ObjectToWorld;
				float4x4 modelMatrixInverse = unity_WorldToObject;


				output.tangentWorld = normalize(mul(modelMatrix, float4(input.tangent.xyz, 0)).xyz);
				output.normalWorld = normalize(mul(float4(input.normal, 0), modelMatrixInverse).xyz);
				output.binormalWorld = normalize(cross(output.normalWorld, output.tangentWorld) 
										* input.tangent.w); //input.tangent.w specific to unity


				output.normalDir = normalize(mul(float4(input.normal, 0), modelMatrixInverse).xyz);
				output.pos = UnityObjectToClipPos(input.vertex);
				output.posWorld = mul(modelMatrix, input.vertex);
				output.tex = input.texcoord;

				return output;
			}

			float4 PS(vertexOut input) : COLOR
			{
				float4 texNormal1 = tex2D(_Noise, input.tex.xy * _Noise_ST.xy + _Noise_ST.zw + _ScrollSpeed * _Time.xx);
				float4 texNormal2 = tex2D(_Noise, input.tex.xy * _Noise_ST.xy * 1.5 + _Noise_ST.zw + float2(-_ScrollSpeed * 1.3, _ScrollSpeed * 1.2) * _Time.xx);
				
				float4 texNormal = texNormal1 * 0.5 + texNormal2 * (1 - 0.5);

				float4 encodedNormal = texNormal * _NormalStrength + float4(0.5, 0.5, 1, 1) * (1 - _NormalStrength);
				float3 localCoord = float3(2 * encodedNormal.r - 1, 2 * encodedNormal.g - 1, 0);
				localCoord.z = sqrt(1 - dot(localCoord, localCoord));

				float3x3 local2WorldTranspose = float3x3(
					input.tangentWorld,
					input.binormalWorld,
					input.normalWorld);

				float3 normalDir = normalize(mul(localCoord, local2WorldTranspose));

				float3 viewDir = normalize(input.posWorld.xyz - _WorldSpaceCameraPos);

				float3 reflectDir = reflect(viewDir,normalize(normalDir));



				float3 lightDir;
				float attenuation;

				float3 vertexToLight = _WorldSpaceLightPos0.xyz - input.posWorld.xyz;
				float vertexToLightDist = length(vertexToLight);

				float isDir = _WorldSpaceLightPos0.w;
				attenuation = (1 - isDir) + (isDir * (1 / vertexToLightDist));
				// if w = 0 --> directional, so att = 1;      if w = 1, --> LINEAR attenuation;

				lightDir = (isDir) * normalize(vertexToLight) + (1 - isDir) * normalize(_WorldSpaceLightPos0.xyz);
				// if Directional light, use worldspacelightpos, if point or spotlight, use vertex to light

				float3 diffRefl = attenuation * _LightColor0.rgb * _Color.rgb * max(0, dot(normalDir, lightDir));
				
				float specCutOff = step(0, dot(normalDir, lightDir)); //if dot is bigger than 0, return 1, else 0

				float3 specRefl = pow(max(0, dot(-viewDir, reflect(-lightDir, normalDir))), _Shininess) 
									  * attenuation * _LightColor0.rgb * specCutOff;
				
				float4 mappedRefl = texCUBE(_Cube, reflectDir);
				
				return float4(specRefl + mappedRefl.xyz, 1);
            }

			// Techniques

		    //----------------------------------------------------------
			ENDCG // here ends the pure Cg code
        }
		

	}
}