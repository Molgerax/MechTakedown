// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "hda/Exam/Shield" //define the name & folders of our Shader (SurfaceShader)
{
    Properties
    {
		_BumpMap("Normal", 2D) = "bump" {}
		_Color("Diff Color", Color) = (1, 1, 1, 1)
		_Shininess("Shiny", Float) = 8
		_UVTiling("UV Tiling", Vector) = (1, 1, 0, 0)

		//PASSING IN COLLISION POINTS, w is TIME
		_WaveCenter("Wave Center", Vector) = (0, 0, 0, 0)
    }

	// FUNCTIONS FOR PASSES OF ALL SUBSHADERS
	CGINCLUDE
	
	#include "UnityCG.cginc"
	uniform float4 _LightColor0;
	uniform sampler2D _BumpMap;
	uniform float4 _BumpMap_ST;
	uniform float4 _Color;
	uniform float _Shininess;
	uniform float4 _UVTiling;

	const float2 unitTri = float2(1.7320508, 1); //30-60-90 triangle side lengths, used for hexagons

	//Functions
	float distanceFromHex(float2 uv) //returns distance from hex center
	{
		const float hexSize = 0.1;
		float2 p = uv;
		return max(dot(p, unitTri * 0.5), p.y) - hexSize; 
	}

	float4 getHex(float2 uv) //returns Hexagonal grid coordinate
	{
		float4 hexCenter = floor(float4(uv, uv - float2(1, 0.5)) / unitTri.xyxy) + 0.5;

		float4 h = float4(uv - hexCenter.xy * unitTri, uv - (hexCenter.zw + 0.5) * unitTri);

		return dot(h.xy, h.xy) < dot(h.zw, h.zw) 
				? float4(h.xy, hexCenter.xy) 
				: float4(h.zw, hexCenter.zw + 0.5);
	}


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
	};

	// Shader Functions-----------------------
	vertexOut VS(vertexIn input) //Vertex Shader
	{
		vertexOut output;

		float4x4 modelMatrix = unity_ObjectToWorld;
		float4x4 modelMatrixInverse = unity_WorldToObject;

		output.tangentWorld = normalize(mul(modelMatrix, float4(input.tangent.xyz, 0)).xyz);
		output.normalWorld = normalize(mul(float4(input.normal, 0), modelMatrixInverse).xyz);
		output.binormalWorld = normalize(cross(output.normalWorld, output.tangentWorld) 
								* input.tangent.w); //input.tangent.w specific to unity
		
		output.posWorld = mul(modelMatrix, input.pos);
		output.tex = input.texcoords;
		output.pos = UnityObjectToClipPos(input.pos);
		
		return output;
	}

	float4 PSA(vertexOut input) : COLOR //Pixel Shader w/ Ambient Light
	{	
		float4 encodedNormal = tex2D(_BumpMap, input.tex.xy * _BumpMap_ST.xy + _BumpMap_ST.zw);
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

		float2 texoffset = (input.tex.xy * 2 - 1) * _UVTiling.xy + _UVTiling.zw;
		float4 hexes = getHex(texoffset);

		float3 col = float3(distanceFromHex(texoffset), 0, 0);
		//col = float3(texoffset.xy, 0);
		return float4(col, 1);
		//return float4(specRefl + ambientLight + diffRefl, 1);
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
    }
}