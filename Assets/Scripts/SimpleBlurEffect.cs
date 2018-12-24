using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[ExecuteInEditMode]
public class SimpleBlurEffect : PostEffectsBase
{
    //模糊半径
    public float BlurRadius = 1.0f;
    //降低分辨率
    public int downSample = 2;
    //迭代次数
    public int iteration = 3;

    //多次模糊效果
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (_Material)
        {

            RenderTexture rt1 = RenderTexture.GetTemporary(source.width >> downSample, source.height >> downSample, 0, source.format);
            RenderTexture rt2 = RenderTexture.GetTemporary(source.width >> downSample, source.height >> downSample, 0, source.format);

            //直接将原图拷贝到降分辨率的RT上
            Graphics.Blit(source, rt1);

            //分辨率降低采样减少
            for (int i =0;i <iteration; i++)
            {
                _Material.SetFloat("_BlurRadius", BlurRadius);
                Graphics.Blit(rt1, rt2, _Material);
                Graphics.Blit(rt2, rt1, _Material);
            }

            Graphics.Blit(rt1, destination);

            RenderTexture.ReleaseTemporary(rt1);
            RenderTexture.ReleaseTemporary(rt2);
        }
    }
}
