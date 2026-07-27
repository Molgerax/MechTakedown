using System;
using UnityEngine;


/// <summary>
/// This script changes the given shader property on a single renderer to this transform's current position, also in Edit Mode.
/// This is helpful if you want different renderers to receive different changing values, without using a new material per renderer.
/// If you want to have it global for all renderers that use the same material, then see <see cref="ShaderSetPositionPerMaterial"/>
/// </summary>
[ExecuteAlways]
public class ShaderSetPositionPerRenderer : MonoBehaviour
{
    [SerializeField] private string propertyName = "_PropertyName";
    [SerializeField] private Renderer targetRenderer;

    private MaterialPropertyBlock _propertyBlock;

    private void Update()
    {
        SetMaterialProperty();
    }

    private void SetMaterialProperty()
    {
        // return if renderer is not set   
        if (!targetRenderer)
            return;

        // Create a material property block if it is null
        if (_propertyBlock == null)
            _propertyBlock = new();
        
        // First get the property block from the renderer. This copies all properties on this renderer into the block
        targetRenderer.GetPropertyBlock(_propertyBlock);

        // Change the properties as we see fit
        _propertyBlock.SetVector(propertyName, transform.position);

        // Apply the properties again to the renderer
        targetRenderer.SetPropertyBlock(_propertyBlock);
    }

    private void OnDrawGizmos()
    {
        Gizmos.color = Color.blue;
        Gizmos.DrawSphere(transform.position, 0.5f);
        
        if (targetRenderer)
            Gizmos.DrawLine(transform.position, targetRenderer.transform.position);
    }
}

