// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "hda/PixelPhongTexture" //define the name & folders of our Shader (SurfaceShader)
{
    Properties
    {
		_MainTex("Textured Image", 2D) = "white" {}
		_SpecColor("Spec Mat Color", Color) = (1, 1, 1, 1)
		_Shininess("Shiny Power", Float) = 8
    }
    SubShader //multiple subshaders for different GPUs, Unity will choose the most suited one for current application
    {

        Pass //BASE PASS FRONT
        {
			Tags {"LightMode" = "ForwardBase"}
			Cull Back

            CGPROGRAM //here starts the pure Cg shader code
			//------------------------------------------------------------------	
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc" 
			// -->from UnityLightingCommon.cginc

			// GLOBAL VARS
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;
			uniform float4 _SpecColor;
			uniform float _Shininess;
			uniform float4 _LightColor0;
			
			// DATA STRUCTURES
			struct vertexIn
			{
				float4 pos : POSITION;
				float3 normal : NORMAL;
				float4 texcoords : TEXCOORD0;

			};
			struct vertexOut
			{
				float4 pos : SV_POSITION;
				float4 tex : TEXCOORD0;
				float4 posWorld : TEXCOORD1;
				float3 normalDir : TEXCOORD2;
			};

			// Shader Functions-----------------------


			vertexOut vert(vertexIn input)
			{
				vertexOut output;

				float4x4 modelMatrix = unity_ObjectToWorld;
				float4x4 modelMatrixInverse = unity_WorldToObject;

				output.tex = input.texcoords;

				output.posWorld = mul(modelMatrix, input.pos);
				output.normalDir = normalize(mul(float4(input.normal, 1), modelMatrixInverse).xyz); //float3 normalDir = UnityObjectToWorldNormal(input.normal); //<-- does the same
				output.pos = UnityObjectToClipPos(input.pos);

				return output;
			}

			float4 frag(vertexOut input) : COLOR 
			{
				float4 col = tex2D(_MainTex, input.tex.xy);
				float3 normalDir = normalize(input.normalDir);

				float3 viewDir = normalize(_WorldSpaceCameraPos - input.posWorld.xyz);


				float3 lightDir;
				float attenuation;

				float3 vertexToLight = _WorldSpaceLightPos0.xyz - input.posWorld.xyz;
				float vertexToLightDist = length(vertexToLight);

				//--Emulate if statement, directional light -> w = 0
				float isDir = _WorldSpaceLightPos0.w;
				attenuation = (1 - isDir) + (isDir * (1 / vertexToLightDist));
				// if w = 0 --> att = 1, if w = 1, --> LINEAR attenuation;

				lightDir = (isDir) * normalize(vertexToLight) + (1 - isDir) * normalize(_WorldSpaceLightPos0.xyz);
				// if Directional light, use worldspacelightpos, if point or spotlight, use vertex to light

				float3 ambientLight = UNITY_LIGHTMODEL_AMBIENT.rgb * col.rgb;

				float3 diffRefl = attenuation * _LightColor0.rgb * col.rgb * max(0, dot(normalDir, lightDir));
				
				
				//either 0 or 1, cuts off if light is behind you
				float specCutOff = clamp(10000000 * dot(normalDir, lightDir), 0, 1);

				float3 specRefl = pow(max(0, dot(viewDir, reflect(-lightDir, normalDir))), _Shininess) 
									  * attenuation * _LightColor0.rgb * _SpecColor.rgb * specCutOff;

				return float4(ambientLight + diffRefl + specRefl, 1);
			}
			
			// Techniques

			//------------------------------------------------------------------
			ENDCG //here ends the pure Cg code
        }
		
		Pass //ADD PASS FRONT
        {
			Tags {"LightMode" = "ForwardAdd"}
			Cull Back
			Blend One One

            CGPROGRAM //here starts the pure Cg shader code
			//------------------------------------------------------------------	
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc" 
			// -->from UnityLightingCommon.cginc

			// GLOBAL VARS
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;
			uniform float4 _SpecColor;
			uniform float _Shininess;
			uniform float4 _LightColor0;
			
			// DATA STRUCTURES
			struct vertexIn
			{
				float4 pos : POSITION;
				float3 normal : NORMAL;
				float4 texcoords : TEXCOORD0;

			};
			struct vertexOut
			{
				float4 pos : SV_POSITION;
				float4 tex : TEXCOORD0;
				float4 posWorld : TEXCOORD1;
				float3 normalDir : TEXCOORD2;
			};

			// Shader Functions-----------------------


			vertexOut vert(vertexIn input)
			{
				vertexOut output;

				float4x4 modelMatrix = unity_ObjectToWorld;
				float4x4 modelMatrixInverse = unity_WorldToObject;

				output.tex = input.texcoords;

				output.posWorld = mul(modelMatrix, input.pos);
				output.normalDir = normalize(mul(float4(input.normal, 1), modelMatrixInverse).xyz); //float3 normalDir = UnityObjectToWorldNormal(input.normal); //<-- does the same
				output.pos = UnityObjectToClipPos(input.pos);

				return output;
			}

			float4 frag(vertexOut input) : COLOR 
			{
				float4 col = tex2D(_MainTex, input.tex.xy);
				float3 normalDir = normalize(input.normalDir);

				float3 viewDir = normalize(_WorldSpaceCameraPos - input.posWorld.xyz);


				float3 lightDir;
				float attenuation;

				float3 vertexToLight = _WorldSpaceLightPos0.xyz - input.posWorld.xyz;
				float vertexToLightDist = length(vertexToLight);

				//--Emulate if statement, directional light -> w = 0
				float isDir = _WorldSpaceLightPos0.w;
				attenuation = (1 - isDir) + (isDir * (1 / vertexToLightDist));
				// if w = 0 --> att = 1, if w = 1, --> LINEAR attenuation;

				lightDir = (isDir) * normalize(vertexToLight) + (1 - isDir) * normalize(_WorldSpaceLightPos0.xyz);
				// if Directional light, use worldspacelightpos, if point or spotlight, use vertex to light

				float3 diffRefl = attenuation * _LightColor0.rgb * col.rgb * max(0, dot(normalDir, lightDir));
				
				
				//either 0 or 1, cuts off if light is behind you
				float specCutOff = clamp(10000000 * dot(normalDir, lightDir), 0, 1);

				float3 specRefl = pow(max(0, dot(viewDir, reflect(-lightDir, normalDir))), _Shininess) 
									  * attenuation * _LightColor0.rgb * _SpecColor.rgb * specCutOff;

				return float4(diffRefl + specRefl, 1);
			}
			
			// Techniques

			//------------------------------------------------------------------
			ENDCG //here ends the pure Cg code
        }

		Pass //BASE PASS BACK
        {
			Tags {"LightMode" = "ForwardBase"}
			Cull Front

            CGPROGRAM //here starts the pure Cg shader code
			//------------------------------------------------------------------	
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc" 
			// -->from UnityLightingCommon.cginc

			// GLOBAL VARS
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;
			uniform float4 _SpecColor;
			uniform float _Shininess;
			uniform float4 _LightColor0;
			
			// DATA STRUCTURES
			struct vertexIn
			{
				float4 pos : POSITION;
				float3 normal : NORMAL;
				float4 texcoords : TEXCOORD0;

			};
			struct vertexOut
			{
				float4 pos : SV_POSITION;
				float4 tex : TEXCOORD0;
				float4 posWorld : TEXCOORD1;
				float3 normalDir : TEXCOORD2;
			};

			// Shader Functions-----------------------


			vertexOut vert(vertexIn input)
			{
				vertexOut output;

				float4x4 modelMatrix = unity_ObjectToWorld;
				float4x4 modelMatrixInverse = unity_WorldToObject;

				output.tex = input.texcoords;

				output.posWorld = mul(modelMatrix, input.pos);
				output.normalDir = normalize(mul(float4(-input.normal, 1), modelMatrixInverse).xyz); //float3 normalDir = UnityObjectToWorldNormal(input.normal); //<-- does the same
				output.pos = UnityObjectToClipPos(input.pos);

				return output;
			}

			float4 frag(vertexOut input) : COLOR 
			{
				float4 col = tex2D(_MainTex, input.tex.xy);
				float3 normalDir = normalize(input.normalDir);

				float3 viewDir = normalize(_WorldSpaceCameraPos - input.posWorld.xyz);


				float3 lightDir;
				float attenuation;

				float3 vertexToLight = _WorldSpaceLightPos0.xyz - input.posWorld.xyz;
				float vertexToLightDist = length(vertexToLight);

				//--Emulate if statement, directional light -> w = 0
				float isDir = _WorldSpaceLightPos0.w;
				attenuation = (1 - isDir) + (isDir * (1 / vertexToLightDist));
				// if w = 0 --> att = 1, if w = 1, --> LINEAR attenuation;

				lightDir = (isDir) * normalize(vertexToLight) + (1 - isDir) * normalize(_WorldSpaceLightPos0.xyz);
				// if Directional light, use worldspacelightpos, if point or spotlight, use vertex to light

				float3 ambientLight = UNITY_LIGHTMODEL_AMBIENT.rgb * col.rgb;

				float3 diffRefl = attenuation * _LightColor0.rgb * col.rgb * max(0, dot(normalDir, lightDir));
				
				
				//either 0 or 1, cuts off if light is behind you
				float specCutOff = clamp(10000000 * dot(normalDir, lightDir), 0, 1);

				float3 specRefl = pow(max(0, dot(viewDir, reflect(-lightDir, normalDir))), _Shininess) 
									  * attenuation * _LightColor0.rgb * _SpecColor.rgb * specCutOff;

				return float4(ambientLight + diffRefl + specRefl, 1);
			}
			
			// Techniques

			//------------------------------------------------------------------
			ENDCG //here ends the pure Cg code
        }
		
		Pass //ADD PASS BACK
        {
			Tags {"LightMode" = "ForwardAdd"}
			Cull Front
			Blend One One

            CGPROGRAM //here starts the pure Cg shader code
			//------------------------------------------------------------------	
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc" 
			// -->from UnityLightingCommon.cginc

			// GLOBAL VARS
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;
			uniform float4 _SpecColor;
			uniform float _Shininess;
			uniform float4 _LightColor0;
			
			// DATA STRUCTURES
			struct vertexIn
			{
				float4 pos : POSITION;
				float3 normal : NORMAL;
				float4 texcoords : TEXCOORD0;

			};
			struct vertexOut
			{
				float4 pos : SV_POSITION;
				float4 tex : TEXCOORD0;
				float4 posWorld : TEXCOORD1;
				float3 normalDir : TEXCOORD2;
			};

			// Shader Functions-----------------------


			vertexOut vert(vertexIn input)
			{
				vertexOut output;

				float4x4 modelMatrix = unity_ObjectToWorld;
				float4x4 modelMatrixInverse = unity_WorldToObject;

				output.tex = input.texcoords;

				output.posWorld = mul(modelMatrix, input.pos);
				output.normalDir = normalize(mul(float4(-input.normal, 1), modelMatrixInverse).xyz); //float3 normalDir = UnityObjectToWorldNormal(input.normal); //<-- does the same
				output.pos = UnityObjectToClipPos(input.pos);

				return output;
			}

			float4 frag(vertexOut input) : COLOR 
			{
				float4 col = tex2D(_MainTex, input.tex.xy);
				float3 normalDir = normalize(input.normalDir);

				float3 viewDir = normalize(_WorldSpaceCameraPos - input.posWorld.xyz);


				float3 lightDir;
				float attenuation;

				float3 vertexToLight = _WorldSpaceLightPos0.xyz - input.posWorld.xyz;
				float vertexToLightDist = length(vertexToLight);

				//--Emulate if statement, directional light -> w = 0
				float isDir = _WorldSpaceLightPos0.w;
				attenuation = (1 - isDir) + (isDir * (1 / vertexToLightDist));
				// if w = 0 --> att = 1, if w = 1, --> LINEAR attenuation;

				lightDir = (isDir) * normalize(vertexToLight) + (1 - isDir) * normalize(_WorldSpaceLightPos0.xyz);
				// if Directional light, use worldspacelightpos, if point or spotlight, use vertex to light

				float3 diffRefl = attenuation * _LightColor0.rgb * col.rgb * max(0, dot(normalDir, lightDir));
				
				
				//either 0 or 1, cuts off if light is behind you
				float specCutOff = clamp(10000000 * dot(normalDir, lightDir), 0, 1);

				float3 specRefl = pow(max(0, dot(viewDir, reflect(-lightDir, normalDir))), _Shininess) 
									  * attenuation * _LightColor0.rgb * _SpecColor.rgb * specCutOff;

				return float4(diffRefl + specRefl, 1);
			}
			
			// Techniques

			//------------------------------------------------------------------
			ENDCG //here ends the pure Cg code
        }
    }
}