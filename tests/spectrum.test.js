// Testes de services/Spectrum: a config gerada para o cava e a leitura de um
// quadro da saída crua.
function run(t) {
    const S = t.Spectrum;

    t.test("spectrum: a config do cava", () => {
        const lines = S.configFor(24, 60).split("\n");
        t.eq(lines.slice(0, 3), ["[general]", "bars = 24", "framerate = 60"]);
        for (const l of ["method = raw", "raw_target = /dev/stdout", "data_format = ascii", "ascii_max_range = 1000", "bar_delimiter = 59", "frame_delimiter = 10", "channels = mono"])
            t.check(lines.includes(l), l);
    });

    t.test("spectrum: um quadro em 0 a 1 por barra", () => {
        t.eq(S.parse("0;500;1000;", 3), [0, 0.5, 1], "com o ; do fim");
        t.eq(S.parse("250;750", 2), [0.25, 0.75], "sem o ; do fim");
        t.eq(S.parse("1200;-5;", 2), [1, 0], "fora da faixa, preso nas pontas");
    });

    t.test("spectrum: quadro incompleto ou inválido", () => {
        t.eq(S.parse("10;20;", 3), null, "barras faltando");
        t.eq(S.parse("10;x;30;", 3), null, "número inválido");
        t.eq(S.parse("", 3), null, "linha vazia");
    });

    t.test("spectrum: sem pedido, o cava não roda", () => {
        t.eq(S.active, false);
    });
}
