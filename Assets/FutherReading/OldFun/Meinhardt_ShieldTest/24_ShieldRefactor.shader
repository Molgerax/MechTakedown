Shader "hda/Exam/ShieldRefactor"
{
    Properties
    {
		[Header(Shield Properties)]
		[Space(5)]
        _Color("Shield Main Color", color) = (1, 1, 1, 1)
		_TileAmount("Tiling Amount", float) = 10.0
		_UVTiling("UV Tiling and Offset", Vector) = (1, 1, 0, 0)
		_Activation("Activation Amount", Range(0.0, 1.0)) = 1.0
		_ActivationDir("Activation Direction", Vector) = (0, 0, 0, 0)
		_ActivationSmooth("Activation Smoothing", Range(0.0, 1.0)) = 0.5

		[Header(Tile Properties)]
		[Space(5)]
		_BorderGap("Border Edge Gap", Range(0.0, 1.0)) = 0.1
		_HoleGap("Inner Hole Gap", Range(0.0, 1.0)) = 0.1
		_BaseAlpha("Base Alpha", Range(0.0, 1.0)) = 0.1
		_FresnelAmount("Fresnel Amount", Range(0.0, 1.0)) = 0.1
		
		[Header(Wobble Properties)]
		[Space(5)]
		_WobbleSpeed("Wobble Speed", Range(0.0, 5.0)) = 1.0
		_WobbleSpeedVar("Wobble Speed Variation", Range(0.0, 1.0)) = 0.5
		_WobbleStrength("Wobble Strength", Range(0.0, 1.0)) = 1.0
		_WobbleStrengthVar("Wobble Strength Variation", Range(0.0, 1.0)) = 0.5

		[Header(Impact Wave Properties)]
		[Space(5)]
		_WaveColor("Impact Wave Color", color) = (1, 1, 1, 1)
		_WaveHitStrength("Impact Wave Strength", Range(0.0, 1.0)) = 1.0
		_WaveMaxTime("Wave Max Time", Float) = 1.0
		_WaveDelay("Wave Delay", Range(0.0, 1.0)) = 0.1
		_WaveThickness("Wave Thickness", Range(0.0, 4.0)) = 1.0
		_FadeDelay("Wave Fade Delay", Range(0.0, 1.0)) = 0.2
		[HideInInspector] _WaveCenter("Wave Center", Vector) = (0, 0, 0, 0) //not used, single equivalent of the list
    }


	CGINCLUDE

	// PROPERTY VARIABLES
	#include "UnityCG.cginc"
	uniform float4 _LightColor0; //Not needed, unlit shader
	uniform float4 _Color;
	uniform float _TileAmount;
	uniform float4 _UVTiling;
	uniform float _Activation;
	uniform float4 _ActivationDir;
	uniform float _ActivationSmooth;

	uniform float _BorderGap;
	uniform float _HoleGap;
	uniform float _BaseAlpha;
	uniform float _FresnelAmount;

	uniform float _WobbleSpeed;
	uniform float _WobbleSpeedVar;
	uniform float _WobbleStrength;
	uniform float _WobbleStrengthVar;

	uniform float4 _WaveColor;
	uniform float _WaveHitStrength;
	uniform float _WaveMaxTime;
	uniform float _WaveDelay;
	uniform float4 _WaveCenter;
	uniform float _WaveThickness;
	uniform float _FadeDelay;
	uniform float4 _WaveHitList[32];

	//Constants
	static const float2 unitTri = float2(1, 1.7320508); //(1, sqrt(3)), 30-60-90 triangle side lengths, used for hexagon calculation
	static const float sqrt2 = 1.41421;

	//FUNCTIONS ---------------

	//distance function to get distance to center of hexagon, input is point uv in the coord system with hex center as origin
	//assumes the input will not exceed the internal uv of a hexagon from -0.5 to 0.5 on the x and -sqrt(3)/2 to +sqrt(3)/2 on the y
	float dfHex(float2 uv) {
		float2 p = abs(uv);
		return max(dot(p, unitTri * 0.5), p.x) * 2;
	} // returns 0 in middle, 1 at edge


	//XY = uv coords inside current hex --> uv coords with hex center at (0, 0)
	//ZW = center coords of current hex; doubles as "ID" to differentiate hexes, uniform within a hex
	//essentially: ZW.XY, with ZW being the integer index of the hex and XY being the "fragtional" uv inside this hex
	float4 getHexInfo(float2 uv) //converts object UV to "grid UV"
	{
		//two pairs of centers are calculated, as the center of hexagons are aligned in two overlapping rectangular grids
		//the coord systems are offset by 0.5 on x and 1 on y, and the hexes in each grid are spaced 1 on x and sqrt(3) on y apart
		//divide by the spacing to get integer coordinates
		//then add 0.5 on both x and y to get the centered uv position of the two possible centers of the grid
		float4 hexCenter = floor(float4(uv, uv - float2(0.5, 1)) / unitTri.xyxy) + 0.5;
		//two pairs of "internal UVs", with center of hex as origin, which go from -0.5 to 0.5 on the x and -sqrt(3)/2 to +sqrt(3)/2 on the y
		//subtract the respective center scaled by (1, sqrt(3)) from the uv to get "fractional" uv inside this hex with the center as (0, 0)
		float4 hexOffset = float4(uv - hexCenter.xy * unitTri, uv - (hexCenter.zw + 0.5) * unitTri);

		//basically compare length of both uv offsets at the given uv from their own center
		float hexfactor = step(dot(hexOffset.xy, hexOffset.xy), dot(hexOffset.zw, hexOffset.zw));
		//the closest of the centers is chosen to finally determine the correct grid to align to
		return lerp(float4(hexOffset.zw, hexCenter.zw + 0.5), float4(hexOffset.xy, hexCenter.xy), hexfactor);
	}


	float WhiteNoise(float2 UV) //generic white noise function for variance
	{
		return saturate(frac(sin(dot(UV, float2(12.9898, 78.233))) * 43758.5453));
	}


	
	float sdfLine(float2 p, float2 n, float h)
	{
		return dot(p, n) + h;
	}

	float sdfCircle(float2 p, float r)
	{
		float len = length(p);
		return len - r;
	}

	//Signed Distance of Ring, for Wave Impacts; generalized to use uv of point relative to ring center;
	//-> unused here, but still useful to see and remember; won't be compiled anyway :D
	float sdfRing(float2 uv, float radius, float innerRadius)
	{
		float len = length(uv);
		return max(len - radius, innerRadius - len);
	}

	//Signed Distance of ring based on distance (of a point) from ring origin, outer radius and inner radius of ring
	// --> inside of ring negative distance to closest ring edge, outside of ring positive distance to closest ring edge; ring edge = 0
	float sdfRingLen(float len, float r, float ir)
	{
		return max(len - r, ir - len);
	}

	//0 - 1 linear gradient of ring from inner radius to outer radius; same parameters as sdf
	//len than inner radius -> 0, bigger than outer radius -> 1
	float ringGradient(float len, float r, float ir)
	{
		float l = len - ir;
		return max(0, min(1, (len - ir) / (r - ir))); //linear version of smoothstep Function
	}

	//kinematic equation for the travelled distance of an object with initial velocity v0
	//that gets deccelerated by acc at the time t after the initial throw / impact
	float kinDist(float t, float acc, float v0)
	{
		return t * v0 - 0.5 * acc * t * t;
	}

	//Function for Impact Waves
	float waveStrength(float2 uv, float2 waveCenter, float waveTime, float waveRadius, float maxTime)
	{
		//distance of this pixel from the impact
		float waveDist = distance(waveCenter, uv);

		//time that has passed since the impact, for the wave front; wave end is delayed by wave delay
		float timePassed = _Time.y - waveTime;
		float timePassedEnd = timePassed - maxTime * _WaveDelay;

		//Kinematic equations for decceleration of the wave
		float waveStartSpeed = 2 * waveRadius / maxTime;
		float waveAcc = waveStartSpeed / maxTime;

		//Normalized speed of wave front from 1 - 0; essentially linear timer of 1-timePassed 
		float waveSpeed = saturate((waveStartSpeed - timePassed * waveAcc) / waveStartSpeed);

		//"bools" used to determine if wave front/end have reached max distance, so they dont deccelerate backwards
		float isMax = step(maxTime, timePassed);
		float isMaxEnd = step(maxTime, timePassedEnd);

		//distance of wave front and end from the impact point based  on kinematic equations
		float waveFront = lerp(kinDist(timePassed, waveAcc, waveStartSpeed), waveRadius, isMax);
		float waveEnd = lerp(kinDist(timePassedEnd, waveAcc, waveStartSpeed), waveRadius, isMaxEnd);
		
		//signed distance to the wave ring, _WaveThickness helps to widen the ring to reduce "hex aliasing"
		float waveRing = smoothstep(_WaveThickness, 0, sdfRingLen(waveDist, waveFront, waveEnd));
	
		//0 - 1 falloff, becomes 1 when waveFront stops; because of quadratic formula of distance, this is essentially a smooth stop function
		float distFalloff = saturate((waveFront) / waveRadius);

		//0 - 1 linear Gradient of the ring
		float ringFade = ringGradient(waveDist, waveFront + 0.5 * _WaveThickness, waveEnd - 0.5 * _WaveThickness);

		//ring gradient lerps towards small bumpy wave about when wave front reaches end; put f(x)= x - x*x into a graphing calculator, it's a lil bump
		ringFade = lerp(ringFade, ringFade - ringFade * ringFade, distFalloff * distFalloff);
		
		//fade based on time, the soonest it starts is when the wave front reaches its end
		//it fades to black when the wave end has reached its max distance
		float endFade = smoothstep(maxTime, (1 - _WaveDelay - _FadeDelay) * maxTime, timePassedEnd);

		//multiply "sdf bleed" of ring, ring gradient and time fade together
		return waveRing * ringFade * endFade;
	}

	float hexWaveStrength(float2 hexCen, float2 waveCen, float waveTime, float waveRadius, float maxTime)
	{
		//transforms the hex UVs, so the wave stays in a circular shape
		float2 hexScaled = (hexCen - 0.5) * unitTri;
		float2 waveScaled = (waveCen - 0.5) * unitTri;

		return waveStrength(hexScaled, waveScaled, waveTime, waveRadius, maxTime);
	}

	//Iterates over all 32 hit points in the hit point array, so all hit points have their own wave
	float hexWaveFromList(float2 hexCen)
	{
		float o = 0;
		for(int i = 0; i < 32; i++) 
		{
			float2 waveHexID = getHexInfo((_WaveHitList[i].xy * _UVTiling.xy  + _UVTiling.zw) * _TileAmount).zw;
			o += hexWaveStrength(hexCen, waveHexID, _WaveHitList[i].z, _WaveHitList[i].w, _WaveMaxTime);
		}
		return o;
	}

	//STRUCTS ----------------
	struct vertexIn
	{
		float4 pos : POSITION;
		float4 texcoords : TEXCOORD0;
		float3 normal : NORMAL;
		float4 tangent : TANGENT;
	};

	struct vertexOut
	{
		float4 pos : SV_POSITION;
		float4 tex : TEXCOORD0;
		float3 posWorld : TEXCOORD1;
		float3 normalDir : TEXCOORD2;
	};



	// Shader Functions-----------------------
	vertexOut vert(vertexIn input) //Vertex Shader
	{
		vertexOut output;

		float4x4 modelMatrix = unity_ObjectToWorld;
		float4x4 modelMatrixInverse = unity_WorldToObject;

		output.tex = input.texcoords;
		output.pos = UnityObjectToClipPos(input.pos);
		output.posWorld = mul(modelMatrix, input.pos);
		output.normalDir = normalize(mul(float4(-input.normal, 1), modelMatrixInverse).xyz);

		return output;
	}

	float4 frag(vertexOut input) : COLOR
	{
		//View Direction
		float3 viewDir = normalize(input.posWorld.xyz - _WorldSpaceCameraPos);

		//Fresnel Factor, clamped to 0 - 1
		float fresnel = saturate(1 - dot(viewDir, normalize(input.normalDir)));
		
		//Get info about uv & hex;
		float2 uv = input.tex.xy * _UVTiling.xy + _UVTiling.zw;
		float2 unscaledUV = input.tex.xy * 2 - 1;

		float4 hexInfo = getHexInfo(uv * _TileAmount);
		float distHex = dfHex(hexInfo.xy);

		
		// ACTIVATION -------------- VERY HACKY, DONE IN THE LAST HOURS, I'M SORRY
		

		//FIRST MODE : LINEAR ACTIVATION
		//Get factor of activation, dependent on activation direction
		float activeLen = length(_ActivationDir.xy);
		//normalize vector; in case of 0.0, default to right vector
		float2 activeDir = lerp(normalize(_ActivationDir.xy), float2(1, 0), step(activeLen, 0));

		//distance h from origin to line which intersects corner of a square
		//projects (1,1) onto normal of the line
		float activeDirH = length(dot(abs(activeDir), float2(1, 1)));

		//smoothing from 0-1 ratio to length of shield; fallback in case of 0;
		float activeSmooth = max(_ActivationSmooth * activeDirH * 2, 0.0001);
		
		float linActiveFac = smoothstep(2 * activeDirH * _Activation + (_Activation * activeSmooth), 
									 2 * activeDirH * _Activation -((1-_Activation) * activeSmooth), 
									 sdfLine(hexInfo.zw / _UVTiling.xy / _TileAmount * unitTri * 2 - 1, activeDir, activeDirH));

		
		//SECOND MODE : RADIAL ACTIVATION
		float activeIsRad = 1 - step(abs(_ActivationDir.z), 0);
		//positivie -> from inside to outside, negative -> from outside to inside
		float activeRadDir = (1 - activeIsRad) + normalize(_ActivationDir.z + 0.001);

		float activeRadDist = distance(abs(_ActivationDir.xy), float2(-1, -1));

		float activeRadSmooth = max(0.001, _ActivationSmooth * activeRadDist);

		float activeRad = smoothstep(activeRadDist * _Activation + (_Activation * activeRadSmooth), 
									 activeRadDist * _Activation - ((1-_Activation) * activeRadSmooth),
									 distance(hexInfo.zw / _UVTiling.xy / _TileAmount * unitTri * 2 - 1, _ActivationDir.xy));
		
		float activeRadInwards = smoothstep(activeRadDist * (1-_Activation) - ((_Activation) * activeRadSmooth),
											activeRadDist * (1-_Activation) + (1-_Activation) * activeRadSmooth, 
											distance(hexInfo.zw / _UVTiling.xy / _TileAmount * unitTri * 2 - 1, _ActivationDir.xy));
		activeRad = lerp(activeRadInwards, activeRad, activeRadDir * 0.5 + 0.5);

		float activeFac = saturate(lerp(linActiveFac, activeRad, activeIsRad));
		//activeFac = saturate(linActiveFac);

		//Impact Wave
		//deprecated, used for a single impact point
		//float4 waveHitHex = getHexInfo((_WaveCenter.xy) * _TileAmount);
		//float hexWave = hexWaveStrength(hexInfo.zw, waveHitHex.zw, _WaveCenter.z, _WaveCenter.w, _WaveMaxTime);

		//Impact Waves from the whole list of passed in impact points
		float hexWave = hexWaveFromList(hexInfo.zw);

		//cap the sum of all waves at 1 to avoid issues down the line
		hexWave = saturate(hexWave);

		//Default values, delete
		float3 outCol = lerp(_Color.rgb, _WaveColor.rgb, hexWave);
		float outAlpha = 1;

		//indicates random "strength/energy" of a hex, second value for desyncing the hexes with same variance from pulsing in sync
		float2 hexVariance = float2(WhiteNoise(hexInfo.zw), WhiteNoise(hexInfo.wz)); 

		//wobble of hexes over time
		float hexWobble = (sin(_Time.y * (_WobbleSpeed * (1 + _WobbleSpeedVar * hexVariance.x)) 
							+ 6.28 * hexVariance.y) * 0.5 + 0.5); // needs second pass of noise for offset, so not all in sync
		
		float hexWobbleStrength = hexWobble * (_WobbleStrength * (1 - _WobbleStrengthVar * (1-hexVariance.x))); //adjust wobble strength according to strength properties

		
		//Inner Shape / Gradient of Color
		float hexBorderGap = saturate(_BorderGap - (_BorderGap) * (hexWave * _WaveHitStrength) + (1-_BorderGap) * (1-activeFac));
		float hexHoleGap = saturate(_HoleGap + (1-_HoleGap) * (hexWave * _WaveHitStrength) - (_HoleGap) * (1-activeFac));

		float hexBase = step(distHex, 1 - hexBorderGap);
		float hexGradient = smoothstep(hexHoleGap * (hexHoleGap - hexBorderGap), 1 - hexBorderGap, distHex);

		

		
		outCol = lerp(_Color.rgb, _WaveColor.rgb, hexWave);
		outAlpha = (fresnel + hexWave) * hexBase * hexGradient * ((1 - hexWobbleStrength) + (hexWave * 0.25));

		outAlpha = saturate(activeFac * hexGradient * hexBase *
					(_BaseAlpha + _FresnelAmount * fresnel - hexWobbleStrength + hexWave));
		
		//outAlpha = activeFac;
		return float4(outCol, outAlpha);
	}

	

	ENDCG


    SubShader //multiple subshaders for different GPUs, Unity will choose the most suited one for current application
    {
		Tags {"Queue" = "Transparent"}

        Pass //BASE PASS, FRONT FACE
        {
			Tags {"LightMode" = "ForwardBase"}
			Blend SrcAlpha One
			Cull Off
			Zwrite Off

            CGPROGRAM //here starts the pure Cg shader code
			//------------------------------------------------------------------
			

			// Shader Functions-----------------------
			#pragma vertex vert
			#pragma fragment frag
			
			// Techniques

			//------------------------------------------------------------------
			ENDCG //here ends the pure Cg code
        }
    }
}
