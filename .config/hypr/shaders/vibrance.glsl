#version 300 es
// Luma-preserving saturation boost — compensates for the laptop panel's
// narrow gamut (~60% sRGB) feeling washed out next to a P3 Mac display.
// 1.0 = neutral. Raise/lower SATURATION to taste; reload Hyprland to apply.
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

const float SATURATION = 1.15;

void main() {
    vec4 color = texture(tex, v_texcoord);
    float luma = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
    fragColor = vec4(mix(vec3(luma), color.rgb, SATURATION), color.a);
}
