Shader "Tutorial/3_MoreProperties"
{
    Properties
    {
        _ColorA("Color A", Color) = (1, 1, 1, 1)
		_ColorB("Color B", Color) = (0, 0, 0, 1)
		_RingScale("Ring Scale", Float) = 5				// We can also use Float values as inputs
	    _Sphere("Sphere Center", Vector) = (0, 0, 0, 0) // This is how we use Vectors as properties, standard is a float4
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
            
			struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
            };

            // Don't forget to add all your properties here in the CBuffer, otherwise you can't use them in the code!
            CBUFFER_START(UnityPerMaterial)
				float4 _ColorA; 
				float4 _ColorB; 
				float _RingScale;
				float4 _Sphere;
            CBUFFER_END
            
			Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
            	// Time for some math: The distance(a, b) function returns the distance between two points. This works for
            	// float, float2, float3 and float4!
            	// We take the distance between the world position of the pixel, and the sphere center.
            	float dist = distance(IN.positionWS.xyz, _Sphere.xyz);
            	
            	// The frac(x) function returns only the fractional part of a number, so it goes from 0 to 1 and then snaps back to 0
            	// In this case, this will result in rings that form around the sphere center
            	// By changing "_RingScale" on the material, we can make the rings thinner or thicker
            	float rings = frac(dist * _RingScale);
            	
            	// The lerp(a, b, t) function blends between a and b using t: if t is 0, it retuns a, if t is 1, it returns b, 
            	// and a number between means a blend of a and b
				float3 color = lerp(_ColorA.rgb, _ColorB.rgb, rings);
            	
				return float4(color, 1);
			}
			
			ENDHLSL
        }
    }
}