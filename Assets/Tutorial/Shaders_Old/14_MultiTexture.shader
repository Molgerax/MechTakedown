// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "hda/MultiTexture" //define the name & folders of our Shader (SurfaceShader)
{
    Properties
    {
		_Color("Color", Color) = (1, 1, 1, 1)
		_MainTex("Textured Image", 2D) = "white" {}
		_NightTex("Textured Image", 2D) = "white" {}
    }
    SubShader //multiple subshaders for different GPUs, Unity will choose the most suited one for current application
    {

        Pass //PASS 0 -- BASE BACK, needs to render backside first due to no depth test
        {
			Tags {"LightMode" = "ForwardBase"}

            CGPROGRAM //here starts the pure Cg shader code
			//------------------------------------------------------------------	
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			// GLOBAL VARS
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;
			uniform sampler2D _NightTex;
			uniform float4 _NightTex_ST;
			uniform float4 _Color;
			uniform float _Cutoff;
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
				float4 col : COLOR;
				float4 tex : TEXCOORD0;
				float lol : TEXCOORD1;
			};

			// Shader Functions-----------------------


			vertexOut vert(vertexIn input)
			{
				vertexOut output;
				float4x4 modelMatrix = unity_ObjectToWorld;
				float4x4 modelMatrixInverse = unity_WorldToObject;

				float3 normalDir = normalize(mul(float4(input.normal, 1), modelMatrixInverse).xyz);
				//float3 normalDir = UnityObjectToWorldNormal(input.normal); //<-- does the same

				float3 lightDir = normalize(_WorldSpaceLightPos0.rgb);
				
				float3 diffRefl = _LightColor0.rgb * max(0, dot(normalDir, lightDir));

				output.lol = max(0, dot(normalDir, lightDir)); //maps between 0 and 1
				
				output.tex = input.texcoords;

				output.pos = UnityObjectToClipPos(input.pos);
				output.col = float4(diffRefl, 1);
				return output;
			}

			float4 frag(vertexOut input) : COLOR 
			{
				float4 texColDay = tex2D(_MainTex, (input.tex.xy * _MainTex_ST.xy) + _MainTex_ST.zw);
				float4 texColNight = tex2D(_NightTex, (input.tex.xy * _NightTex_ST.xy) + _NightTex_ST.zw) * 0.5f;
				
				float4 finalCol = lerp(texColNight, texColDay, input.lol); 

				return finalCol;
			}
			
			// Techniques

			//------------------------------------------------------------------
			ENDCG //here ends the pure Cg code
        }
    }
}