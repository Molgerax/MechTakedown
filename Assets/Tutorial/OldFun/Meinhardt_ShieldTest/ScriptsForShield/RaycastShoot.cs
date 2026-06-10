using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class RaycastShoot : MonoBehaviour
{
    public Camera cam;
    [SerializeField] LayerMask shieldLayer;
    [SerializeField] float waveRadius = 1;

    
    
    // Start is called before the first frame update
    void Start()
    {
        if(!cam) cam = GetComponent<Camera>();
    }

    // Update is called once per frame
    void Update()
    {
        if (!Input.GetMouseButtonDown(0)) return;

        RaycastHit hit;
        if (Physics.Raycast(cam.ScreenPointToRay(Input.mousePosition), out hit, 100f, shieldLayer))
        {

            Renderer rend = hit.transform.GetComponent<Renderer>();
            MeshCollider meshCollider = hit.collider as MeshCollider;


            Vector2 hitUV = hit.textureCoord;

            //Debug.Log(hitUV);

            ShieldManager shield = hit.transform.GetComponent<ShieldManager>();

            //if(!hitToList) 
            shield.SetHitPoint(hitUV, waveRadius);
            //else 
            shield.AddHitPointToList(hitUV, waveRadius);

            //StartWaveCenter(hitUV, rend.sharedMaterial);
        }
    }

    void StartWaveCenter(Vector2 hitUVs, Material material)
    {
        material.SetVector("_WaveCenter", new Vector4(hitUVs.x, hitUVs.y, Time.time, waveRadius));
    }
}
