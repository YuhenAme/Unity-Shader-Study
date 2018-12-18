// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Celshading" {
	Properties {
		_MainTex("Main Tex",2D) = "white"{}
		_Outline("Outline",Range(0,1)) = 0.1
		_OutlineColor("Outline Color",Color) = (0,0,0,1)
		_DiffuseColor("Diffuse Color",Color) = (1,1,1,1)
		_SpecularColor("Specular Color",Color) = (1,1,1,1)
		_Shininess("Shininess",Range(1,500)) = 40
		_DiffuseSegment("Diffuse Segment",Vector) = (0.1,0.3,0.6,1.0)
		_SpecularSegment("Specular Segment",Range(0,1)) = 0.5


	}
		SubShader{
				Tags {"RenderType" = "Opaque"}
				LOD 200

		Pass{
			//描边
			NAME "OUTLINE"
			Cull Front
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			float _Outline;
			fixed4 _OutlineColor;
			struct a2v {
				float4 vertex:POSITION;
				float3 normal:NORMAL;

			};
			struct v2f {
				float4 pos:SV_POSITION;
			};

			v2f vert(a2v v) {
				v2f o;
				//将顶点以及法线转移到视角空间
				float4 pos = mul(UNITY_MATRIX_MV, v.vertex);
				float3 normal = mul((float3x3)UNITY_MATRIX_MV, v.normal);
				normal.z = -0.5;
				//模型按照顶点方向外扩一定距离
				pos = pos + float4(normalize(normal), 0)*_Outline;
				//转移到裁剪空间
				o.pos = mul(UNITY_MATRIX_P, pos);
				return o;
			}
			float4 frag(v2f i) : SV_Target{
				return float4(_OutlineColor.rgb,1);
			}
				ENDCG
		}
		Pass{
				Tags {"LightMode" = "ForwardBase"}
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile_fwbase
				#include"UnityCG.cginc"
				#include"Lighting.cginc"
				#include"AutoLight.cginc"
				#include"UnityShaderVariables.cginc"

				fixed4 _DiffuseColor;
				fixed4 _SpecularColor;
				sampler2D _MainTex;
				float4 _MainTex_ST;
				float _Shininess;
				fixed4 _DiffuseSegment;
				fixed _SpecularSegment;

				struct a2v {
					float4 vertex : POSITION;
					float3 normal : NORMAL;
					float4 texcoord : TEXCOORD0;

				};
				struct v2f {
					float4 pos : SV_POSITION;
					float2 uv : TEXCOORD0;
					fixed3 worldNormal : TEXCOORD1;
					float3 worldPos : TEXCOORD2;
					SHADOW_COORDS(3)
				};

				v2f vert(a2v v) {
					v2f o;

					o.pos = UnityObjectToClipPos(v.vertex);
					o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
					o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
					o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

					TRANSFER_SHADOW(o);
					return o;
				}
				float4 frag(v2f i) : SV_Target{
					fixed3 worldNormal = normalize(i.worldNormal);
					fixed3 worldLightDir = UnityWorldSpaceLightDir(i.worldPos);
					fixed3 worldViewDir = UnityWorldSpaceViewDir(i.worldPos);
					fixed3 worldHalfDir = normalize(worldLightDir + worldViewDir);

					UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

					fixed diff = dot(worldNormal, worldLightDir);
					diff = 0.5*diff + 0.5;
					fixed spec = max(0, dot(worldNormal, worldHalfDir));
					spec = pow(spec, _Shininess);

					//对漫反射进行的处理
					//根据diff的值，将光照映射到不同的区域值，而不是再沿着法线递减
					//fwidth(x)返回x这个值在当前像素和它的下一个相邻像素之间的差值
					fixed w = fwidth(diff) * 2.0;
					if (diff < _DiffuseSegment.x + w) {
						diff = lerp(_DiffuseSegment.x, _DiffuseSegment.y, smoothstep(_DiffuseSegment.x - w, _DiffuseSegment.x + w, diff));
					}
					else if (diff < _DiffuseSegment.y + w) {
						diff = lerp(_DiffuseSegment.y, _DiffuseSegment.z, smoothstep(_DiffuseSegment.y - w, _DiffuseSegment.y + w, diff));
					}
					else if (diff < _DiffuseSegment.z + w) {
						diff = lerp(_DiffuseSegment.z, _DiffuseSegment.w, smoothstep(_DiffuseSegment.z - w, _DiffuseSegment.z + w, diff));
					}
					else {
						diff = _DiffuseSegment.w;
					}
					//对高光的处理
					w = fwidth(spec);
					if (spec < _SpecularSegment + w) {
						spec = lerp(0, 1, smoothstep(_SpecularSegment - w, _SpecularSegment + w, spec));
					}
					else {
						spec = 1;
					}

					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT;

					fixed3 texColor = tex2D(_MainTex, i.uv).rgb;
					fixed3 diffuse = diff * _LightColor0.rgb*_DiffuseColor.rgb*texColor;
					fixed3 specular = spec * _LightColor0.rgb*_SpecularColor.rgb;

					return fixed4(ambient + (diffuse + specular)*atten, 1);
				}
				ENDCG
		}

	}
	FallBack "Diffuse"
}
