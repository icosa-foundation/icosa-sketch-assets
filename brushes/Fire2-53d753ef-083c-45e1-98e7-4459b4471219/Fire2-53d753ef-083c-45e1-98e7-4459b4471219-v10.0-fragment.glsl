
// Copyright 2020 The Tilt Brush Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Fire2 fragment shader
precision mediump float;

out vec4 fragColor;

uniform sampler2D u_MainTex;
uniform sampler2D u_DisplaceTex;
uniform vec4 u_time;
uniform float u_Scroll1;
uniform float u_Scroll2;
uniform float u_DisplacementIntensity;
uniform float u_FlameFadeMin;
uniform float u_FlameFadeMax;
uniform float u_EmissionGain;

in vec4 v_color;
in vec2 v_texcoord0;
in vec4 v_worldPos;

vec4 bloomColor(vec4 color, float gain) {
  float cmin = length(color.rgb) * 0.05;
  color.rgb = max(color.rgb, vec3(cmin));
  color = pow(color, vec4(2.2));
  color.rgb *= 2.0 * exp(gain * 10.0);
  return color;
}

void main() {
  vec2 displacement;
  float flame_fade_mix = 0.0;

  // Sample displacement texture
  displacement = texture(u_DisplaceTex, v_texcoord0).xy;
  displacement = displacement * 2.0 - 1.0;
  displacement *= u_DisplacementIntensity;

  // Sample mask from MainTex y channel
  float mask = texture(u_MainTex, v_texcoord0).y;

  // Apply displacement to UV coordinates
  vec2 uv = v_texcoord0;
  uv += displacement;

  // Sample flame textures with scrolling animation
  float flame1 = texture(u_MainTex, uv * 0.7 + vec2(-u_time.x * u_Scroll1, 0.0)).x;
  float flame2 = texture(u_MainTex, vec2(uv.x, 1.0 - uv.y) + vec2(-u_time.x * u_Scroll2, -u_time.x * u_Scroll2 / 4.0)).x;

  // Combine flames
  float flames = clamp(flame2 + flame1, 0.0, 1.0) / 2.0;
  flames = smoothstep(0.0, 0.8, mask * flames);
  flames *= mask;

  // Create flame texture
  vec4 tex = vec4(flames, flames, flames, 1.0);
  float flame_fade = mix(u_FlameFadeMin, u_FlameFadeMax, flame_fade_mix);

  // Apply flame fade along stroke
  tex.xyz *= pow(1.0 - v_texcoord0.x, flame_fade) * (flame_fade * 2.0);

  vec4 color = bloomColor(v_color, u_EmissionGain) * tex;
  fragColor = color * color.a;
}
