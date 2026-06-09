// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "hda/ParallaxMapping" //define the name & folders of our Shader (SurfaceShader)
{
    Properties
    {
		_BumpMap("Normal", 2D) = "bump" {}
		_Color("Diff Color", Color) = (1, 1, 1, 1)
		_Shininess("Shiny", Float) = 8
		_ParallaxMap("Heightmap", 2D) = "black" {}
		_Parallax("Height", Range(0.0, 0.1)) = 0.01
		_MaxOffset("Max Offset", Range(0.0, 0.5)) = 0.01
    }

	// FUNCTIONS FOR PASSES OF ALL SUBSHADERS
	CGINCLUDE
	
	#include "UnityCG.cginc"
	uniform float4 _LightColor0;
	uniform sampler2D _BumpMap;
	uniform float4 _BumpMap_ST;
	uniform float4 _Color;
	uniform float _Shininess;
	uniform sampler2D _ParallaxMap;
	uniform float4 _ParallaxMap_ST;
	uniform float _Parallax;
	uniform float _MaxOffset;

	struct vertexIn
	{
		float4 pos : POSITION;
		float4 texcoords : TEXCOORD0;
		float3 normal : NORMAL;
		float4 tangent : TANGENT;
	};

	struct vertexOut
	{
		float4 pos : SV_POSITION;
		float4 tex : TEXCOORD0;
		float4 posWorld : TEXCOORD1;
		float3 tangentWorld : TEXCOORD2;
		float3 normalWorld : TEXCOORD3;
		float3 binormalWorld : TEXCOORD4;
		float3 viewDirWorld : TEXCOORD5;
		float3 viewDirSSC : TEXCOORD6; //scaled surface coords
	};

	// Shader Functions-----------------------
	vertexOut VS(vertexIn input)
	{
		vertexOut output;

		float4x4 modelMatrix = unity_ObjectToWorld;
		float4x4 modelMatrixInverse = unity_WorldToObject;

		output.tangentWorld = normalize(mul(modelMatrix, float4(input.tangent.xyz, 0)).xyz);
		output.normalWorld = normalize(mul(float4(input.normal, 0), modelMatrixInverse).xyz);
		output.binormalWorld = normalize(cross(output.normalWorld, output.tangentWorld) 
								* input.tangent.w); //input.tangent.w specific to unity
		
		float3 binormal = cross(input.normal, input.tangent.xyz) * input.tangent.w;
		float3 viewDirObject = mul(modelMatrixInverse, float4(_WorldSpaceCameraPos, 1)).xyz - input.pos.xyz;

		float3x3 localSurface2SOT = float3x3 (
					input.tangent.xyz,
					binormal,
					input.normal);

		output.viewDirSSC = mul(localSurface2SOT, viewDirObject);
		output.posWorld = mul(modelMatrix, input.pos);
		output.viewDirWorld = normalize(_WorldSpaceCameraPos - output.posWorld.xyz);
		output.tex = input.texcoords;
		output.pos = UnityObjectToClipPos(input.pos);
		
		return output;
	}

	float4 PSA(vertexOut input) : COLOR 
	{	
		float height = _Parallax * (-0.5 + tex2D(_ParallaxMap, input.tex.xy 
						* _ParallaxMap_ST.xy + _ParallaxMap_ST.zw).x);
		
		float2 texCoordOffset = clamp(height * input.viewDirSSC.xy / input.viewDirSSC.z, -_MaxOffset, _MaxOffset);


		float4 encodedNormal = tex2D(_BumpMap, _BumpMap_ST.xy * (input.tex.xy + texCoordOffset) + _BumpMap_ST.zw);

		float3 localCoord = float3(2 * encodedNormal.r - 1, 2 * encodedNormal.g - 1, 0);
		localCoord.z = sqrt(1 - dot(localCoord, localCoord));

		float3x3 local2WorldTranspose = float3x3(
				input.tangentWorld,
				input.binormalWorld,
				input.normalWorld);

		float3 normalDir = normalize(mul(localCoord, local2WorldTranspose));

		float3 viewDir = normalize(_WorldSpaceCameraPos - input.posWorld.xyz);
		float3 lightDir;
		float attenuation;

		/*
		if (_WorldSpaceLightPos0.w == 0) //Directional? 
		{
			attenuation = 1;
			lightDir = normalize(_WorldSpaceLightPos0.xyz);
		}
		else
		{
			float3 vertexToLight = _WorldSpaceLightPos0.xyz - input.posWorld.xyz;
			float dist = length(vertexToLight);
			attenuation = 1 / dist; //linear
			lightDir = normalize(vertexToLight);
		}*/
		
		
		float3 vertexToLight = _WorldSpaceLightPos0.xyz - input.posWorld.xyz;
		float vertexToLightDist = length(vertexToLight);

		float isDir = _WorldSpaceLightPos0.w;
		attenuation = (1 - isDir) + (isDir * (1 / vertexToLightDist));
		// if w = 0 --> directional, so att = 1;      if w = 1, --> LINEAR attenuation;

		lightDir = (isDir) * normalize(vertexToLight) + (1 - isDir) * normalize(_WorldSpaceLightPos0.xyz);
		// if Directional light, use worldspacelightpos, if point or spotlight, use vertex to light
		

		float3 diffRefl = attenuation * _LightColor0.rgb * _Color.rgb * max(0, dot(normalDir, lightDir));
		
		float3 ambientLight = UNITY_LIGHTMODEL_AMBIENT.rgb * _Color.rgb;

		float specCutOff = step(0, dot(normalDir, lightDir)); //if dot is bigger than 0, return 1, else 0

		float3 specRefl = pow(max(0, dot(viewDir, reflect(-lightDir, normalDir))), _Shininess) 
							  * attenuation * _LightColor0.rgb * specCutOff;

		return float4(specRefl + ambientLight + diffRefl, 1);
	}

	float4 PS(vertexOut input) : COLOR 
	{	
		float4 encodedNormal = tex2D(_BumpMap, input.tex.xy * _BumpMap_ST.xy + _BumpMap_ST.zw);
		float3 localCoord = float3(2 * encodedNormal.a - 1, 2 * encodedNormal.g - 1, 0);
		encodedNormal.z = sqrt(1 - dot(localCoord, localCoord));

		float3x3 local2WorldTranspose = float3x3(
				input.tangentWorld,
				input.binormalWorld,
				input.normalWorld);

		float3 normalDir = normalize(mul(localCoord, local2WorldTranspose));

		float3 viewDir = normalize(_WorldSpaceCameraPos - input.posWorld.xyz);
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

		float3 specRefl = pow(max(0, dot(viewDir, reflect(-lightDir, normalDir))), _Shininess) 
							  * attenuation * _LightColor0.rgb * specCutOff;

		return float4(specRefl + diffRefl, 1);
	}

	ENDCG


    SubShader //multiple subshaders for different GPUs, Unity will choose the most suited one for current application
    {

        Pass //PASS 0 -- BASE with Ambient Light
        {
			Tags {"LightMode" = "ForwardBase"}

            CGPROGRAM //here starts the pure Cg shader code
			//------------------------------------------------------------------	
			#pragma vertex VS
			#pragma fragment PSA
			//------------------------------------------------------------------
			ENDCG //here ends the pure Cg code
        }
		Pass //PASS 1 -- ADD without Ambient Light
        {
			Tags {"LightMode" = "ForwardAdd"}
			Blend One One


            CGPROGRAM //here starts the pure Cg shader code
			//------------------------------------------------------------------	
			#pragma vertex VS
			#pragma fragment PS
			//------------------------------------------------------------------
			ENDCG //here ends the pure Cg code
        }
    }
}