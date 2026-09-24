// Chuva digital: colunas de caracteres (blocos) caindo em velocidades
// diferentes, a cabeça clara e a cauda sumindo. (Decay Green)
void main() {
    float aspect = resolution.x / resolution.y;
    vec2 uv = qt_TexCoord0;
    float columns = 90.0;
    float rows = columns / aspect * 0.55;
    vec2 g = vec2(uv.x * columns, uv.y * rows);
    vec2 cell = floor(g);
    float h = hash(vec2(cell.x, 3.3));
    float speed = 2.0 + h * 5.0;
    float head = fract(time * speed / rows * 0.9 + h * 7.0) * (rows + 18.0);
    float dist = head - cell.y;
    float trail = dist > 0.0 ? exp(-dist * 0.18) : 0.0;
    // "Caractere": um bloco que muda de tempos em tempos.
    vec2 f = fract(g);
    float glyph = step(0.35, hash(cell + floor(time * (1.0 + h * 3.0))));
    float shape = step(0.15, f.x) * step(f.x, 0.85) * step(0.1, f.y) * step(f.y, 0.9) * glyph;
    vec3 col = base.rgb;
    col += accent.rgb * shape * trail * 0.55;
    col += mix(accent.rgb, text.rgb, 0.6) * shape * smoothstep(1.5, 0.0, abs(dist)) * 0.5;
    col = mix(col, base.rgb, smoothstep(0.35, 0.95, length(centered())) * 0.45);
    fragColor = vec4(dither(col), 1.0) * qt_Opacity;
}
