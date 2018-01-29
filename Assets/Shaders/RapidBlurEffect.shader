// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Learning Unity Shader/Lecture 15/RapidBlurEffect"
{
	//-----------------------------------������ || Properties��------------------------------------------  
	Properties
	{
		//������
		_MainTex("Base (RGB)", 2D) = "white" {}
	}

	//----------------------------------������ɫ�� || SubShader��---------------------------------------  
	SubShader
	{
		ZWrite Off
		Blend Off

		//---------------------------------------��ͨ��0 || Pass 0��------------------------------------
		//ͨ��0��������ͨ�� ||Pass 0: Down Sample Pass
		Pass
		{
			ZTest Off
			Cull Off

			CGPROGRAM

			//ָ����ͨ���Ķ�����ɫ��Ϊvert_DownSmpl
			#pragma vertex vert_DownSmpl
			//ָ����ͨ����������ɫ��Ϊfrag_DownSmpl
			#pragma fragment frag_DownSmpl

			ENDCG

		}

		//---------------------------------------��ͨ��1 || Pass 1��------------------------------------
		//ͨ��1����ֱ����ģ������ͨ�� ||Pass 1: Vertical Pass
		Pass
		{
			ZTest Always
			Cull Off

			CGPROGRAM

			//ָ����ͨ���Ķ�����ɫ��Ϊvert_BlurVertical
			#pragma vertex vert_BlurVertical
			//ָ����ͨ����������ɫ��Ϊfrag_Blur
			#pragma fragment frag_Blur

			ENDCG
		}

		//---------------------------------------��ͨ��2 || Pass 2��------------------------------------
		//ͨ��2��ˮƽ����ģ������ͨ�� ||Pass 2: Horizontal Pass
		Pass
		{
			ZTest Always
			Cull Off

			CGPROGRAM

			//ָ����ͨ���Ķ�����ɫ��Ϊvert_BlurHorizontal
			#pragma vertex vert_BlurHorizontal
			//ָ����ͨ����������ɫ��Ϊfrag_Blur
			#pragma fragment frag_Blur

			ENDCG
		}
	}


	//-------------------------CG��ɫ������������ || Begin CG Include Part----------------------  
	CGINCLUDE

	//��1��ͷ�ļ����� || include
	#include "UnityCG.cginc"

	//��2���������� || Variable Declaration
	sampler2D _MainTex;
	//UnityCG.cginc�����õı����������еĵ����سߴ�|| it is the size of a texel of the texture
	uniform half4 _MainTex_TexelSize;
	//C#�ű����Ƶı��� || Parameter
	uniform half _DownSampleValue;

	//��3����������ṹ�� || Vertex Input Struct
	struct VertexInput
	{
		//����λ������
		float4 vertex : POSITION;
		//һ����������
		half2 texcoord : TEXCOORD0;
	};

	//��4������������ṹ�� || Vertex Input Struct
	struct VertexOutput_DownSmpl
	{
		//����λ������
		float4 pos : SV_POSITION;
		//һ���������꣨���ϣ�
		half2 uv20 : TEXCOORD0;
		//�����������꣨���£�
		half2 uv21 : TEXCOORD1;
		//�����������꣨���£�
		half2 uv22 : TEXCOORD2;
		//�ļ��������꣨���ϣ�
		half2 uv23 : TEXCOORD3;
	};


	//��5��׼����˹ģ��Ȩ�ؾ������7x4�ľ��� ||  Gauss Weight
	static const half4 GaussWeight[7] =
	{
		half4(0.0205,0.0205,0.0205,0),
		half4(0.0855,0.0855,0.0855,0),
		half4(0.232,0.232,0.232,0),
		half4(0.324,0.324,0.324,1),
		half4(0.232,0.232,0.232,0),
		half4(0.0855,0.0855,0.0855,0),
		half4(0.0205,0.0205,0.0205,0)
	};


	//��6��������ɫ���� || Vertex Shader Function
	VertexOutput_DownSmpl vert_DownSmpl(VertexInput v)
	{
		//��6.1��ʵ����һ������������ṹ
		VertexOutput_DownSmpl o;

		//��6.2���������ṹ
		//����ά�ռ��е�����ͶӰ����ά����  
		o.pos = UnityObjectToClipPos(v.vertex);
		//��ͼ��Ľ�������ȡ��������������Χ�ĵ㣬�ֱ�����ļ�����������
		o.uv20 = v.texcoord + _MainTex_TexelSize.xy* half2(0.5h, 0.5h);;
		o.uv21 = v.texcoord + _MainTex_TexelSize.xy * half2(-0.5h, -0.5h);
		o.uv22 = v.texcoord + _MainTex_TexelSize.xy * half2(0.5h, -0.5h);
		o.uv23 = v.texcoord + _MainTex_TexelSize.xy * half2(-0.5h, 0.5h);

		//��6.3���������յ�������
		return o;
	}

	//��7��Ƭ����ɫ���� || Fragment Shader Function
	fixed4 frag_DownSmpl(VertexOutput_DownSmpl i) : SV_Target
	{
		//��7.1������һ����ʱ����ɫֵ
		fixed4 color = (0,0,0,0);

	//��7.2���ĸ��������ص㴦������ֵ���
	color += tex2D(_MainTex, i.uv20);
	color += tex2D(_MainTex, i.uv21);
	color += tex2D(_MainTex, i.uv22);
	color += tex2D(_MainTex, i.uv23);

	//��7.3���������յ�ƽ��ֵ
	return color / 4;
	}

		//��8����������ṹ�� || Vertex Input Struct
	struct VertexOutput_Blur
	{
		//��������
		float4 pos : SV_POSITION;
		//һ�������������꣩
		half4 uv : TEXCOORD0;
		//��������ƫ������
		half2 offset : TEXCOORD1;
	};

	//��9��������ɫ���� || Vertex Shader Function
	VertexOutput_Blur vert_BlurHorizontal(VertexInput v)
	{
		//��9.1��ʵ����һ������ṹ
		VertexOutput_Blur o;

		//��9.2���������ṹ
		//����ά�ռ��е�����ͶӰ����ά����  
		o.pos = UnityObjectToClipPos(v.vertex);
		//��������
		o.uv = half4(v.texcoord.xy, 1, 1);
		//����X�����ƫ����
		o.offset = _MainTex_TexelSize.xy * half2(1.0, 0.0) * _DownSampleValue;

		//��9.3���������յ�������
		return o;
	}

	//��10��������ɫ���� || Vertex Shader Function
	VertexOutput_Blur vert_BlurVertical(VertexInput v)
	{
		//��10.1��ʵ����һ������ṹ
		VertexOutput_Blur o;

		//��10.2���������ṹ
		//����ά�ռ��е�����ͶӰ����ά����  
		o.pos = UnityObjectToClipPos(v.vertex);
		//��������
		o.uv = half4(v.texcoord.xy, 1, 1);
		//����Y�����ƫ����
		o.offset = _MainTex_TexelSize.xy * half2(0.0, 1.0) * _DownSampleValue;

		//��10.3���������յ�������
		return o;
	}

	//��11��Ƭ����ɫ���� || Fragment Shader Function
	half4 frag_Blur(VertexOutput_Blur i) : SV_Target
	{
		//��11.1����ȡԭʼ��uv����
		half2 uv = i.uv.xy;

		//��11.2����ȡƫ����
		half2 OffsetWidth = i.offset;
		//�����ĵ�ƫ��3��������������Ͽ�ʼ��Ȩ�ۼ�
		half2 uv_withOffset = uv - OffsetWidth * 3.0;

		//��11.3��ѭ����ȡ��Ȩ�����ɫֵ
		half4 color = 0;
		for (int j = 0; j< 7; j++)
		{
			//ƫ�ƺ����������ֵ
			half4 texCol = tex2D(_MainTex, uv_withOffset);
			//�������ɫֵ+=ƫ�ƺ����������ֵ x ��˹Ȩ��
			color += texCol * GaussWeight[j];
			//�Ƶ���һ�����ش���׼����һ��ѭ����Ȩ
			uv_withOffset += OffsetWidth;
		}

		//��11.4���������յ���ɫֵ
		return color;
	}

	//-------------------����CG��ɫ������������  || End CG Programming Part------------------  			
	ENDCG

	FallBack Off
}