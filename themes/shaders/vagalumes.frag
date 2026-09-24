// Vaga-lumes: pontos de luz que vagam devagar e acendem e apagam, sobre uma
// mata escura com névoa no chão. (Everforest)
float fireflies(vec2 uv, float scale, float seed) {
    vec2 g = uv * scale;
    vec2 cell = floor(g);
    float h = hash(cell + seed);
    if (h > 0.22)
        return 0.0;
    float t = time * (0.15 + h * 0.3) + h * 60.0;
    vec2 pos = 0.5 + 0.32 * vec2(sin(t * 1.3 + h * 9.0), cos(t * 0.9 + h * 4.0));
    float d = length(fract(g) - pos);
    float blink = pow(max(0.0, sin(time * (0.4 + h) + h * 30.0)), 3.0);
    return (smoothstep(0.05, 0.0, d) + smoothstep(0.28, 0.0, d) * 0.25) * blink;
}

void main() {
    float aspect = resolution.x / resolution.y;
    vec2 uv = vec2(qt_TexCoord0.x * aspect, qt_TexCoord0.y);
    vec2 p = centered();
    vec3 col = mix(base.rgb, surface.rgb, smoothstep(0.8, -0.8, p.y) * 0.5);
    float mist = fbm(vec2(p.x * 1.5 + time * 0.015, p.y * 2.5));
    col = mix(col, surface.rgb * 1.15, smoothstep(0.0, -0.6, p.y) * smoothstep(0.4, 0.9, mist) * 0.6);
    vec3 glow = mix(accent.rgb, vec3(1.0, 0.95, 0.6), 0.35);
    col += glow * (fireflies(uv, 6.0, 0.0) + fireflies(uv, 10.0, 17.0) * 0.6) * 0.8;
    fragColor = vec4(dither(col), 1.0) * qt_Opacity;
}
