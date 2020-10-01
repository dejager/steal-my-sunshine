#include <metal_stdlib>
using namespace metal;

kernel void keepingVersed(texture2d<float, access::write> o[[texture(0)]],
                          constant float &time [[buffer(0)]],
                          constant float2 *touchEvent [[buffer(1)]],
                          constant int &numberOfTouches [[buffer(2)]],
                          ushort2 gid [[thread_position_in_grid]]) {

  int width = o.get_width();
  int height = o.get_height();
  float2 res = float2(width, height);
  float2 p = float2(gid.xy);

  float2 uv = 7.0 * (p.xy - 0.5 * res.xy) / max(res.x, res.y);

  for(float i=1.0; i < 100.0; i *= 1.1) {
    float2 output = uv;
    output.x += (0.5 / i) * cos(i * uv.y + time * 0.414 + 0.03 * i) + 10.3;
    output.y += (0.5 / i) * cos(i * uv.x + time * 0.297 + 0.03 * (i + 10.0)) + 1.9;
    uv = output;
  }

  float3 color = float3(0.5 * sin(3.0 * uv.x) + 0.5,
                        0.5 * sin(3.0 * uv.y) + 0.5,
                        sin(1.9 * uv.x + 1.7 * uv.y));

  float processedColor = 0.43 * (color.r + color.g + color.b);

  float4 outputColor = float4(processedColor + 0.6,
                              0.2 + 0.75 * processedColor,
                              0.2,
                              1.0);


  o.write(outputColor, gid);
}
