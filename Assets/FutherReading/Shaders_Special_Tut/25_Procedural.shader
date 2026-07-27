Shader "Tutorial/25_Procedural" //define the name & folders of our Shader (SurfaceShader)
{
    Properties
    {
		_Color("Diff Color", Color) = (1, 1, 1, 1)
    	_Cutoff("Cutoff", Range(0, 1)) = 0.5
    	_Frequency("Frequency", Float) = 1
    }
    

    SubShader //multiple subshaders for different GPUs, Unity will choose the most suited one for current application
    {
    	Tags 
        { 
            "RenderPipeline" = "UniversalPipeline" 
            "RenderType" = "Opaque" 
            "Queue" = "Geometry" 
        }

        Pass //PASS 0 -- BASE with Ambient Light
        {
			Tags {"LightMode" = "UniversalForward"}

            HLSLPROGRAM //here starts the pure Cg shader code

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            
            struct Attributes
            {
            	float4 pos : POSITION;
            	float4 uv : TEXCOORD0;
            	float3 normal : NORMAL;
            	float4 tangent : TANGENT;
            };
            
            struct Varyings
            {
            	float4 pos : SV_POSITION;
            	float4 uv : TEXCOORD0;
            	float3 posWS : TEXCOORD1;
            	float4 tangentWS : TEXCOORD2;
            	float3 normalWS : TEXCOORD3;
            	float3 viewDirWS : TEXCOORD4;
            };

            
            CBUFFER_START(UnityPerMaterial)
            	float4 _LightColor0;
            	float4 _Color;
				float _Cutoff;
				float _Frequency;
            CBUFFER_END
            
            // Shader Functions-----------------------
            Varyings vert(Attributes IN)
            {
            	Varyings output;
            	
				// New way of doing it
            	VertexNormalInputs inputs = GetVertexNormalInputs(IN.normal, IN.tangent);
            	output.tangentWS = float4(inputs.tangentWS, IN.tangent.w);
            	output.normalWS = inputs.normalWS;
            	
            	output.pos = TransformObjectToHClip(IN.pos);
            	output.posWS = TransformObjectToWorld(IN.pos);
            	output.uv = IN.uv;
            	output.viewDirWS = GetWorldSpaceNormalizeViewDir(output.posWS);
            	
            	return output;
            }


            static const float2 unitTri = float2(1, 1.7320508); //(1, sqrt(3)), 30-60-90 triangle side lengths, used for hexagon calculation
			static const float sqrt2 = 1.41421;
            
            float dfHex(float2 uv) {
				float2 p = abs(uv);
				return max(dot(p, unitTri * 0.5), p.x) * 2;
			} // returns 0 in middle, 1 at edge

            
            float4 frag(Varyings IN) : COLOR 
            {
            	float2 uv = IN.uv;

            	float triWave = abs(2 * frac(uv.x * _Frequency) - 1);

            	//triWave = sin(uv.x * _Frequency) * 0.5 + 0.5;
            	triWave = frac(uv.x * _Frequency);

            	triWave = smoothstep(0, 1, triWave);


            	float2 checker = floor(uv * _Frequency) % 2;
            	triWave = (checker.x + checker.y) % 2;

				triWave = dfHex(uv * _Frequency);
            	//triWave = saturate(triWave);

            	triWave = step(_Cutoff, triWave);
            	
            	float diff = abs(uv.y - triWave);
            	diff = smoothstep(_Cutoff, 0, diff);
            	
            	float3 color = triWave  * _Color;
				//color = diff * _Color;
            	
            	return float4(color, 1);
            }
            	
			ENDHLSL
        }
    }
}