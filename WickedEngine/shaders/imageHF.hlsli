#ifndef WI_IMAGE_HF
#define WI_IMAGE_HF
#include "globals.hlsli"
#include "ShaderInterop_Image.h"

float Wedge2D(float2 v, float2 w)
{
	return v.x * w.y - v.y * w.x;
}

struct VertextoPixel
{
	float4 pos : SV_POSITION;
	float2 q : TEXCOORD3;
	float2 b1 : TEXCOORD4;
	float2 b2 : TEXCOORD5;
	float2 b3 : TEXCOORD6;

	float2 uv_screen()
	{
		return pos.xy * image.output_resolution_rcp;
	}
	float4 compute_uvs()
	{
		float2 uv0;
		float2 uv1;

		[branch]
		if (image.flags & IMAGE_FLAG_FULLSCREEN)
		{
			uv0 = uv_screen();
			uv1 = uv0;
		}
		else
		{
			// Quad interpolation: http://reedbeta.com/blog/quadrilateral-interpolation-part-2/

			// Set up quadratic formula
			float A = Wedge2D(b2, b3);
			float B = Wedge2D(b3, q) - Wedge2D(b1, b2);
			float C = Wedge2D(b1, q);

			// Solve for v
			float2 uv;
			if (abs(A) < 0.001)
			{
				// Linear form
				uv.y = -C / B;
			}
			else
			{
				// Quadratic form. Take positive root for CCW winding with V-up
				float discrim = B * B - 4 * A * C;
				uv.y = 0.5 * (-B + sqrt(discrim)) / A;
			}

			// Solve for u, using largest-magnitude component
			float2 denom = b1 + uv.y * b3;
			if (abs(denom.x) > abs(denom.y))
				uv.x = (q.x - b2.x * uv.y) / denom.x;
			else
				uv.x = (q.y - b2.y * uv.y) / denom.y;

			float4 texMulAdd = unpack_half4(image.texMulAdd);
			float4 texMulAdd2 = unpack_half4(image.texMulAdd2);

			uv0 = mad(uv, texMulAdd.xy, texMulAdd.zw);
			uv1 = mad(uv, texMulAdd2.xy, texMulAdd2.zw);
		}

		return float4(uv0, uv1);
	}
};

#endif // WI_IMAGE_HF

