// Testes de core/shapes/BlobShapes: a mistura das duas curvas da bolha que
// muda de forma, o contorno em pontos e a sequência das formas.
function run(t) {
    const B = t.BlobShapes;
    const five = { lobes: 5, amplitude: 0.1 };
    const nine = { lobes: 9, amplitude: 0.04 };
    const angles = [0, 0.3, 1, 2.2, Math.PI, 5.5];
    // Dois contornos iguais ponto a ponto, a menos do arredondamento.
    const same = (p, q, message) => {
        t.eq(p.length, q.length, message);
        t.check(p.every((x, i) => Math.abs(x.x - q[i].x) < 1e-9 && Math.abs(x.y - q[i].y) < 1e-9), message);
    };

    t.test("blobshapes: a mistura nos extremos é uma forma só", () => {
        for (const a of angles) {
            t.near(B.factor(five, nine, 0, a), 1 + 0.1 * Math.cos(5 * a), 1e-12, `m=0 em ${a}`);
            t.near(B.factor(five, nine, 1, a), 1 + 0.04 * Math.cos(9 * a), 1e-12, `m=1 em ${a}`);
        }
    });

    t.test("blobshapes: no meio, a média das duas curvas", () => {
        for (const a of angles)
            t.near(B.factor(five, nine, 0.5, a), (B.factor(five, nine, 0, a) + B.factor(five, nine, 1, a)) / 2, 1e-12, `${a}`);
        t.near(B.factor(five, nine, 0.25, 0), 1 + 0.75 * 0.1 + 0.25 * 0.04, 1e-12, "um quarto do caminho");
    });

    t.test("blobshapes: contorno fechado, dentro da caixa e sem salto na troca", () => {
        const p = B.outline(100, 80, five, nine, 0.4, 72);
        t.eq(p.length, 73, "steps + 1 pontos");
        t.near(p[0].x, p[72].x, 1e-9, "fecha em x");
        t.near(p[0].y, p[72].y, 1e-9, "fecha em y");
        const far = Math.max(...p.map(q => Math.hypot(q.x - 50, q.y - 40)));
        t.check(far <= 40 + 1e-9, `cabe no menor lado: ${far}`);
        t.near(far, 40, 1e-9, "o maior lobo encosta na borda (cos = 1 em θ = 0)");
        // Trocar a forma: o fim de uma mistura (m=1 de A para B) é o começo da
        // próxima (m=0 de B para C).
        same(B.outline(64, 64, five, nine, 1, 36), B.outline(64, 64, nine, five, 0, 36), "fim de uma, começo da outra");
        same(B.outline(64, 64, five, five, 0.7, 36), B.outline(64, 64, five, five, 0, 36), "a mesma forma dos dois lados não mexe");
    });

    t.test("blobshapes: a lista de formas", () => {
        t.eq(B.shapes.map(s => s.lobes), [5, 6, 7, 9]);
        t.check(B.shapes.every(s => s.amplitude > 0 && s.amplitude < 0.15), "amplitudes pequenas");
        t.eq(new Set(B.shapes.map(s => s.amplitude)).size, B.shapes.length, "amplitudes variadas");
    });

    t.test("blobshapes: a próxima forma nunca repete a atual", () => {
        const n = B.shapes.length;
        for (let current = 0; current < n; current++) {
            const seen = new Set();
            for (let i = 0; i <= 20; i++) {
                const next = B.next(current, n, i / 20);
                t.check(next !== current && next >= 0 && next < n, `${current} → ${next} (rnd ${i / 20})`);
                seen.add(next);
            }
            t.eq(seen.size, n - 1, `de ${current}, todas as outras aparecem`);
        }
        t.eq([B.next(0, 2, 0), B.next(0, 2, 0.99), B.next(1, 2, 0.5)], [1, 1, 0], "com duas, alterna");
        t.eq([B.next(0, 1, 0.5), B.next(0, 0, 0.5)], [0, 0], "uma ou nenhuma: fica");
    });
}
