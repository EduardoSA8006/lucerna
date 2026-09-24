// Luar: céu de madrugada, estrelas que piscam, o halo frio da lua e uma névoa
// que corre baixa. (Luar)
void main() {
    vec2 p = centered();
    float aspect = resolution.x / resolution.y;
    vec3 col = mix(base.rgb, surface.rgb, smoothstep(-0.6, 0.6, -p.y) * 0.35);
    // Lua e halo, no alto à direita.
    vec2 moon = vec2(aspect * 0.28, 0.24);
    float d = length(p - moon);
    vec3 moonlight = mix(accent.rgb, text.rgb, 0.45);
    col = mix(col, moonlight, smoothstep(0.037, 0.028, d) * 0.85);
    col += accent.rgb * exp(-d * 6.0) * (0.2 + 0.03 * sin(time * 0.3));
    col += accent.rgb * exp(-d * 1.6) * 0.06;
    vec2 sky = qt_TexCoord0 * vec2(aspect, 1.0);
    col += text.rgb * stars(sky, 70.0, 0.1) * 0.6 + accent.rgb * stars(sky + 3.7, 130.0, 0.08) * 0.35;
    // Névoa baixa, andando para o lado.
    float mist = fbm(vec2(p.x * 1.6 + time * 0.02, p.y * 3.0));
    col = mix(col, mix(surface.rgb, accent.rgb, 0.25), smoothstep(-0.05, -0.55, p.y) * smoothstep(0.35, 0.9, mist) * 0.55);
    fragColor = vec4(dither(col), 1.0) * qt_Opacity;
}
