using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShieldManager : MonoBehaviour
{
    enum ShieldType
    {
        Linear,
        RadialOutwards,
        RadialInwards
    }

    [SerializeField] ShieldType activationMode = ShieldType.Linear;
    [SerializeField] Vector2 shieldOrigin = new Vector2(1, 1);
    [SerializeField] float activationTime = 1f;

    private Renderer _renderer;
    private MaterialPropertyBlock _propBlock;


    private int _waveCenterID;
    private int _waveHitListID;
    
    private int _activationDirID;
    private int _activationAmountID;

    private IEnumerator activateProcess;
    private bool isActive;
    private bool isActivating = false;

    private const int _maxHits = 32;
    private int _currentHitIndex = 0;
    private Vector4[] _hitList;


    private void Awake()
    {
        _propBlock = new MaterialPropertyBlock();
        _renderer = GetComponent<Renderer>();

        _waveCenterID = Shader.PropertyToID("_WaveCenter");
        _waveHitListID = Shader.PropertyToID("_WaveHitList");

        _activationDirID = Shader.PropertyToID("_ActivationDir");
        _activationAmountID = Shader.PropertyToID("_Activation");

        _hitList = new Vector4[_maxHits];
    }


    private void Update()
    {
        BootOnButton();
    }



    [ContextMenu("Boot Up")]
    public void BootShieldUp()
    {
        Activate(activationTime, false);
        isActive = true;
    }

    [ContextMenu("Shut Down")]
    public void ShutShieldDown()
    {
        Activate(activationTime, true);
        isActive = false;
    }



    void BootOnButton()
    {
        if(Input.GetKeyDown(KeyCode.Space) && !isActivating)
        {
            Activate(activationTime, isActive);
        }
    }





    float ShieldToFloat(ShieldType shieldType)
    {
        float o = (float) shieldType;
        o = o == 2 ? -1 : o;
        return o;
    }

    public void Activate(float time, bool deactivate) 
    {
        if (activationMode == 0 && shieldOrigin.x + shieldOrigin.y == 0) shieldOrigin.x = 1;


        _renderer.GetPropertyBlock(_propBlock);
        _propBlock.SetVector(_activationDirID, new Vector4(shieldOrigin.x, shieldOrigin.y, ShieldToFloat(activationMode), 0));
        _renderer.SetPropertyBlock(_propBlock);

        if(activateProcess != null) StopCoroutine(activateProcess);
        activateProcess = ActivationProcess(time, deactivate);
        StartCoroutine(activateProcess);
    }

    IEnumerator ActivationProcess(float time, bool deactivate) 
    {
        isActivating = true;
        float t = 0;
        while(t < time)
        {
            t += Time.deltaTime;
            UpdateShieldActivation(deactivate ? 1 - (t/time) : t / time);
            yield return null;
        }
        UpdateShieldActivation(deactivate ? 0 : 1);
        isActive = !deactivate;
        isActivating = false;
    }

    void UpdateShieldActivation(float t)
    {
        _renderer.GetPropertyBlock(_propBlock);
        _propBlock.SetFloat(_activationAmountID, t);
        _renderer.SetPropertyBlock(_propBlock);
    }

    public void SetHitPoint(Vector2 hitUV, float speed)   //Just for one vector
    {
        _renderer.GetPropertyBlock(_propBlock);
        _propBlock.SetVector(_waveCenterID, new Vector4(hitUV.x, hitUV.y, Time.time, speed));
        _renderer.SetPropertyBlock(_propBlock);
    }


    public void AddHitPointToList(Vector2 hitUV, float speed)
    {
        Vector4 newHit = new Vector4(hitUV.x, hitUV.y, Time.time, speed);

        _hitList[_currentHitIndex++] = newHit;
        if (_currentHitIndex == _maxHits) _currentHitIndex = 0;

        Debug.Log("Hit Point: " + newHit + ", Index: " + _currentHitIndex);

        _renderer.GetPropertyBlock(_propBlock);

        _propBlock.SetVectorArray(_waveHitListID, _hitList);

        _renderer.SetPropertyBlock(_propBlock);
    }

}
