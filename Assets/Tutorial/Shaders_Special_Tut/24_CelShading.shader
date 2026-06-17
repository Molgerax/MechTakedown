Shader "Tutorial/24_CelShading" //define the name & folders of our Shader (SurfaceShader)
{
    Properties
    {
		_Color("Diff Color", Color) = (1, 1, 1, 1)
    	_Cutoff("Cutoff", Range(0, 1)) = 0.5
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
            
            float4 frag(Varyings IN) : COLOR 
            {	
            	Light light = GetMainLight();

            	float3 normal = normalize(IN.normalWS);
            	float LdotN = dot(light.direction, normal) * 0.5 + 0.5;

            	float l = 1;

            	//l = smoothstep(0, 1, LdotN);
            	//l = LdotN * 0.5 + 0.5;
				//l *= l;

            	//l = step(_Cutoff, l);

            	l *= 0.5 + step(_Cutoff, LdotN) * 0.5;
            	l *= 0.5 + step(_Cutoff * 0.5, LdotN) * 0.5;
            	
            	
            	float3 color = saturate(l) * _Color;
            	
            	return float4(color, 1);
            }
            	
			ENDHLSL
        }
    }
}