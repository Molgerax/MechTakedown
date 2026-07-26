Shader "Tutorial/1_Minimal"
{
    // Here we put properties that can be adjusted per material, like colors, textures, sliders, etc.
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
    }
    
    // SubShaders are usually done for different target hardware, but we just need one per shader 
    SubShader
    {
        // Tags allow us to tell the Render Pipeline how and when to execute this shader.
        // Tags can be defined per SubShader (like here), or per pass, which can be used for advanced techniques (not covered here)
        // "RenderType" is either "Opaque" or "Transparent"
        // "Queue" tells us when to render this shader. "Geometry" is for all opaque shaders, after that is "AlphaTest", "Transparent" and "Overlay"
        Tags 
        { 
            "RenderPipeline" = "UniversalPipeline" 
            "RenderType" = "Opaque" 
            "Queue" = "Geometry" 
        }

        // Shaders consist of multiple passes. URP natively supports only one specific pass by default (without extra work), 
        // so we also just need one pass.
        Pass
        {
            // Here could go another "Tags" bracket, and also some other stuff we will get to later.
            
            
            // This starts the actual HLSL code. From here on out, we need to write actual HLSL code, and not Unity's
            // esoteric ShaderLab wrapper. We will need to close this with a "ENDHLSL" statement later
            HLSLPROGRAM

            // Here we declare which functions should be our vertex and fragment shader functions.
            #pragma vertex vert
            #pragma fragment frag

            // Your best friend: Include files. They hold many useful functions for everything one might need.
            // Core.hlsl should be included in every shader, others might need to be added depening on the features
            // you are using, like lighting.
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            
            // structs can be used to transfer mesh data between the steps of the pipeline.
            // In this example, "Attributes" is data we get from the mesh per vertex, 
            // and "Varyings" is the vertex data we send to the fragment shader.
            
            // The stuff after the : are called SEMANTICS, and they are the place where we get the data from and 
            // where we store it again in-between shader stages.
            struct Attributes
            {
                // POSITION is a float4 of the vertex position in object space
                float4 positionOS : POSITION;
            };

            // The semantics used to store vertex data for the fragment shader are a bit different:
            // The vertex position is stored in SV_POSITION. We will get to the rest in time.
            struct Varyings
            {
                // HCS stands from Homogenous Clip Space, it is the space of the screen.
                float4 positionHCS : SV_POSITION;
            };

            
            // CBUFFER stands for Constant Buffer, it is a buffer where the different properties we declared above are stored.
            // (except for textures).
            
            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
            CBUFFER_END


            // The vertex shader. It should always follow the structure that it returns the "Varyings" struct used for 
            // sending data to the fragment shader, and that it takes the "Attributes" struct as an input parameter
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                
                // Using the pre-built function from the "Core.hlsl" include file, we can easily convert the vertex position
                // from object space to HClip space (HCS for short)
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                
                return OUT;
            }

            // The fragment shader takes in the Varyings from the vertex shader and returns a color for the screen, so it outputs a float4 value.
            // It needs to be appended by the semantic ": SV_Target", so the pipeline knows it needs to write this color
            // to the render target, i.e. the screen.
            
            float4 frag(Varyings IN) : SV_Target
            {
                // We are getting the color from the "_Color" property defined above and then again defined in the CBuffer.
                float4 color = _Color;
                
                // The alpha channel, i.e. the fourth channel, is unused for now, we can just set it to 1.
                return float4(color.rgb, 1);
            }
            ENDHLSL
        }
    }
}
