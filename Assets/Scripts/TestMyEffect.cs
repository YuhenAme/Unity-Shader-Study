using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TestMyEffect : PostEffectsBase
{
    public float timeFactor = 30.0f;
    public float pulseFactor = 1.0f;
    public float waveWitdh = 0.1f;
    public float waveSpeed = 0.3f;
    public float controllOffset = 1.0f;

    private float waveStartTime;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        float curDistance = (Time.time - waveStartTime) * waveSpeed;
        _Material.SetFloat("_controllOffset", controllOffset);
        _Material.SetFloat("_curDistance", curDistance);
        _Material.SetFloat("_waveWitdh", waveWitdh);
        _Material.SetFloat("_timeFactor", timeFactor);
        _Material.SetFloat("_pulseFactor", pulseFactor);
        Graphics.Blit(source,destination, _Material);
    }

    private void OnEnable()
    {
        waveStartTime = Time.time;
    }
}
