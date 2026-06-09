// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "hda/Transparency" //define the name & folders of our Shader (SurfaceShader)
{
    Properties
    {
		_Color("Color", Color) = (1, 1, 1, 1)
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
			
			Blend SrcAlpha OneMinusSrcAlpha //standard alpha blending


            CGPROGRAM //here starts the pure Cg shader code
			//------------------------------------------------------------------	
			#pragma vertex VS
			#pragma fragment PS
			#include "UnityCG.cginc"
			// GLOBAL VARS
			uniform float4 _Color;

			// DATA STRUCTURES
			// Shader Functions-----------------------


			float4 VS(float4 pos : POSITION) : SV_POSITION
			{
				float4 output;
				output = UnityObjectToClipPos(pos);
				return output;
			}

			float4 PS(void) : COLOR 
			{
				return _Color;
			}
			
			// Techniques

			//------------------------------------------------------------------
			ENDCG //here ends the pure Cg code
        }
    }
}