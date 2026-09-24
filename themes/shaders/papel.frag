// Papel: folha clara com manchas de tinta que se espalham devagar e a textura
// fina do papel. Feito para temas claros. (Pergaminho)
void main() {
    vec2 p = centered();
    float t = time * 0.012;
    float ink = fbm(p * 1.3 + vec2(t, t * 0.7));
    float veil = fbm(p * 2.6 - vec2(t * 0.6, -t) + ink);
    vec3 col = base.rgb;
    col = mix(col, surface.rgb, smoothstep(0.35, 0.8, veil) * 0.8);
    col = mix(col, accent.rgb, smoothstep(0.52, 0.9, ink) * 0.22);
    col = mix(col, text.rgb, smoothstep(0.62, 0.95, veil * ink * 1.6) * 0.06);
    // Fibras do papel, paradas.
    float grain = hash(floor(qt_TexCoord0 * resolution * 0.5));
    col -= (grain - 0.5) * 0.025;
    col -= 0.05 * smoothstep(0.35, 0.95, length(p));
    fragColor = vec4(col, 1.0) * qt_Opacity;
}
