shader_type canvas_item;

uniform vec2 eye_left;
uniform vec2 eye_right;
uniform vec2 mouth_center;
uniform float blink = 0.0;
uniform float talking = 0.0;
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
    pixel.a *= smoothstep(0.25, 0.65, pixel.a);
    COLOR = pixel * tint;
}
