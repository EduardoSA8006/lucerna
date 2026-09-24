// Ondas: faixas de mar em camadas, como numa gravura japonesa, que sobem e
// descem devagar, com espuma nas cristas. (Kanagawa)
void main() {
    vec2 p = centered();
    float aspect = resolution.x / resolution.y;
    // Em tema claro, faixas em tons pastel do destaque e espuma branca; no
    // escuro, faixas escurecendo para a frente e espuma na cor do texto.
    float light = step(0.5, dot(base.rgb, vec3(0.299, 0.587, 0.114)));
    vec3 foamColor = mix(text.rgb, vec3(1.0), light);
    vec3 col = mix(base.rgb, surface.rgb, smoothstep(0.6, -0.2, p.y) * 0.4);
    // Sol pálido no alto.
    col += mix(accent.rgb, text.rgb, 0.4) * exp(-length(p - vec2(aspect * 0.22, 0.28)) * 7.0) * 0.35;
    // Camadas do fundo para a frente: mais escuras e mais baixas na frente.
    for (int i = 0; i < 4; i++) {
        float fi = float(i);
        float y = -0.05 - fi * 0.12;
        float amp = 0.03 + fi * 0.012;
        float freq = 3.0 + fi * 1.3;
        float wave = y + amp * sin(p.x * freq + time * (0.25 + fi * 0.07) + fi * 1.7)
                       + amp * 0.5 * sin(p.x * freq * 2.3 - time * 0.3 + fi);
        float body = smoothstep(wave + 0.004, wave - 0.004, p.y);
        vec3 tone = mix(mix(accent.rgb * 0.55 + base.rgb * 0.45, base.rgb * 0.8, fi / 3.0),
                        mix(base.rgb, accent.rgb, 0.1 + fi * 0.07), light);
        col = mix(col, tone, body);
        float foam = smoothstep(0.012, 0.0, abs(p.y - wave)) * (0.5 + 0.5 * noise(vec2(p.x * 30.0 + time, fi * 7.0)));
        col = mix(col, foamColor, foam * mix(0.35, 0.6, light) * (1.0 - fi * 0.2));
    }
    fragColor = vec4(dither(col), 1.0) * qt_Opacity;
}
