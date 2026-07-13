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

// Space fragment shader - analogous color space effect with noise
precision mediump float;

out vec4 fragColor;

uniform vec4 u_time;
uniform float u_EmissionGain;

in vec4 v_color;
in vec2 v_texcoord0;

vec2 mod289(vec2 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 mod289(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 mod289(vec4 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
    return mod289(((x * 34.0) + 1.0) * x);
}

vec4 permute(vec4 x) {
    return mod289(((x * 34.0) + 1.0) * x);
}

vec4 taylorInvSqrt(vec4 r) {
    return 1.79284291400159 - 0.85373472095314 * r;
}

float snoise(vec2 v) {
    const vec4 C = vec4(
        0.211324865405187,
        0.366025403784439,
       -0.577350269189626,
        0.024390243902439
    );
    vec2 i = floor(v + dot(v, C.yy));
    vec2 x0 = v - i + dot(i, C.xx);
    vec2 i1 = x0.x > x0.y ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;

    i = mod289(i);
    vec3 p = permute(
        permute(i.y + vec3(0.0, i1.y, 1.0)) +
        i.x + vec3(0.0, i1.x, 1.0)
    );
    vec3 m = max(
        0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)),
        0.0
    );
    m *= m;
    m *= m;

    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);

    vec3 g;
    g.x = a0.x * x0.x + h.x * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

float snoise(vec3 v) {
    const vec2 C = vec2(1.0 / 6.0, 1.0 / 3.0);
    const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);
    vec3 i = floor(v + dot(v, C.yyy));
    vec3 x0 = v - i + dot(i, C.xxx);
    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    vec3 i1 = min(g.xyz, l.zxy);
    vec3 i2 = max(g.xyz, l.zxy);
    vec3 x1 = x0 - i1 + C.xxx;
    vec3 x2 = x0 - i2 + C.yyy;
    vec3 x3 = x0 - D.yyy;

    i = mod289(i);
    vec4 p = permute(
        permute(
            permute(i.z + vec4(0.0, i1.z, i2.z, 1.0)) +
            i.y + vec4(0.0, i1.y, i2.y, 1.0)
        ) + i.x + vec4(0.0, i1.x, i2.x, 1.0)
    );
    float n = 1.0 / 7.0;
    vec3 ns = n * D.wyz - D.xzx;
    vec4 j = p - 49.0 * floor(p * ns.z * ns.z);
    vec4 x_ = floor(j * ns.z);
    vec4 y_ = floor(j - 7.0 * x_);
    vec4 x = x_ * ns.x + ns.yyyy;
    vec4 y = y_ * ns.x + ns.yyyy;
    vec4 h = 1.0 - abs(x) - abs(y);
    vec4 b0 = vec4(x.xy, y.xy);
    vec4 b1 = vec4(x.zw, y.zw);
    vec4 s0 = floor(b0) * 2.0 + 1.0;
    vec4 s1 = floor(b1) * 2.0 + 1.0;
    vec4 sh = -step(h, vec4(0.0));
    vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
    vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
    vec3 p0 = vec3(a0.xy, h.x);
    vec3 p1 = vec3(a0.zw, h.y);
    vec3 p2 = vec3(a1.xy, h.z);
    vec3 p3 = vec3(a1.zw, h.w);
    vec4 norm = taylorInvSqrt(vec4(
        dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)
    ));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;
    vec4 m = max(0.5 - vec4(
        dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)
    ), 0.0);
    m *= m;
    return 42.0 * dot(m * m, vec4(
        dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)
    ));
}

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 6; i++) {
        value += amplitude * snoise(p);
        p *= 2.0;
        amplitude *= 0.516;
    }
    return value;
}

float fbm(vec3 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 6; i++) {
        value += amplitude * snoise(p);
        p *= 2.0;
        amplitude *= 0.516;
    }
    return value;
}

// RGB to HSV conversion
vec3 RGBtoHSV(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// HSV to RGB conversion
vec3 HSVToRGB(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Clamped remap function from Math.cginc
float clampedRemap(float x1, float x2, float y1, float y2, float x) {
    float t = clamp((x - x1) / (x2 - x1), 0.0, 1.0);
    return mix(y1, y2, t);
}

vec4 bloomColor(vec4 color, float gain) {
    float cmin = length(color.rgb) * 0.05;
    color.rgb = max(color.rgb, vec3(cmin, cmin, cmin));
    color = pow(color, vec4(2.2));
    color.rgb *= 2.0 * exp(gain * 10.0);
    return color;
}

vec4 encodeHdr(vec3 color) {
    return vec4(color, 1.0);
}

void main() {
    float analog_spread = 0.1;  // how far the analogous hues are from the primary
    float gain = 10.0;
    float gain2 = 0.0;

    // Primary hue is chosen by user
    vec3 i_HSV = RGBtoHSV(v_color.rgb);

    // We're gonna mix these 3 colors together
    float primary_hue = i_HSV.x;
    float analog1_hue = fract(primary_hue - analog_spread);
    float analog2_hue = fract(primary_hue + analog_spread);

    float r = abs(v_texcoord0.y * 2.0 - 1.0);  // distance from center of stroke

    // Determine the contributions of each hue
    float primary_a = 0.2 * fbm(v_texcoord0 + u_time.x) * gain + gain2;
    float analog1_a = 0.2 * fbm(vec3(v_texcoord0.x + 12.52, v_texcoord0.y + 12.52, u_time.x * 5.2)) * gain + gain2;
    float analog2_a = 0.2 * fbm(vec3(v_texcoord0.x + 6.253, v_texcoord0.y + 6.253, u_time.x * 0.8)) * gain + gain2;

    // The main hue is present in the center and falls off with randomized radius
    primary_a = clampedRemap(0.0, 0.5, primary_a, 0.0, r + fbm(vec2(u_time.x + 50.0, v_texcoord0.x)) * 2.0);

    // The analog hues start a little out from the center and increase with intensity going out
    analog1_a = clampedRemap(0.2, 1.0, 0.0, analog1_a * 1.2, r);
    analog2_a = clampedRemap(0.2, 1.0, 0.0, analog2_a * 1.2, r);

    vec4 color;
    color.a = primary_a + analog1_a + analog2_a;

    float final_hue = (primary_a * primary_hue + analog1_a * analog1_hue + analog2_a * analog2_hue) / color.a;

    // Now sculpt the overall shape of the stroke
    float lum = 1.0 - r;
    float rfbm = fbm(vec2(v_texcoord0.x, u_time.x));
    rfbm += 1.2;
    rfbm *= 0.8;
    lum *= step(r, rfbm);  // shorten the radius with fbm

    // Blur the edge a little bit
    lum *= smoothstep(rfbm, rfbm - 0.2, r);

    color.rgb = HSVToRGB(vec3(final_hue, i_HSV.y, i_HSV.z * lum));
    color = clamp(color, 0.0, 1.0);
    color = bloomColor(color, u_EmissionGain);
    fragColor = encodeHdr(color.rgb);
}
