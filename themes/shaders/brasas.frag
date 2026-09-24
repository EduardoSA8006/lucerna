// Brasas: carvão escuro, um calor que sobe do chão e fagulhas subindo e
// piscando. (Brasa)
float ember(vec2 uv, float scale, float speed, float seed) {
    vec2 g = uv * vec2(scale, scale * 0.6);
    g.y -= time * speed;
    g.x += sin(g.y * 0.7 + seed) * 0.35;
    vec2 cell = floor(g);
    float h = hash(cell + seed);
    if (h > 0.18)
        return 0.0;
    vec2 pos = vec2(hash(cell + 1.3 + seed), hash(cell + 5.9 + seed));
    float d = length(fract(g) - pos);
    float flicker = 0.5 + 0.5 * sin(time * (2.0 + h * 5.0) + h * 30.0);
    // Somem ao subir.
    float fade = smoothstep(1.05, 0.2, uv.y);
    return smoothstep(0.09, 0.0, d) * flicker * fade;
}

void main() {
    vec2 uv = vec2(qt_TexCoord0.x * resolution.x / resolution.y, 1.0 - qt_TexCoord0.y);
    vec2 p = centered();
    float t = time * 0.04;
    vec3 hot = mix(accent.rgb, vec3(1.0, 0.82, 0.5), 0.45);
    vec3 col = base.rgb;
    // Calor na base, ondulando.
    float heat = fbm(vec2(p.x * 2.0, p.y * 3.0 - t * 4.0));
    col += accent.rgb * smoothstep(0.55, -0.6, p.y) * (0.18 + 0.2 * heat);
    col += accent.rgb * exp(-length(p - vec2(0.2, -0.75)) * 1.6) * 0.18;
    float e = ember(uv, 14.0, 0.09, 0.0) + ember(uv, 22.0, 0.06, 11.0) * 0.7 + ember(uv, 34.0, 0.04, 23.0) * 0.45;
    col += hot * e * 0.9;
    fragColor = vec4(dither(col), 1.0) * qt_Opacity;
}
