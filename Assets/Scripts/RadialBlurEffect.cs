using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[ExecuteInEditMode]
public class RadialBlurEffect : PostEffectsBase
{
    public float BlurFactor = 1.0f;
    public Vector4 BlurCenter = new Vector4(0.5f, 0.5f, 0, 0);

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (_Material)
        {
            _Material.SetFloat("_BlurFactor", BlurFactor);
            _Material.SetVector("_BlurCenter", BlurCenter);
            Graphics.Blit(source, destination, _Material);
        }
    }

}
