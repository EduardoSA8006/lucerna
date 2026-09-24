// Trecho comum aos wallpapers animados (incluído por dev/shaders.sh antes de
// compilar). Todos recebem os mesmos uniforms: qualquer tema usa qualquer efeito.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;        // segundos de animação (só avança enquanto roda)
    vec2 resolution;   // tamanho desenhado, em pixels
    vec4 base;         // cores do tema ativo
    vec4 surface;
    vec4 accent;
    vec4 text;
};

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p = p * 2.03 + vec2(17.1, 9.2);
        a *= 0.5;
    }
    return v;
}

// Coordenadas centradas, com a proporção da tela (x de -aspect/2 a aspect/2)
// e o y para cima (no Qt, y = 0 é o alto da tela).
vec2 centered() {
    float aspect = resolution.x / max(resolution.y, 1.0);
    return vec2(qt_TexCoord0.x - 0.5, 0.5 - qt_TexCoord0.y) * vec2(aspect, 1.0);
}

// Estrelas que piscam devagar numa grade; `density` de 0 a 1.
float stars(vec2 uv, float scale, float density) {
    vec2 g = uv * scale;
    vec2 cell = floor(g);
    float h = hash(cell);
    if (h > density)
        return 0.0;
    vec2 pos = vec2(hash(cell + 3.1), hash(cell + 7.7));
    float d = length(fract(g) - pos);
    float twinkle = 0.55 + 0.45 * sin(time * (0.6 + h * 1.7) + h * 40.0);
    return smoothstep(0.08, 0.0, d) * twinkle;
}

// Gira o matiz de uma cor (em radianos): tira uma segunda cor do acento.
vec3 hueShift(vec3 c, float a) {
    const vec3 k = vec3(0.57735);
    float cosA = cos(a);
    return c * cosA + cross(k, c) * sin(a) + k * dot(k, c) * (1.0 - cosA);
}

// Pontilhado fino: some com as faixas nos degradês escuros.
vec3 dither(vec3 c) {
    return c + (hash(qt_TexCoord0 * resolution + fract(time)) - 0.5) / 255.0;
}
