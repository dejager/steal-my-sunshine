#include <metal_stdlib>
using namespace metal;

#define saturate(x) clamp(x,0.0, 1.0)
#define rgb(r,g,b) (float3(r,g,b)/ 255.0)

float random(float x) {
  return fract(sin(x) * 71523.5413291);
}

float random(float2 x) {
  return random(dot(x, float2(13.4251, 15.5128)));
}

float noise(float2 x) {
  float2 i = floor(x);
  float2 f = x - i;
  f *= f * (3.0 -2.0 * f);
  return mix(mix(random(i), random(i+float2(1.0, 0.0)), f.x),
             mix(random(i + float2(0.0, 1.0)), random(i + float2(1.0, 1.0)), f.x), f.y);
}

float fractalBrownianMotion(float2 x) {
  float r = 0.0, s = 1.0, w = 1.0;
  for (int i = 0.0; i < 5.0; i++) {
    s *= 2.0;
    w *= 0.5;
    r += w * noise(s * x);
  }
  return r;
}

float cloud(float2 uv, float scalex, float scaley, float density, float sharpness, float speed, float time) {
  return pow(saturate(fractalBrownianMotion(float2(scalex, scaley) * (uv + float2(speed, 0) * time)) - (1.0 - density)), 1.0 - sharpness);
}

float3 render(float2 uv, float time) {
  // sky
  float3 color = mix(rgb(255.0, 212.0 ,166.0), rgb(204.0, 235.0, 255.0), uv.y);

  // sun
  float2 spos = uv - float2(0.0, 0.4);
  float sun = exp(-20.0 * dot(spos, spos));
  float3 scol = rgb(255, 155, 102) * sun * 0.7;
  color += scol;

  // clouds
  float3 cl1 = mix(rgb(151,138,153), rgb(166,191,224),uv.y);
  float d1 = mix(0.9,0.1,pow(uv.y, 0.7));

  color = mix(color, cl1, cloud(uv, 2.0, 8.0, d1, 0.4, 0.04, time));
  color = mix(color, float3(0.9), 8.0 * cloud(uv, 14.0, 18.0, 0.9, 0.75, 0.02, time) * cloud(uv,2.0, 5.0, 0.6, 0.15, 0.01, time) * uv.y);
  color = mix(color, float3(0.8), 5.0 * cloud(uv, 12.0 ,15.0, 0.9, 0.75, 0.03, time) * cloud(uv,2.0, 8.0, 0.5, 0.0, 0.02, time) * uv.y);

  // post-processing
  color *= float3(1.0, 0.93, 0.81) * 1.04;
  color = mix(0.75 * rgb(255.0, 205.0, 161.0), color, smoothstep(-0.1, 0.3, uv.y));
  color = pow(color, float3(1.3));
  return color;
}

kernel void keepingVersed(texture2d<float, access::write> o[[texture(0)]],
                          constant float &time [[buffer(0)]],
                          constant float2 *touchEvent [[buffer(1)]],
                          constant int &numberOfTouches [[buffer(2)]],
                          ushort2 gid [[thread_position_in_grid]]) {

  int width = o.get_width();
  int height = -o.get_height();
  float2 res = float2(width, height);

  float2 uv = float2(gid.xy) / res.xy;
  uv.x -= 0.5;
  uv.y += 1.0;
  uv.x *= res.x / res.y;

  float4 color = float4(render(uv, time), 1.0);
  o.write(color, gid);
}
