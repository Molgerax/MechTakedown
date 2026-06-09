Shader "hda/NormalMapping_Copied"   //define the name of our Shader (SurfaceShader)
{
	Properties
	{
		_BumpMap ("Normal", 2D) = "bump"{} // "black", "gray", "bump"
		_Color("Diff COlor", Color) = (1,1,1,1)
		_Shininess("Shiny", Float) = 8
	}

	CGINCLUDE

        #include "UnityCG.cginc"
		uniform float4 _LightColor0;
		uniform sampler2D _BumpMap;
		uniform float4 _BumpMap_ST;
		uniform float4 _Color;
		uniform float _Shininess;

		struct vertexIn
		{
			float4 vertex : POSITION;
			float4 texcoord : TEXCOORD0;
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


		// Shader Functions
		vertexOut VS(vertexIn input)
		{
			vertexOut output;

			float4x4 modelMatrix = unity_ObjectToWorld;
			float4x4 modelMatrixInverse = unity_WorldToObject;

			output.tangentWorld = normalize(mul(modelMatrix, float4(input.tangent.xyz, 0)).xyz);
			output.normalWorld = normalize(mul(float4(input.normal, 0), modelMatrixInverse).xyz);
			output.binormalWorld = normalize(cross(output.normalWorld, output.tangentWorld)
				* input.tangent.w); //input.tangent.w specific to unity

			output.posWorld = mul(modelMatrix, input.vertex);
			output.tex = input.texcoord;
			output.pos = UnityObjectToClipPos(input.vertex);

			return output;
		}

		float4 PSA(vertexOut input) : COLOR
		{
			float4 encodedNormal = tex2D(_BumpMap, _BumpMap_ST.xy * input.tex.xy + _BumpMap_ST.zw);
			float3 localCoords = float3(2 * encodedNormal.a - 1, -2 * encodedNormal.g + 1, 0);
			encodedNormal.z = sqrt(1 - dot(localCoords, localCoords));
			//aprx 1 - 0.5 * dot(localCoords, localCoords)

			float3x3 local2WorldTranspose = float3x3(
				input.tangentWorld,
				input.binormalWorld,
				input.normalWorld);

			float3 normalDir = normalize(mul(localCoords, local2WorldTranspose));

			float3 viewDir = normalize(_WorldSpaceCameraPos - input.posWorld.xyz);
			float3 lightDir;
			float att;

			if (_WorldSpaceLightPos0.w == 0) //Directional? 
			{
				att = 1;
				lightDir = normalize(_WorldSpaceLightPos0.xyz);
			}
			else
			{
				float3 vertexToLight = _WorldSpaceLightPos0.xyz - input.posWorld.xyz;
				float dist = length(vertexToLight);
				att = 1 / dist; //linear
				lightDir = normalize(vertexToLight);
			}

			float3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * _Color.rgb;

			float3 diffRefl = att * _Color.rgb * _LightColor0.rgb * max(0, dot(normalDir, lightDir));

			float3 specRefl;
			if (dot(normalDir, lightDir) < 0)
			{
				specRefl = float3(0, 0, 0);
			}
			else
			{
				specRefl = att * _LightColor0.rgb
					* pow(max(0, dot(reflect(-lightDir, normalDir), viewDir)),_Shininess);
			}


			return float4(ambient + diffRefl + specRefl, 1);

		}

		float4 PS(vertexOut input) : COLOR
		{
			float4 encodedNormal = tex2D(_BumpMap, _BumpMap_ST.xy * input.tex.xy + _BumpMap_ST.zw);
			float3 localCoords = float3(2 * encodedNormal.a - 1, 2 * encodedNormal.g - 1, 0);
			encodedNormal.z = sqrt(1 - dot(localCoords, localCoords));
			//aprx 1 - 0.5 * dot(localCoords, localCoords)

			float3x3 local2WorldTranspose = float3x3(
				input.tangentWorld,
				input.binormalWorld,
				input.normalWorld);

			float3 normalDir = normalize(mul(localCoords, local2WorldTranspose));

			float3 viewDir = normalize(_WorldSpaceCameraPos - input.posWorld.xyz);
			float3 lightDir;
			float att;

			if (_WorldSpaceLightPos0.w == 0) //Directional? 
			{
				att = 1;
				lightDir = normalize(_WorldSpaceLightPos0.xyz);
			}
			else
			{
				float3 vertexToLight = _WorldSpaceLightPos0.xyz - input.posWorld.xyz;
				float dist = length(vertexToLight);
				att = 1 / dist; //linear
				lightDir = normalize(vertexToLight);
			}

			float3 diffRefl = att * _Color.rgb * _LightColor0.rgb * max(0, dot(normalDir, lightDir));

			float3 specRefl;
			if (dot(normalDir, lightDir) < 0)
			{
				specRefl = float3(0, 0, 0);
			}
			else
			{
				specRefl = att * _LightColor0.rgb
					* pow(max(0, dot(reflect(-lightDir, normalDir), viewDir)), _Shininess);
			}


			return float4( diffRefl + specRefl, 1);

		}

	ENDCG

	SubShader
	{
		Pass 
		{
			Tags {"LightMode" = "ForwardBase"}
			CGPROGRAM 
			//----------------------------------------------------------
			#pragma vertex VS
			#pragma fragment PSA
		    //----------------------------------------------------------
			ENDCG 
        }
		Pass 
		{
			Tags {"LightMode" = "ForwardAdd"}
			Blend One One
			CGPROGRAM 
			//----------------------------------------------------------

			#pragma vertex VS
			#pragma fragment PS
			//----------------------------------------------------------
			ENDCG 
		}

	}
}

