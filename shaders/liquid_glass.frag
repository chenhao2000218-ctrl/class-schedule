#version 460 core

#include <flutter/runtime_effect.glsl>

// 液态玻璃边缘折射 + 色差效果（生成式，不需要背后采样）
// 在玻璃边缘绘制彩虹色高光，模拟物理折射的色差效果

uniform vec2 size;              // 组件尺寸
uniform float displacementScale; // 折射强度
uniform float aberration;       // 色差强度
uniform float edgeWidth;        // 边缘宽度占比
uniform float time;             // 时间

out vec4 fragColor;

// 噪声
float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  return mix(
    mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
    mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
    f.y
  );
}

float fbm(vec2 p) {
  float value = 0.0;
  float amplitude = 0.5;
  for (int i = 0; i < 4; i++) {
    value += amplitude * noise(p);
    p *= 2.0;
    amplitude *= 0.5;
  }
  return value;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / size;

  // 到最近边缘的距离
  vec2 edgeDist = min(uv, 1.0 - uv);
  float minEdgeDist = min(edgeDist.x, edgeDist.y);

  // 边缘 mask：边缘 1，中心 0
  float edgeMask = 1.0 - smoothstep(0.0, edgeWidth, minEdgeDist);

  // 边缘法线方向（指向最近边缘）
  vec2 edgeNormal = normalize(uv - 0.5 + vec2(0.001));

  // 基于噪声的折射方向扰动
  vec2 noiseUv = uv * 8.0 + vec2(time * 0.05, time * 0.03);
  float n = fbm(noiseUv) - 0.5;
  vec2 refractDir = edgeNormal + vec2(n * 0.5, n * 0.3);
  refractDir = normalize(refractDir);

  // 彩虹色：基于折射方向生成 RGB 分离
  // 模拟棱镜分光：不同波长折射角度不同
  float angle = atan(refractDir.y, refractDir.x);
  float hue = (angle / 6.28318 + 0.5) * 360.0;

  // HSV 转 RGB
  float c = 1.0;
  float x = 1.0 - abs(mod(hue / 60.0, 2.0) - 1.0);
  vec3 rainbow;
  if (hue < 60.0) rainbow = vec3(c, x, 0.0);
  else if (hue < 120.0) rainbow = vec3(x, c, 0.0);
  else if (hue < 180.0) rainbow = vec3(0.0, c, x);
  else if (hue < 240.0) rainbow = vec3(0.0, x, c);
  else if (hue < 300.0) rainbow = vec3(x, 0.0, c);
  else rainbow = vec3(c, 0.0, x);

  // 色差强度控制
  rainbow = mix(vec3(1.0), rainbow, aberration * edgeMask);

  // 边缘亮度增强。保持克制，避免形成可见的白色流动贴图。
  float edgeBrightness = edgeMask * (0.035 + 0.015 * sin(time * 2.0 + n * 6.28));

  // 最终颜色：只在边缘产生极弱折射，中心保持完全透明。
  vec3 color = vec3(0.0);
  color += rainbow * edgeMask * 0.04 * displacementScale * 0.02;
  color += vec3(1.0) * edgeBrightness;

  // 透明度：中心为 0，避免盖住中文文字或控件内容。
  float alpha = edgeMask * 0.18;

  fragColor = vec4(color, alpha);
}
