// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "hda/VertexDiffuseLight" //define the name & folders of our Shader (SurfaceShader)
{
    Properties
    {
		_Color("Color", Color) = (1, 1, 1, 1)
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
			uniform float4 _Color;
			uniform float4 _LightColor0;
			
			// DATA STRUCTURES
			struct vertexIn
			{
				float4 pos : POSITION;
				float3 normal : NORMAL;

			};
			struct vertexOut
			{
				float4 pos : SV_POSITION;
				float4 col : COLOR;
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
				
				float3 diffRefl = _LightColor0.rgb * _Color.rgb * max(0, dot(normalDir, lightDir));

				output.pos = UnityObjectToClipPos(input.pos);
				output.col = float4(diffRefl, 1);
				return output;
			}

			float4 frag(vertexOut input) : COLOR 
			{
				return input.col;
			}
			
			// Techniques

			//------------------------------------------------------------------
			ENDCG //here ends the pure Cg code
        }
    }
}