// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/SimpleBlurEffect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
	CGINCLUDE
	#include"UnityCG.cginc"

	struct v2f_blur
	{
		float4 pos :SV_POSITION;
		float2 uv : TEXCOORD0;
		float2 uv1 :TEXCOORD1;
		float2 uv2 :TEXCOORD2;
		float2 uv3 :TEXCOORD3;
		float2 uv4 :TEXCOORD4;
	};
	sampler2D _MainTex;
	//可以获得纹理的相关大小
	float4 _MainTex_TexelSize;
	//模糊半径
	uniform float _BlurRadius;

	v2f_blur vert_blur(appdata_img v)
	{
		v2f_blur o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord.xy;
		//计算uv上下左右四个点对于模糊半径下的uv坐标
		o.uv1 = v.texcoord.xy + _BlurRadius*_MainTex_TexelSize* float2(1,1);
		o.uv2 = v.texcoord.xy + _BlurRadius*_MainTex_TexelSize* float2(-1,1);
		o.uv3 = v.texcoord.xy + _BlurRadius*_MainTex_TexelSize* float2(-1,-1);
		o.uv4 = v.texcoord.xy + _BlurRadius*_MainTex_TexelSize* float2(1,-1);
		return o;
	}

	fixed4 frag_blur(v2f_blur i) : SV_Target
	{
		fixed4 color = fixed4(0,0,0,0);

		color += tex2D(_MainTex,i.uv);
		color += tex2D(_MainTex,i.uv1);
		color += tex2D(_MainTex,i.uv2);
		color += tex2D(_MainTex,i.uv3);
		color += tex2D(_MainTex,i.uv4);
		//平均
		return color*0.2;
	}
	ENDCG

    SubShader
    {
        Pass{
				ZTest Always
				Cull Off
				ZWrite Off
				Fog{ Mode Off}
				CGPROGRAM
				#pragma vertex vert_blur
				#pragma fragment frag_blur
				ENDCG
		}
    }
}
