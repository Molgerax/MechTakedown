using System;
using UnityEngine;


/// <summary>
/// This script changes the given shader property on a material to this transform's current position, also in Edit Mode.
/// This is helpful if you want all of your materials to receive this changing value.
/// If you want to have it be different per renderer, then see <see cref="ShaderSetPositionPerRenderer"/>
/// </summary>
[ExecuteAlways]
public class ShaderSetPositionPerMaterial : MonoBehaviour
{
    [SerializeField] private string propertyName = "_PropertyName";
    [SerializeField] private Material material;


    private void Update()
    {
        SetMaterialProperty();
    }

    private void SetMaterialProperty()
    {
        // return if material is not set   
        if (!material)
            return;
        
        // return if material does not have property with this name
        if (!material.HasVector(propertyName))
            return;
        
        material.SetVector(propertyName, transform.position);
    }

    private void OnDrawGizmos()
    {
        Gizmos.color = Color.red;
        Gizmos.DrawSphere(transform.position, 0.5f);
    }
}

