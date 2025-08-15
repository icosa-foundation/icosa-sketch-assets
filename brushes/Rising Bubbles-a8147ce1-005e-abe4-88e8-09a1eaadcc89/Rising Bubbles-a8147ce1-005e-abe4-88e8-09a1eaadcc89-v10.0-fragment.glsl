// Copyright 2020 The Tilt Brush Authors
// Updated to OpenGL ES 3.0 by the Icosa Gallery Authors
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

precision mediump float;

out vec4 fragColor;

in vec4 v_color;
in vec2 v_texcoord0;

uniform sampler2D u_MainTex;
uniform float u_ScrollRate;
uniform vec4 u_ScrollDistance; // Only x used here for UV domain scaling
uniform float u_ScrollJitterIntensity;
uniform float u_ScrollJitterFrequency;
uniform vec4 u_time; // Use y component for time, matching Unity _Time.y

void main() {
  // Time in [0,1] with seed from vertex alpha (Unity uses color.a)
  float seed = v_color.a;
  float t01 = fract(u_time.y * u_ScrollRate + seed * 10.0);

  // Scroll along U; wrap to [0,1]
  float u = fract(v_texcoord0.x - t01);
  float v = v_texcoord0.y;

  // Sample texture at scrolled coords
  vec4 tex = texture(u_MainTex, vec2(u, v));

  // RGB affected by color; alpha channel contributes a highlight
  vec3 basecolor = v_color.rgb * tex.rgb;
  vec3 highlightcolor = vec3(tex.a);

  // Dim over lifetime (toward end)
  float dim = pow(1.0 - t01, 1.0) * 5.0;
  vec3 rgb = (basecolor + highlightcolor) * dim;

  fragColor = vec4(rgb, 1.0);
}
