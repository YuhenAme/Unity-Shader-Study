Shader "Custom/EasyPBR"
{
    Properties
    {
		_Albedo("Color",2D) = "white"{}
		_MetalnessMap("MetallicColor",2D) = "white"{}
		_NormalMap("Normal",2D) = "white"{}
		_BumpScale("Bump Scale",Range(0.0,10)) = 0
		_Metalness("Metallic",Range(0.0,1)) = 0.5
		_Roughness("Rough",Range(0.0,1)) = 1
		_Specular("Specular Color",Color) = (1,1,1,1)
    }
    SubShader
    {
        LOD 100
		Pass{
			Tags {
				"RenderType" = "Opaque"
				"LightMode" = "ForwardBase"
			}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct a2v {
				fixed4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				fixed3 normal : NORMAL;
				float4 tangent : TANGENT;
			};
			struct v2f {
				fixed4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				//切线空间转移到世界空间矩阵
				float4 TtoW0 : TEXCOORD1;
				float4 TtoW1 : TEXCOORD2;
				float4 TtoW2 : TEXCOORD3;
			};

			sampler2D _Albedo;
			sampler2D _Normal;
			sampler2D _MetalnessMap;
			fixed _BumpScale;
			fixed _Metalness;
			fixed _Roughness;
			fixed _key;
			fixed3 _Specular;
			samplerCUBE _Cubemap;
			fixed4 _Albedo_ST;
			uniform fixed4 _LightColor0;

			v2f vert(a2v v) {
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _Albedo);
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed3 worldBinormal = cross(worldNormal, worldTangent)*v.tangent.w;

				//切线到世界坐标的转换矩阵
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
				return o;
			}
			//菲涅尔函数
			fixed3 fresnelSchlick(float cosTheta, fixed3 F0) {
				return F0 + (1.0 - F0)*pow(1.0 - cosTheta, 5.0);
			}
			//微表面分布函数
			fixed DistributionGGX(fixed3 N, fixed3 H, fixed roughness) {
				fixed a = roughness * roughness;
				fixed a2 = a * a;
				fixed NdotH = max(dot(N, H), 0.0);
				fixed NdotH2 = NdotH * NdotH;

				fixed nom = a2;
				fixed denom = (NdotH2*(a2 - 1.0) + 1.0);
				denom = UNITY_PI * denom * denom;
				return nom / denom;
			}
			//几何衰减
			fixed GeometrySchlickGGX(fixed NdotV, fixed roughness) {
				fixed r = (roughness + 1.0);
				fixed k = (r*r) / 8.0;

				fixed nom = NdotV;
				fixed denom = NdotV * (1.0 - k) + k;
				return nom / denom;
			}
			fixed GeometrySmith(fixed3 N, fixed3 V, fixed3 L, fixed roughness) {
				fixed NdotV = max(dot(N, V), 0.0);
				fixed NdotL = max(dot(N, L), 0.0);
				fixed ggx2 = GeometrySchlickGGX(NdotV, roughness);
				fixed ggx1 = GeometrySchlickGGX(NdotL, roughness);
				return ggx1 * ggx2;
			}

			fixed4 frag(v2f i) : SV_Target{
				float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
				fixed4 albedo = tex2D(_Albedo, i.uv);
				fixed4 Metalness = tex2D(_MetalnessMap, i.uv);
				//切线空间下的法线
				fixed3 normal = UnpackNormal(tex2D(_Normal, i.uv));
				//计算出z分量的值，参考入门精要
				normal.xy *= _BumpScale;
				normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
				//法线转移到世界空间
				normal = normalize(half3(dot(i.TtoW0.xyz, normal), dot(i.TtoW1.xyz, normal), dot(i.TtoW2.xyz, normal)));
				normal = normalize(float3(i.TtoW0.z, i.TtoW1.z, i.TtoW2.z));

				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				fixed3 halfDir = normalize(viewDir + lightDir);

				//反射方向
				fixed3 reflectDir = normalize(reflect(-viewDir, normal));
				//处理反射
				fixed3 reflection = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectDir, _Roughness * 5).rgb;
			
				//根据金属度来区别菲涅尔系数
				fixed3 F0 = lerp(fixed3(0.04, 0.04, 0.04), albedo, _Metalness);
				fixed3 fresnel = fresnelSchlick(max(dot(normal, viewDir), 0.0), F0);
				//微表面分布项
				fixed D = DistributionGGX(normal, halfDir, _Roughness);
				//几何遮蔽项
				fixed G = GeometrySmith(normal, viewDir, lightDir, _Roughness);

				//+0.001是为了防止除零错误
				fixed3 specular = D * G*fresnel / (4.0*max(dot(normal, viewDir), 0.0) * max(dot(normal, lightDir), 0.0) + 0.01);
				
				//用菲涅尔项做高光与反射的插值
				specular += lerp(specular, reflection, fresnel);
				//diffuse项的系数
				fixed diff = (1.0 - fresnel) * (1.0 - _Metalness);

				//ShadeSH9是一个球谐函数(没搞懂)
				//球谐光照实际上是将周围环境光采样成几个系数，用这几个系数对光照还原
				//计算量与光源的数量无光，用于模拟实时光照
				float4 sh = float4(ShadeSH9(half4(normal, 1)), 1.0);

				fixed3 Final = (diff * albedo + specular)* _LightColor0.xyz * (max(dot(normal, lightDir), 0.0) + 0.0);
				//最终颜色补上环境反射的光
				return float4(Final, 1.0) + 0.03 * sh * albedo;
			}
			ENDCG	
		}
		Pass{
			Tags {
				"RenderType" = "Opaque"
				"LightMode" = "ForwardAdd"
			}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct a2v {
				fixed4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				fixed3 normal : NORMAL;
				float4 tangent : TANGENT;
			};
			struct v2f {
				fixed4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				//切线空间转移到世界空间矩阵
				float4 TtoW0 : TEXCOORD1;
				float4 TtoW1 : TEXCOORD2;
				float4 TtoW2 : TEXCOORD3;
			};

			sampler2D _Albedo;
			sampler2D _Normal;
			sampler2D _MetalnessMap;
			fixed _BumpScale;
			fixed _Metalness;
			fixed _Roughness;
			fixed _key;
			fixed3 _Specular;
			samplerCUBE _Cubemap;
			fixed4 _Albedo_ST;
			uniform fixed4 _LightColor0;

			v2f vert(a2v v) {
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _Albedo);
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed3 worldBinormal = cross(worldNormal, worldTangent)*v.tangent.w;

				//切线到世界坐标的转换矩阵
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
				return o;
			}
			//菲涅尔函数
			fixed3 fresnelSchlick(float cosTheta, fixed3 F0) {
				return F0 + (1.0 - F0)*pow(1.0 - cosTheta, 5.0);
			}
			//微表面分布函数
			fixed DistributionGGX(fixed3 N, fixed3 H, fixed roughness) {
				fixed a = roughness * roughness;
				fixed a2 = a * a;
				fixed NdotH = max(dot(N, H), 0.0);
				fixed NdotH2 = NdotH * NdotH;

				fixed nom = a2;
				fixed denom = (NdotH2*(a2 - 1.0) + 1.0);
				denom = UNITY_PI * denom * denom;
				return nom / denom;
			}
			//几何衰减
			fixed GeometrySchlickGGX(fixed NdotV, fixed roughness) {
				fixed r = (roughness + 1.0);
				fixed k = (r*r) / 8.0;

				fixed nom = NdotV;
				fixed denom = NdotV * (1.0 - k) + k;
				return nom / denom;
			}
			fixed GeometrySmith(fixed3 N, fixed3 V, fixed3 L, fixed roughness) {
				fixed NdotV = max(dot(N, V), 0.0);
				fixed NdotL = max(dot(N, L), 0.0);
				fixed ggx2 = GeometrySchlickGGX(NdotV, roughness);
				fixed ggx1 = GeometrySchlickGGX(NdotL, roughness);
				return ggx1 * ggx2;
			}

			fixed4 frag(v2f i) : SV_Target{
				float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
				fixed4 albedo = tex2D(_Albedo, i.uv);
				fixed4 Metalness = tex2D(_MetalnessMap, i.uv);
				//切线空间下的法线
				fixed3 normal = UnpackNormal(tex2D(_Normal, i.uv));
				//计算出z分量的值，参考入门精要
				normal.xy *= _BumpScale;
				normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
				//法线转移到世界空间
				normal = normalize(half3(dot(i.TtoW0.xyz, normal), dot(i.TtoW1.xyz, normal), dot(i.TtoW2.xyz, normal)));
				normal = normalize(float3(i.TtoW0.z, i.TtoW1.z, i.TtoW2.z));

				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				fixed3 halfDir = normalize(viewDir + lightDir);

				//反射方向
				fixed3 reflectDir = normalize(reflect(-viewDir, normal));
				//处理反射
				fixed3 reflection = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectDir, _Roughness * 5).rgb;

				//根据金属度来区别菲涅尔系数
				fixed3 F0 = lerp(fixed3(0.04, 0.04, 0.04), albedo, _Metalness);
				fixed3 fresnel = fresnelSchlick(max(dot(normal, viewDir), 0.0), F0);
				//微表面分布项
				fixed D = DistributionGGX(normal, halfDir, _Roughness);
				//几何遮蔽项
				fixed G = GeometrySmith(normal, viewDir, lightDir, _Roughness);

				//+0.001是为了防止除零错误
				fixed3 specular = D * G*fresnel / (4.0*max(dot(normal, viewDir), 0.0) * max(dot(normal, lightDir), 0.0) + 0.01);

				//用菲涅尔项做高光与反射的插值
				specular += lerp(specular, reflection, fresnel);
				//diffuse项的系数
				fixed diff = (1.0 - fresnel) * (1.0 - _Metalness);

				//ShadeSH9是一个球谐函数(没搞懂)
				//球谐光照实际上是将周围环境光采样成几个系数，用这几个系数对光照还原
				//计算量与光源的数量无光，用于模拟实时光照
				float4 sh = float4(ShadeSH9(half4(normal, 1)), 1.0);

				fixed3 Final = (diff * albedo + specular)* _LightColor0.xyz * (max(dot(normal, lightDir), 0.0) + 0.0);
				//最终颜色补上环境反射的光
				return float4(Final, 1.0) + 0.03 * sh * albedo;
			}
			ENDCG
		}
    }
    FallBack "Diffuse"
}
