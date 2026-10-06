// Luma wipe of the scene preview - the math of OBS' own
// plugins/obs-transitions/data/luma_wipe_transition.effect (PSLumaWipe),
// so the preview wipes like the program does.
#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uProgress;
uniform float uSoftness;
uniform float uInvert;
uniform sampler2D uFrom;
uniform sampler2D uTo;
uniform sampler2D uLuma;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  vec4 a = texture(uFrom, uv);
  vec4 b = texture(uTo, uv);
  float luma = texture(uLuma, uv).r;
  if (uInvert > 0.5) {
    luma = 1.0 - luma;
  }
  float time = mix(0.0, 1.0 + uSoftness, uProgress);
  if (luma <= time - uSoftness) {
    fragColor = b;
  } else if (luma >= time) {
    fragColor = a;
  } else {
    fragColor = mix(a, b, (time - luma) / uSoftness);
  }
}
