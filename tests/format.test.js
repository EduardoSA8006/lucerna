// Testes de core/format/Format: números, tamanhos e tempos em pt-BR.
function run(t) {
    const F = t.Format;

    t.test("format: número com vírgula decimal", () => {
        t.eq(F.number(3.14159, 2), "3,14");
        t.eq(F.number(2, 0), "2");
    });

    t.test("format: porcentagem arredondada", () => {
        t.eq(F.percent(0.426), "43%");
        t.eq(F.percent(1), "100%");
    });

    t.test("format: bytes em B, KiB, GiB", () => {
        t.eq(F.bytes(512), "512 B");
        t.eq(F.bytes(1536), "1,5 KiB");
        t.eq(F.bytes(150 * 1024), "150 KiB");
        t.eq(F.bytes(3 * 1024 * 1024 * 1024), "3,0 GiB");
    });

    t.test("format: taxa por segundo", () => {
        t.eq(F.rate(2048), "2,0 KiB/s");
    });

    t.test("format: duração em dias, horas e minutos", () => {
        t.eq(F.duration(3725), "1 h 2 min");
        t.eq(F.duration(90000), "1 d 1 h");
        t.eq(F.duration(59), "0 min");
    });

    t.test("format: relógio de mídia", () => {
        t.eq(F.clock(83), "1:23");
        t.eq(F.clock(600), "10:00");
        t.eq(F.clock(-5), "0:00");
        t.eq(F.clock(NaN), "0:00");
    });

    t.test("format: há quanto tempo, com datas fixas", () => {
        const now = new Date(2026, 0, 10, 12, 0);
        t.eq(F.since(new Date(2026, 0, 10, 11, 59, 30), now), "agora");
        t.eq(F.since(new Date(2026, 0, 10, 11, 55), now), "há 5 min");
        t.eq(F.since(new Date(2026, 0, 10, 9, 5), now), "09:05");
        t.eq(F.since(new Date(2026, 0, 9, 23, 0), new Date(2026, 0, 10, 0, 30)), "09/01");
    });

    t.test("format: primeira letra maiúscula", () => {
        t.eq(F.capitalize("olá mundo"), "Olá mundo");
        t.eq(F.capitalize(""), "");
    });
}
