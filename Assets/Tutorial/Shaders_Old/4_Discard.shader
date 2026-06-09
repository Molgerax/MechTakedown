// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "hda/Discard" //define the name & folders of our Shader (SurfaceShader)
{
    Properties
    {
		_Percentage("Percentage", Float) = 1.0
    }
    SubShader //multiple subshaders for different GPUs, Unity will choose the most suited one for current application
    {
        Pass //multiple passes are possible, good for transparency, glass, etc.
        {
			Cull Off //Set backface culling

            CGPROGRAM //here starts the pure Cg shader code
			//------------------------------------------------------------------	
			#pragma vertex VS
			#pragma fragment PS
			#include "UnityCG.cginc"
			// GLOBAL VARS
			uniform float _Percentage;

			// DATA STRUCTURES

			struct vertexIn
			{
				float4 pos : POSITION;
			};

			struct vertexOut //used to transfer data from vert to frag
			{
				float4 pos : SV_POSITION;
            	float4 col : TEXCOORD0; //usually used for UVs, now abused to save color
				float4 posObject : TEXCOORD1;
			};

			// Shader Functions-----------------------


			vertexOut VS(vertexIn input)
			{
				vertexOut output;
				output.pos = UnityObjectToClipPos(input.pos); //mul()
				output.col = input.pos + float4(0.5, 0.5, 0.5, 0); 
				output.posObject = input.pos;
				return output;
			}

			float4 PS(vertexOut input) : COLOR 
			{
				
				clip(-0.5 * input.posObject.y - 0.5 + _Percentage);

				return input.col;
			}
			
			// Techniques

			//------------------------------------------------------------------
			ENDCG //here ends the pure Cg code
        }
    }
}