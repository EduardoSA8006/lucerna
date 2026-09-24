// Aurora: nuvens de nebulosa que se movem devagar, um brilho do acento de um
// lado e o de uma segunda cor (o acento com o matiz girado) do outro, e um
// céu de estrelas que piscam. (Nebulosa)
void main() {
    vec2 p = centered();
    float aspect = resolution.x / resolution.y;
    float t = time * 0.02;
    vec3 second = clamp(hueShift(accent.rgb, -1.25), 0.0, 1.0);
    vec2 q = p + 0.25 * vec2(fbm(p * 1.2 + t), fbm(p * 1.2 - t + 5.2));
    float n = fbm(q * 1.5 + vec2(t, -t * 0.6));
    float m = fbm(q * 2.4 + vec2(-t * 0.8, t * 0.5) + n * 1.8);
    vec3 col = base.rgb;
    // Brilhos: acento no alto à esquerda, a segunda cor embaixo à direita.
    float a = exp(-length((p - vec2(-aspect * 0.28, 0.3)) * vec2(0.9, 1.2)) * 2.2);
    float b = exp(-length((p - vec2(aspect * 0.32, -0.34)) * vec2(0.9, 1.3)) * 2.4);
    col += accent.rgb * a * (0.26 + 0.34 * m);
    col += second * b * (0.16 + 0.24 * m);
    // Nuvens: tingidas pelo brilho que bate nelas.
    float cloud = smoothstep(0.45, 1.0, m);
    vec3 tint = mix(surface.rgb, mix(accent.rgb, second, b / max(a + b, 0.001)), 0.55);
    col = mix(col, tint, cloud * (0.2 + 0.6 * (a + b)));
    col += mix(accent.rgb, text.rgb, 0.7) * stars(qt_TexCoord0 * vec2(aspect, 1.0), 110.0, 0.1) * 0.5;
    fragColor = vec4(dither(col), 1.0) * qt_Opacity;
}
