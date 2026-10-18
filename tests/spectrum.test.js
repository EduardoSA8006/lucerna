// Testes de services/Spectrum (a escala, as falhas e o recuo do reinício) e
// do backend services/spectrum/Cava (a config gerada e a leitura de um quadro).
function run(t) {
    const S = t.Spectrum;

    t.test("spectrum: a escala de quem olha", () => {
        t.eq(S.shape([0, 0.25, 1]), [0, 0.5, 1], "a raiz realça as faixas fracas");
        t.eq(S.shape([-1, 2, "x"]), [0, 1, 0], "fora da faixa ou inválido, preso");
        t.eq([S.shape([]), S.shape(null)], [[], []]);
    });

    t.test("spectrum: as falhas seguidas", () => {
        t.eq([S.failuresAfter(0, false), S.failuresAfter(2, false)], [1, 3], "saiu sem quadro: soma");
        t.eq(S.failuresAfter(3, true), 1, "rodou e caiu: recomeça a conta");
    });

    t.test("spectrum: o recuo do reinício", () => {
        t.eq([1, 2, 3].map(f => S.retryDelay(f, 4)), [1000, 2000, 4000], "1, 2, 4 s");
        t.eq([S.retryDelay(4, 4), S.retryDelay(9, 4)], [-1, -1], "na quarta seguida, desiste");
        t.eq(S.retryDelay(0, 4), 1000);
    });

    t.test("spectrum: parado, sem quadro velho", () => {
        t.eq([S.active, S.values], [false, []]);
    });

    const cava = t.cava();

    t.test("cava: a config gerada", () => {
        const lines = cava.configFor(24, 30).split("\n");
        t.eq(lines.slice(0, 3), ["[general]", "bars = 24", "framerate = 30"]);
        for (const l of ["method = raw", "raw_target = /dev/stdout", "data_format = ascii", "ascii_max_range = 1000", "bar_delimiter = 59", "frame_delimiter = 10", "channels = mono"])
            t.check(lines.includes(l), l);
    });

    t.test("cava: um quadro em 0 a 1 por barra", () => {
        t.eq(cava.parse("0;500;1000;", 3), [0, 0.5, 1], "com o ; do fim");
        t.eq(cava.parse("250;750", 2), [0.25, 0.75], "sem o ; do fim");
        t.eq(cava.parse("1200;-5;", 2), [1, 0], "fora da faixa, preso nas pontas");
    });

    t.test("cava: quadro incompleto ou inválido", () => {
        t.eq(cava.parse("10;20;", 3), null, "barras faltando");
        t.eq(cava.parse("10;x;30;", 3), null, "número inválido");
        t.eq(cava.parse("", 3), null, "linha vazia");
    });

    cava.destroy();
}
