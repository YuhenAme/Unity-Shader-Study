Shader "Hidden/RadialBlurEffect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
	CGINCLUDE
	#include"UnityCG.cginc"
	#define SAMPLE_COUNT 6
	uniform sampler2D _MainTex;
	uniform float _BlurFactor;
	uniform float4 _BlurCenter;

	fixed4 frag(v2f_img i):SV_Target
	{
		//模糊方向
		float2 dir = _BlurCenter.xy - i.uv;
		float4 outColor = 0;
		for(int j =0;j<SAMPLE_COUNT;++j)
		{
			float2 uv = i.uv + dir*_BlurFactor*j;
			outColor += tex2D(_MainTex,uv);
		}
		outColor *= 0.167;
		return outColor;
	}
	ENDCG


    SubShader
    {
        Pass
		{
			ZTest Off
			Cull Off
			ZWrite Off
			Fog{Mode Off}

			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag
			ENDCG


		}
    }
}
