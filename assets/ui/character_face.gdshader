shader_type canvas_item;

uniform vec2 eye_left = vec2(-1.0);
uniform vec2 eye_right = vec2(-1.0);
uniform vec2 eye_radius = vec2(0.005, 0.003);
uniform vec2 mouth_center = vec2(-1.0);
uniform vec2 mouth_radius = vec2(0.006, 0.003);
uniform float blink : hint_range(0.0, 1.0) = 0.0;
uniform float talking : hint_range(0.0, 1.0) = 0.0;
uniform float reaction : hint_range(0.0, 1.0) = 0.0;
uniform bool alternate_uniform = false;
varying vec4 vertex_tint;

void vertex() {
    vertex_tint = COLOR;
}

vec2 close_eye(vec2 uv, vec2 center) {
    vec2 local = (uv - center) / max(eye_radius, vec2(0.00001));
    float edge = 1.0 - smoothstep(0.75, 1.0, abs(local.x));
    float amount = blink * edge * (1.0 - smoothstep(0.8, 1.0, abs(local.y)));
    float mapped_y = clamp(local.y / max(0.05, 1.0 - amount * 0.95), -1.0, 1.0);
    return vec2(uv.x, mix(uv.y, center.y + mapped_y * eye_radius.y, amount));
}

void fragment() {
    vec2 uv = close_eye(close_eye(UV, eye_left), eye_right);
    vec2 mouth = (uv - mouth_center) / max(mouth_radius, vec2(0.00001));
    float lip_mask = (1.0 - smoothstep(0.75, 1.0, abs(mouth.x))) * (1.0 - smoothstep(0.8, 1.0, abs(mouth.y)));
    float flap = (0.5 + 0.5 * sin(TIME * 17.0)) * talking;
    uv.y = mix(uv.y, mouth_center.y + (uv.y - mouth_center.y) / (1.0 + flap * 0.55), lip_mask);
    vec4 pixel = texture(TEXTURE, uv);
    if (alternate_uniform && pixel.g > pixel.r * 1.25 && pixel.b > pixel.r * 1.1) {
        pixel.rgb = mix(pixel.rgb, vec3(pixel.g * 1.05, pixel.g * 0.38, pixel.b * 0.82), 0.85);
    }
    pixel.rgb = mix(pixel.rgb, pixel.rgb * vec3(1.06, 1.025, 0.98), reaction);
    COLOR = pixel * vertex_tint;
}
