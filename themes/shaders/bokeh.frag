// Bokeh: luzes de cidade à noite, desfocadas, que flutuam e pulsam devagar
// em duas camadas. (Tokyo Night)
float lights(vec2 uv, float scale, float seed, out vec3 tint) {
    vec2 g = uv * scale + vec2(time * 0.02 * (1.0 + seed * 0.1), 0.0);
    vec2 cell = floor(g);
    float h = hash(cell + seed);
    tint = vec3(0.0);
    if (h > 0.3)
        return 0.0;
    vec2 pos = 0.25 + 0.5 * vec2(hash(cell + 4.1 + seed), hash(cell + 9.3 + seed));
    pos += 0.08 * vec2(sin(time * 0.3 + h * 20.0), cos(time * 0.25 + h * 12.0));
    float d = length(fract(g) - pos);
    float r = 0.18 + 0.14 * hash(cell + 1.7);
    float disk = smoothstep(r, r * 0.75, d) * 0.7 + smoothstep(r * 0.9, r * 0.8, d) * 0.3;
    float pulse = 0.6 + 0.4 * sin(time * (0.3 + h) + h * 40.0);
    tint = h < 0.12 ? accent.rgb : h < 0.22 ? clamp(hueShift(accent.rgb, 1.1), 0.0, 1.0) : clamp(hueShift(accent.rgb, -0.8), 0.0, 1.0);
    return disk * pulse;
}

void main() {
    float aspect = resolution.x / resolution.y;
    vec2 uv = vec2(qt_TexCoord0.x * aspect, qt_TexCoord0.y);
    vec2 p = centered();
    vec3 col = mix(base.rgb, surface.rgb, smoothstep(0.6, -0.8, p.y) * 0.5);
    vec3 t1;
    vec3 t2;
    float a = lights(uv, 3.0, 0.0, t1);
    float b = lights(uv + 0.37, 5.5, 13.0, t2);
    col += t1 * a * 0.22 + t2 * b * 0.14;
    fragColor = vec4(dither(col), 1.0) * qt_Opacity;
}
