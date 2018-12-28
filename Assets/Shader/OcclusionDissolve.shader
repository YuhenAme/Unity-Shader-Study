// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/OcclusionDissolve"
{
    Properties
    {
		_Diffuse("Diffuse", Color) = (1,1,1,1)
		_DissolveColorA("Dissolve Color A", Color) = (0,0,0,0)
		_DissolveColorB("Dissolve Color B", Color) = (1,1,1,1)
		_MainTex("Base 2D", 2D) = "white"{}
		_DissolveMap("DissolveMap", 2D) = "white"{}
		_DissolveThreshold("DissolveThreshold", Range(0,2)) = 0
		_ColorFactorA("ColorFactorA", Range(0,1)) = 0.7
		_ColorFactorB("ColorFactorB", Range(0,1)) = 0.8
		_DissolveDistance("DissolveDistance",Range(0,20)) = 14
		_DissolveDistanceFactor("DissolveDistanceFactor",Range(0,3)) = 3
    }    
	CGINCLUDE
	#include"Lighting.cginc"
	uniform float4 _Diffuse;
	uniform float4 _DissolveColorA;
	uniform float4 _DissolveColorB;
	uniform sampler2D _MainTex;
	uniform float4 _MainTex_ST;
	uniform sampler2D _DissolveMap;
	uniform float _DissolveThreshold;
	uniform float _ColorFactorA;
	uniform float _ColorFactorB;
	uniform float _DissolveDistance;
	uniform float _DissolveDistanceFactor;

	struct v2f{
		float4 pos : SV_POSITION;
		float3 worldNormal : TEXCOORD0;
		float2 uv : TEXCOORD1;
		float4 screenPos : TEXCOORD2;
		float3 viewDir : TEXCOORD3;
	};

	v2f vert(appdata_base v)
	{
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
		o.worldNormal = mul(v.normal,(float3x3)unity_WorldToObject);
		o.screenPos = ComputeGrabScreenPos(o.pos);
		o.viewDir = ObjSpaceViewDir(v.vertex);
		return o;

	}
	fixed4 frag(v2f i) : SV_Target
	{
		float2 screenPos = i.screenPos.xy/i.screenPos.w;
		//计算距离中心点的距离
		float2 dir = float2(0.5f,0.5f) - screenPos;
		float distance = 0.5-sqrt(dir.x*dir.x + dir.y*dir.y);
		float viewDistance = max(0,(_DissolveDistance-length(i.viewDir))/_DissolveDistance)*_DissolveDistanceFactor;

		//距离中心点近的才溶解
		float dissolveFactor = distance * viewDistance *_DissolveThreshold;
		fixed4 dissolveValue = tex2D(_DissolveMap,i.uv);
		if(dissolveValue.r<dissolveFactor)
		{
			discard;
		}

		fixed3 worldNormal = normalize(i.worldNormal);
		fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
		fixed3 lambert = saturate(dot(worldNormal,worldLightDir));
		fixed3 albedo = lambert*_Diffuse.xyz*_LightColor0.xyz + UNITY_LIGHTMODEL_AMBIENT.xyz;
		fixed3 color = tex2D(_MainTex,i.uv).rgb*albedo;

		float lerpValue = dissolveFactor/dissolveValue.r;
		
		//if(lerpValue>_ColorFactorA)
		//{
		//	if(lerpValue>_ColorFactorB)
		//		return _DissolveColorB;
		//	return _DissolveColorA;
		//}
		//return fixed4(color,1);

		//用计算代替分支语句
		fixed stepB = step(_ColorFactorB,lerpValue);
		fixed stepA = step(_ColorFactorA,lerpValue);

	    color = (stepB*_DissolveColorB + (1-stepB)*_DissolveColorA)*stepA + (1-stepA)*color;
		return fixed4(color,1);
	}
	ENDCG

    SubShader
    {
       Tags{"RenderType" = "Opaque"}
	   Pass
	   {
			CGPROGRAM
			#pragma vertex vert 
			#pragma fragment frag 
			ENDCG
	   }
    }
    FallBack "Diffuse"
}
