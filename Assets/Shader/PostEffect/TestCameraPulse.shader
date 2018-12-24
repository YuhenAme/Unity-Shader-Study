Shader "Custom/TestCameraPulse"
{
    Properties
    {
		_MainTex("Base(RGB)",2D) = "white"{}
        
    }
	CGINCLUDE
	#include"UnityCG.cginc"
	uniform sampler2D _MainTex;
	uniform float _timeFactor;
	uniform float _pulseFactor;
	uniform float _waveWitdh;
	uniform float _distance;
	uniform float _curDistance;
	uniform float _controllOffset;
	
	fixed4 frag(v2f_img i) : SV_Target
	{
		
		float dis = abs(i.uv.y);
		float sinFactor = sin(_Time.y * _timeFactor) * _pulseFactor*0.01;
		//float2 uv = float2(i.uv.x,i.uv.y + 10.0f);
		float distance = clamp(_waveWitdh-abs(_curDistance-dis),0,1);
		float OffsetX = sinFactor*distance*_controllOffset;
		i.uv.x += OffsetX;

		return tex2D(_MainTex,i.uv );
	}

	ENDCG
    SubShader 
	{
		Pass
		{
			ZTest Always
			Cull Off
			ZWrite Off
			Fog { Mode off }
 
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest 
			ENDCG
		}
	}
	Fallback off
}
