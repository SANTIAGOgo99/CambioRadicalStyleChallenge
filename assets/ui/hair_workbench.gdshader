shader_type canvas_item;

uniform vec2 eye_left;
uniform vec2 eye_right;
uniform vec2 mouth_center;
uniform float blink = 0.0;
uniform float talking = 0.0;
uniform sampler2D coat_mask : filter_linear, repeat_disable;
uniform vec4 dye_color : source_color = vec4(1.0);
uniform bool wet_coat = false;
varying vec4 tint;

void vertex() { tint = COLOR; }

vec2 eyelid(vec2 uv, vec2 center) {
    vec2 radius = vec2(0.015, 0.019);
    vec2 d = (uv - center) / radius;
    float mask = (1.0 - smoothstep(0.65, 1.0, abs(d.x))) * (1.0 - smoothstep(0.65, 1.0, abs(d.y)));
    uv.y = mix(uv.y, center.y + clamp(d.y / max(0.04, 1.0 - blink * 0.96), -1.0, 1.0) * radius.y, mask * blink);
    return uv;
}

void fragment() {
    vec2 uv = eyelid(eyelid(UV, eye_left), eye_right);
    vec2 d = (uv - mouth_center) / vec2(0.019, 0.014);
    float mask = (1.0 - smoothstep(0.6, 1.0, abs(d.x))) * (1.0 - smoothstep(0.7, 1.0, abs(d.y)));
    uv.y = mix(uv.y, mouth_center.y + (uv.y - mouth_center.y) / (1.0 + talking * (0.5 + 0.5 * sin(TIME * 16.0)) * 0.5), mask);
    vec4 pixel = texture(TEXTURE, uv);
    if (UV.x >= 1.0 / 3.0) {
        float column = min(floor(UV.x * 3.0), 2.0);
        vec2 local_uv = vec2(clamp(UV.x * 3.0 - column, 0.0, 1.0), UV.y);
        float coverage = texture(coat_mask, local_uv).r;
        vec3 result = pixel.rgb * dye_color.rgb;
        pixel.rgb = mix(pixel.rgb, result, coverage);
        if (wet_coat) {
            float light = dot(result, vec3(0.299, 0.587, 0.114));
            vec3 cream = vec3(0.91, 0.84, 0.73) * (0.85 + light * 0.15);
            vec3 wet = mix(result * 0.55, cream, 0.85);
            float shine = pow(max(0.0, sin(local_uv.x * 38.0 + local_uv.y * 9.0)), 14.0);
            pixel.rgb = mix(pixel.rgb, wet + shine * 0.12, coverage * 0.96);
        }
    }
    pixel.a *= smoothstep(0.25, 0.65, pixel.a);
    COLOR = pixel * tint;
}
