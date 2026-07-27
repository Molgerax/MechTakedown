Shader "Tutorial/19_Procedural" 
{
    Properties
    {
		_Color("Diff Color", Color) = (1, 1, 1, 1)
    	_Frequency("Frequency", Float) = 4
    }
    

    SubShader 
    {
    	Tags 
        { 
            "RenderPipeline" = "UniversalPipeline" 
            "RenderType" = "Opaque" 
            "Queue" = "Geometry" 
        }

        Pass 
        {
            HLSLPROGRAM 

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            
            struct Attributes
            {
            	float4 positionOS : POSITION;
            	float4 uv : TEXCOORD0;
            };
            
            struct Varyings
            {
            	float4 positionHCS : SV_POSITION;
            	float4 uv : TEXCOORD0;
            };

            
            CBUFFER_START(UnityPerMaterial)
            	float4 _Color;
				float _Frequency;
            CBUFFER_END
            
            Varyings vert(Attributes IN)
            {
            	Varyings output;
            	
            	output.positionHCS = TransformObjectToHClip(IN.positionOS);
            	output.uv = IN.uv;
            	
            	return output;
            }

            
            float4 frag(Varyings IN) : COLOR 
            {
            	float2 uv = IN.uv;

            	
            	// A simple math trick:
            	// floor(x) rounds any value down to the nearest integer, i.e. 0.3 => 0.0, 3.7 => 3.0, etc.
            	// "%" is the modulo operator, so it returns the remainder of a division
            	// e.g. 10 % 3 = 1, 2 % 2 = 0, 12 % 7 = 5, etc
            	// for both x and y axis, "checker" basically becomes a square wave
            	float2 checker = floor(uv * _Frequency) % 2;
            	
            	// when we add both of the checker values and modulo 2 them, we basically do an XOR operation
            	// 0 ^ 0 = 0, 0 ^ 1 = 1, 1 ^ 1 = 0
            	// This results in a checker pattern.
            	float checkerSum = (checker.x + checker.y) % 2;

            	float3 color = checkerSum  * _Color;
            	
            	// For a fun debug view, you can also just return the checker value and see the kind of pattern it forms
            	//return float4(checker.r, checker.g, 0, 1);
            	
            	return float4(color, 1);
            }
            	
			ENDHLSL
        }
    }
}