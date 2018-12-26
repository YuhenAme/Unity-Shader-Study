// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/XRayEffect"
{
    Properties
	{
		_MainTex("Base 2D", 2D) = "white"{}
		_XRayColor("XRay Color",Color) = (1,1,1,1)
	}
 
	SubShader
	{
		Tags{ "Queue" = "Geometry" "RenderType" = "Opaque" }
		
		//渲染X光效果的Pass
		Pass
		{
			Blend SrcAlpha One
			ZWrite Off
			ZTest Greater
 
			CGPROGRAM
			#include "Lighting.cginc"
			uniform float4 _XRayColor;
			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 normal : NORMAL;
				float3 viewDir :TEXCOORD0;
			};
 
			v2f vert (appdata_base v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				//直接在模型空间计算边缘光
				o.normal = v.normal;
				o.viewDir = ObjSpaceViewDir(v.vertex);
				return o;
			}
 
			fixed4 frag(v2f i) : SV_Target
			{
				fixed3 normal = normalize(i.normal);
				fixed3 viewDir = normalize(i.viewDir);
				fixed rim = 1 - saturate(dot(normal , viewDir));
				return rim * _XRayColor;
			}
			#pragma vertex vert
			#pragma fragment frag
			ENDCG
		}
		
		//正常渲染的Pass
		Pass
		{
			ZWrite On
			CGPROGRAM
			#include "Lighting.cginc"
			sampler2D _MainTex;
			float4 _MainTex_ST;
 
			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
 
			v2f vert(appdata_base v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				return o;
			}
 
			fixed4 frag(v2f i) : SV_Target
			{
				return tex2D(_MainTex, i.uv);
			}
 
			#pragma vertex vert
			#pragma fragment frag	
			ENDCG
		}
	}
	
	FallBack "Diffuse"
}
