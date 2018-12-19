// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/testCartoonShading"
{
    Properties
    {
		_GradualChangeTex("Gradual change",2D) = "white"{}
        _MainTex("Base(RGB)",2D) = "white"{}
		_DiffuseColor("Diffuse Color",Color) = (1,1,1,1)
		_Outline("float",Range(0,1)) = 0.1
		_OutlineColor("Outline Color",Color) = (0,0,0,1)
		_SpecularColor("Specular Color",Color) = (1,1,1,1)
		_Shininess("Shininess",Range(1,500)) = 40
		_SpecularSegment("float",Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

		Pass{
			//描边
			Name "OUTLINE"
			Cull Front
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include"UnityCG.cginc"

			float _Outline;
			fixed4 _OutlineColor;

			struct a2v{
				float4 vertex:POSITION;
				float3 normal:NORMAL;
			};
			struct v2f{
				float4 pos : SV_POSITION;
			};

			v2f vert(a2v v){
				v2f o;

				float4 pos = mul(UNITY_MATRIX_MV,v.vertex);
				float3 normal = mul((float3x3)UNITY_MATRIX_MV,v.normal);
				normal.z = -0.5;
				pos = pos + float4(normalize(normal),1)*_Outline;

				o.pos = mul(UNITY_MATRIX_P,pos);
				return o;
			}
			float4 frag(v2f i) : SV_Target{
				return fixed4(_OutlineColor.rgb,1);
			}
			ENDCG
		}
		Pass{
			Tags{"LightMode" = "ForwardBase"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwbase
			#include"UnityCG.cginc"
			#include"Lighting.cginc"
			#include"AutoLight.cginc"
			#include"UnityShaderVariables.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _GradualChangeTex;
			float4 _GradualChangeTex_ST;
			fixed4 _DiffuseColor;
			fixed4 _SpecularColor;
			float _Shininess;
			fixed _SpecularSegment;

			struct a2v{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;

			};
			struct v2f{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				fixed3 worldNormal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				SHADOW_COORDS(3)
			};

			v2f vert(a2v v){
				v2f o;

				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
				o.worldPos = mul(unity_ObjectToWorld,v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				TRANSFER_SHADOW(o);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = UnityWorldSpaceLightDir(i.worldPos);
				fixed3 worldViewDir =  UnityWorldSpaceViewDir(i.worldPos);
				fixed3 worldHalfView = normalize(worldLightDir + worldViewDir);

				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

				fixed diff = dot(worldNormal , worldLightDir);
				diff = diff*0.5 + 0.5;
				fixed3 objColor = tex2D(_MainTex,i.uv);
				fixed3 changeChangeColor = tex2D(_GradualChangeTex,diff);
				//fixed3 diffuse = (smoothstep(0.0, 0.1, diff)*0.4 + 0.6) * objColor * _DiffuseColor;
				fixed3 diffuse = changeChangeColor.rgb * _DiffuseColor *objColor.rgb;
				fixed spec = max(0,dot(worldNormal,worldHalfView));
				spec = pow(spec , _Shininess);
				fixed w = fwidth(spec);
				if(spec < _SpecularSegment + w){
						spec = lerp(0,1, smoothstep(_SpecularSegment - w,_SpecularSegment + w, spec));
				}
				else{
						spec = 1;
				}

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT;
				fixed3 specular = spec * _SpecularColor * _LightColor0.rgb;
			    diffuse = diffuse * _LightColor0.rgb;

				return fixed4(ambient + specular + diffuse , 1);
			
			
			}
			ENDCG
		}    
    }
    FallBack "Diffuse"
}
