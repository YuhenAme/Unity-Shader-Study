//体积光实现
//Pass0 : 提取高光
//Pass1 : 径向模糊
//Pass2 : 原图与径向模糊后的图融合
Shader "Custom/GodRay"
{
    Properties
    {
       _MainTex("Base(RGB)", 2D) = "white"{}
	   _BlurTex("Blur",2D) = "white"{}

    }
	CGINCLUDE
	#define RADIAL_SAMPLE_COUNT 6
	#include "UnityCG.cginc"

	//用于阈值提取高亮部分
	struct v2f_threshold
	{
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
	};
	//用于径向模糊
	struct v2f_blur
	{
		float4 pos :SV_POSITION;
		float2 uv : TEXCOORD0;
		float2 blurOffset : TEXCOORD1;
	};
	//用于最终融合
	struct v2f_merge
	{
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		float2 uv1 : TEXCOORD1;
	};

	sampler2D _MainTex;
	float4 _MainTex_TexelSize;
	sampler2D _BlurTex;
	float4 _BlurTex_TexelSize;
	float4 _ViewPortLightPos;

	float4 _offsets;
	float4 _ColorThreshold;
	float4 _LightColor;
	//光强度
	float _LightFactor;
	//增强系数
	float _PowFactor;
	//产生体积光的范围
	float _LightRadius;

	//高亮部分提取Shader
	v2f_threshold vert_threshold(appdata_img v){
		v2f_threshold o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord.xy;
		return o;
	}
	fixed4 frag_threshold(v2f_threshold i) : SV_Target{
		fixed4 color = tex2D(_MainTex,i.uv);
		float distFromLight = length(_ViewPortLightPos.xy - i.uv);
		float distanceControl = saturate(_LightRadius - distFromLight);

		//小于阈值，剔除
		float4 thresholdColor = saturate(color - _ColorThreshold)*distanceControl;
		//转化成亮度
		float luminanceColor = Luminance(thresholdColor.rgb);
		//增强
		luminanceColor = pow(luminanceColor,_PowFactor);
		
		return fixed4(luminanceColor,luminanceColor,luminanceColor,1);
	}

	//径向模糊
	v2f_blur vert_blur(appdata_img v){
		v2f_blur o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord.xy;

		//径向模糊采样偏移值*沿光方向上的权重
		o.blurOffset = _offsets * (_ViewPortLightPos.xy - o.uv);
		return o;
	}
	fixed4 frag_blur(v2f_blur i) : SV_Target{
		half4 color = half4(0,0,0,0);
		
		for(int j =0;j<RADIAL_SAMPLE_COUNT;j++){
			color += tex2D(_MainTex,i.uv.xy);
			i.uv.xy += i.blurOffset;
		}
		
		return color/RADIAL_SAMPLE_COUNT;
	}

	//融合
	v2f_merge vert_merge(appdata_img v){
		v2f_merge o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv.xy = v.texcoord.xy;
		o.uv1.xy = o.uv.xy;
		return o;
	
	}
	fixed4 frag_merge(v2f_merge i) : SV_Target{
		fixed4 ori = tex2D(_MainTex,i.uv1);
		fixed4 blur = tex2D(_BlurTex,i.uv);

		//输出 = 原图 + 体积光贴图
		return ori + _LightFactor*blur*_LightColor;
	}
	ENDCG

    SubShader
    {
		//提取高光
        Pass{
			ZTest Off//关闭深度测试
			Cull Off //关闭剔除
			ZWrite Off //关闭深度写入
			Fog{Mode Off}

			CGPROGRAM
			#pragma vertex vert_threshold
			#pragma fragment frag_threshold
			ENDCG

		}

		//径向模糊
		Pass{
			ZTest Off
			Cull Off
			ZWrite Off
			Fog{ Mode Off}

			CGPROGRAM
			#pragma vertex vert_blur
			#pragma fragment frag_blur
			ENDCG
		}

		//融合
		Pass{
			ZTest Off
			Cull Off
			ZWrite Off
			Fog{ Mode Off}
			CGPROGRAM
			#pragma vertex vert_merge
			#pragma fragment frag_merge
			ENDCG
		}


    }
    FallBack "Diffuse"
}
