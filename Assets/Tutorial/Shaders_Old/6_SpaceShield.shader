// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "hda/SpaceShield" //define the name & folders of our Shader (SurfaceShader)
{
    Properties
    {
		_Color("Color", Color) = (1, 1, 1, 0.5)
		_Decay("Decay", Float) = 0.0
		//_CollisionPoint("CollisionPoint", Float)
    }
    SubShader //multiple subshaders for different GPUs, Unity will choose the most suited one for current application
    {
		Tags 
		{
			"Queue" = "Transparent"
		}

        Pass //multiple passes are possible, good for transparency, glass, etc.
        {
			ZWrite Off
			// Cull Off
			
			Blend SrcAlpha OneMinusSrcAlpha //standard alpha blending
						// One, Zero, SrcColor, SrcAlpha, DstAlpha, DstColor
						// OneMinusSrcAlpha, OneMinusSrcColor,...

            CGPROGRAM //here starts the pure Cg shader code
			//------------------------------------------------------------------	
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			// GLOBAL VARS
			uniform float4 _Color;
			uniform float _Decay;
			

			// DATA STRUCTURES
			struct vertexIn
			{
				float4 pos : POSITION;
				float3 normal : NORMAL;
			};
			struct vertexOut
			{
				float4 pos : SV_POSITION;
				float3 normal : TEXCOORD0;  //once again abusing texture coords as 
				float3 viewDir : TEXCOORD1; //dump for our data
			};

			// Shader Functions-----------------------


			vertexOut vert(vertexIn input)
			{
				vertexOut output;
				float4x4 modelMatrix = unity_ObjectToWorld;
				float4x4 modelMatrixInverse = unity_WorldToObject;

				output.normal = normalize(mul( float4(input.normal, 1), modelMatrixInverse).xyz); 
							// multiplies float3 with matrix4, then only use 3 with swizzles
				
				output.viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(modelMatrix, input.pos).xyz);
							// first get vertex position by multiplying the modelMatrix with the vertex pos
							// then subtract the position vector from the camera position vector to get the viewDirection
							// then normalize to not fuck up the dot product
				output.pos = UnityObjectToClipPos(input.pos);
				return output;
			}

			float4 frag(vertexOut input) : COLOR 
			{
				float3 normalDir = normalize(input.normal); // Because we don't know what Unity does in the background, for safety!
				float3 viewDir = normalize(input.viewDir); // FOR SAFETY!!

				float Opac = min(1, _Color.a / abs( dot(normalDir, viewDir)));
						// min clamps this between 0 and 1, because abs doesn't let it get negative
						// The opacity is always at least the Color Alpha, towards the edges, it increases strongly

				//return float4(normalDir, 1); //test for normal direction
				return float4(_Color.rgb, Opac * _Decay);
			}
			
			// Techniques

			//------------------------------------------------------------------
			ENDCG //here ends the pure Cg code
        }
    }
}