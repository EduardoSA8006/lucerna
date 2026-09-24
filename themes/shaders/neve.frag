// Neve: flocos caindo em três camadas de profundidade, com um vento lento que
// balança, sobre um céu frio. (Nord)
float flakes(vec2 uv, float scale, float speed, float size, float seed) {
    vec2 g = uv * scale;
    g.y += time * speed;
    g.x += sin(g.y * 0.35 + time * 0.3 + seed) * 0.6;
    vec2 cell = floor(g);
    float h = hash(cell + seed);
    if (h > 0.35)
        return 0.0;
    vec2 pos = 0.2 + 0.6 * vec2(hash(cell + 2.7 + seed), hash(cell + 8.1 + seed));
    return smoothstep(size, size * 0.2, length(fract(g) - pos));
}

void main() {
    float aspect = resolution.x / resolution.y;
    vec2 uv = vec2(qt_TexCoord0.x * aspect, qt_TexCoord0.y);
    vec2 p = centered();
    vec3 col = mix(base.rgb, surface.rgb, smoothstep(-0.7, 0.7, p.y) * 0.6);
    col += accent.rgb * exp(-length(p - vec2(-aspect * 0.25, 0.35)) * 2.2) * 0.1;
    float snow = flakes(uv, 7.0, 0.35, 0.12, 0.0) * 0.9 + flakes(uv, 13.0, 0.22, 0.1, 5.0) * 0.6 + flakes(uv, 24.0, 0.13, 0.09, 11.0) * 0.35;
    col = mix(col, text.rgb, snow * 0.75);
    fragColor = vec4(dither(col), 1.0) * qt_Opacity;
}
