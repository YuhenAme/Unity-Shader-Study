Shader "Custom/OcclusionTransparent"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        
    }
    SubShader
    {
       Tags{"RenderType"="Transparent" "Queue"="Transparent-1"}
	   //第一个Pass只写入深度
	   Pass
	   {
			ZWrite On 
			ColorMask 0 

	   }
	   ZWrite Off 
	   CGPROGRAM
	   #pragma surface surf Lambert alpha 
	   sampler2D _MainTex;
	   fixed4 _Color;
	   struct Input{
			float2 uv_MainTex;
	   };
	   void surf(Input IN,inout SurfaceOutput o){
			fixed4 c = tex2D(_MainTex,IN.uv_MainTex)*_Color;
			o.Albedo = c.rgb;
			o.Alpha  = c.a;
	   }
	   ENDCG

    }
    FallBack "Diffuse"
}
