// Chama: um único brilho âmbar, como a chama de uma lamparina, que respira e
// tremula devagar no escuro. (Lamparina)
void main() {
    vec2 p = centered();
    float t = time * 0.35;
    // A chama fica um pouco abaixo do centro e ondula para os lados.
    vec2 c = vec2(0.0, -0.18);
    vec2 q = p - c;
    q.x += (fbm(vec2(q.y * 3.0 - t, t * 0.3)) - 0.5) * 0.18 * smoothstep(-0.1, 0.6, q.y);
    float flame = exp(-length(q * vec2(2.4, 1.1)) * 3.2);
    float breathe = 0.82 + 0.1 * sin(time * 0.9) + 0.08 * noise(vec2(time * 1.7, 0.0));
    vec3 col = base.rgb;
    col += accent.rgb * flame * 0.55 * breathe;
    // Halo largo e fumaça sutil.
    col += accent.rgb * exp(-length(p - c) * 1.3) * 0.12 * breathe;
    float smoke = fbm(p * 2.0 + vec2(0.0, -time * 0.04));
    col = mix(col, surface.rgb, smoothstep(0.55, 1.0, smoke) * 0.25);
    fragColor = vec4(dither(col), 1.0) * qt_Opacity;
}
