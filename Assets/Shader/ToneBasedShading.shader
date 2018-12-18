// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/ToneBasedShading"
{
    Properties
    {
        _Color("Diffuse Color",Color) = (1,1,1,1)
		_MainTex("Base(RGB)",2D) = "white"{}
		_Outline("Outline",Range(0,1)) = 0.1
		_OutlineColor("Outline Color",Color) = (0,0,0,1)
		_Specular("Specular",Color) = (1,1,1,1)
		_Gloss("Gloss",Range(1.0,500)) = 20
		_Blue("Bule",Range(0,1)) = 0.5
		_Alpha("Alpha",Range(0,1)) = 0.5
		_Yellow("Yellow",Range(0,1)) = 0.5
		_Beta("Beta",Range(0,1)) = 0.5
	}
		SubShader
		{
			Tags{"RenderType" = "Opaque"}
			LOD 200
			UsePass"Custom/Celshading/OUTLINE"

			Pass{
			Tags{ "LightMode" = "ForwardBase" }

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_fwdbase

			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Specular;
			float _Gloss;
			fixed _Blue;
			fixed _Alpha;
			fixed _Yellow;
			fixed _Beta;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
				float4 tangent : TANGENT;
			};

			struct v2f {
				float4 pos : POSITION;
				float2 uv : TEXCOORD0;
				float3 worldNormal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				SHADOW_COORDS(3)
			};

			v2f vert(a2v v) {
				v2f o;

				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

				TRANSFER_SHADOW(o);

				return o;
			}

			float4 frag(v2f i) : COLOR{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = UnityWorldSpaceLightDir(i.worldPos);
				fixed3 worldViewDir = UnityWorldSpaceViewDir(i.worldPos);
				fixed3 worldHalfDir = normalize(worldViewDir + worldLightDir);

				fixed4 c = tex2D(_MainTex, i.uv);

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

				fixed diff = dot(worldNormal, worldLightDir);
				diff = (diff * 0.5 + 0.5) * atten;

				//模型自身的颜色值
				fixed3 k_d = c.rgb * _Color.rgb;

				fixed3 k_blue = fixed3(0, 0, _Blue);
				fixed3 k_yellow = fixed3(_Yellow, _Yellow, 0);
				//混合后的冷色调
				fixed3 k_cool = k_blue + _Alpha * k_d;
				//混合后的暖色调
				fixed3 k_warm = k_yellow + _Beta * k_d;
				//计算漫反射,即是法线与光照方向的点集作为系数，混合冷色调与暖色调
				fixed3 diffuse = _LightColor0.rgb * (diff * k_warm + (1 - diff) * k_cool);

				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, worldHalfDir)), _Gloss);

				return fixed4(ambient + diffuse + specular, 1.0);
			}

				ENDCG
			}
		


		}
    FallBack "Diffuse"
}
