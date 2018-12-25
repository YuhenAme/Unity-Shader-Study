// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/DissolveEffect"
{
    Properties
    {
        _Diffuse("Diffuse",Color) = (1,1,1,1)
		_DissolveColor("Dissolve Color",Color) = (0,0,0,0)
		_DissolveEdgeColor("Dissolve Edge Color",Color) = (1,1,1,1)
		_MainTex("Base(RGB)",2D) = "white"{}
		_DissolveMap("DissolveMap",2D) = "white"{}
		_DissolveThreshold("DissolveThreshold",Range(0,1)) = 0
		_ColorFactor("ColorFactor",Range(0,1)) = 0.7
		_DissolveEdge("DissolveEdge",Range(0,1)) = 0.8
		_FlyThreshold("FlyThreshold",Range(0,1)) = 0.8
		_FlyFactor("FlyFactor",Range(0,1)) = 0.1
    }
	CGINCLUDE
	#include "Lighting.cginc"
	uniform float4 _Diffuse;
	uniform float4 _DissolveColor;
	uniform float4 _DissolveEdgeColor;
	uniform sampler2D _MainTex;
	uniform float4 _MainTex_ST;
	uniform sampler2D _DissolveMap;
	uniform float _DissolveThreshold;
	uniform float _ColorFactor;
	uniform float _DissolveEdge;
	uniform float _FlyThreshold;
	uniform float _FlyFactor;


	struct v2f
	{
		float4 pos : SV_POSITION;
		float3 worldNormal : TEXCOORD0;
		float2 uv : TEXCOORD1;
	};

	v2f vert(appdata_base v )
	{
		v2f o;
		v.vertex.xyz += v.normal * saturate(_DissolveThreshold - _FlyThreshold)*_FlyFactor;
		//v.vertex.y  = float3(0,1,0) * saturate(_DissolveThreshold - _FlyThreshold)*_FlyFactor;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
		o.worldNormal = mul(v.normal,(float3x3)unity_WorldToObject);

		return o;
	}
	fixed4 frag(v2f i) : SV_Target
	{
		//采样噪声贴图
		fixed4 dissloveValue = tex2D(_DissolveMap,i.uv);
		if(dissloveValue.r<_DissolveThreshold)
		{
				discard;
		}
		//计算光照
		fixed3 worldNormal = normalize(i.worldNormal);
		fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
		fixed3 lambert = saturate(dot(worldNormal,worldLightDir));
		lambert = 0.5*lambert + 0.5;
		fixed3 albedo = lambert * _Diffuse.xyz * _LightColor0.xyz + UNITY_LIGHTMODEL_AMBIENT.xyz;
		fixed3 color = tex2D(_MainTex,i.uv).rgb * albedo;
		
		//------------------------
		//当前百分比
		float percentage = _DissolveThreshold / dissloveValue.r;
		//如果当前百分比 - 颜色权重 - 边缘颜色
		float lerpEdge = sign(percentage - _ColorFactor - _DissolveEdge);
		//插值处理
		fixed3 edgeColor = lerp(_DissolveEdgeColor.rgb,_DissolveColor.rgb,saturate(lerpEdge));
		//最终输出颜色的lerp
		float lerpOut = sign(percentage - _ColorFactor);
		fixed3 colorOut = lerp(color, edgeColor,saturate(lerpOut));
		return fixed4(colorOut,1);
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
