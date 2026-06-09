// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "hda/VertexDiffuseTexture" //define the name & folders of our Shader (SurfaceShader)
{
    Properties
    {
		_MainTex("Textured Image", 2D) = "white" {}
    }
    SubShader //multiple subshaders for different GPUs, Unity will choose the most suited one for current application
    {

        Pass //multiple passes are possible, good for transparency, glass, etc.
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

				output.tex = input.texcoords;

				output.pos = UnityObjectToClipPos(input.pos);
				output.col = float4(diffRefl, 1);
				return output;
			}

			float4 frag(vertexOut input) : COLOR 
			{
				return tex2D(_MainTex, (input.tex.xy * _MainTex_ST.xy) + _MainTex_ST.zw) * input.col;
			}
			
			// Techniques

			//------------------------------------------------------------------
			ENDCG //here ends the pure Cg code
        }
    }
}