using System.Collections;
using System.Collections.Generic;
using UnityEngine;
/// <summary>
/// 遮挡半透的效果控制器
/// </summary>
public class TransparentControl : MonoBehaviour
{
    //储存信息
    public class TransparentParam
    {
        public Material[] materials = null;
        public Material[] sharedMats = null;
        public float currentFadeTime = 0;
        public bool isTransparent = true;
    }

    public Transform targetObject = null;
    public float height = 3.0f;
    //最终的透明度
    public float destTransparent = 0.2f;
    //渐变的时间
    public float fadeTime = 1.0f;
    //需要半透的层级
    private int transparentLayer;
    //创建字典
    private Dictionary<Renderer, TransparentParam> transparentDic = new Dictionary<Renderer, TransparentParam>();
    //需要清空的列表
    private List<Renderer> clearList = new List<Renderer>();

    private void Start()
    {
        transparentLayer = 1 << LayerMask.NameToLayer("TransparentLayer");
    }
    private void Update()
    {
        if (targetObject == null)
            return;
       
        UpdateTransparentObject();
        UpdateRayCastHit();
        RemoveUnuseTransparent();

    }
    //射线检测是否有需要半透的物体
    public void UpdateRayCastHit()
    {
        RaycastHit[] rayHits = null;
        Vector3 targetPos = targetObject.transform.position + new Vector3(0, height, 0);
        Vector3 viewDir = (targetPos - transform.position).normalized;
        Vector3 oriPos = transform.position;
        float distance = Vector3.Distance(oriPos, targetPos);
        Ray ray = new Ray(oriPos, viewDir);
        rayHits = Physics.RaycastAll(ray, distance, transparentLayer);
        Debug.DrawLine(oriPos, targetPos, Color.blue);

        foreach(var hit in rayHits)
        {
            //Debug.Log(hit.collider.name);
            Renderer[] renderers = hit.collider.GetComponentsInChildren<Renderer>();
            foreach(Renderer r in renderers)
            {
                AddTransparent(r);
            }

        }

    }
    //加入字典之中
    private void AddTransparent(Renderer r)
    {
        TransparentParam param = null;
        //查询是否已经存入字典中
        transparentDic.TryGetValue(r, out param);
        if(param == null)
        {
            param = new TransparentParam();
            transparentDic.Add(r, param);
            //记录之前原本的材质
            param.sharedMats = r.sharedMaterials;
            //将材质换为需要半透的材质
            param.materials = r.materials;
            foreach(var v in param.materials)
            {
                
                v.shader = Shader.Find("Custom/OcclusionTransparent");
            }
        }
        param.isTransparent = true;
    }
    //移除不需要使用半透的材质
    public void RemoveUnuseTransparent()
    {
        clearList.Clear();
        var var = transparentDic.GetEnumerator();
        while (var.MoveNext())
        {
            if(var.Current.Value.isTransparent == false)
            {
                var.Current.Key.materials = var.Current.Value.sharedMats;
                clearList.Add(var.Current.Key);
            }
        }
        foreach (var v in clearList)
            transparentDic.Remove(v);
    }
    //半透
    public void UpdateTransparentObject()
    {
        var var = transparentDic.GetEnumerator();
        while (var.MoveNext())
        {
            TransparentParam param = var.Current.Value;
            param.isTransparent = false;
            foreach(var mat in param.materials)
            {

                Color col = mat.GetColor("_Color");
                param.currentFadeTime += Time.deltaTime;
                float t = param.currentFadeTime / fadeTime;
                col.a = Mathf.Lerp(1, destTransparent, t);
                mat.SetColor("_Color", col);
            }
        }
    }
}
