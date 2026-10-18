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

    t.test("format: usado / total na unidade do total", () => {
        const gib = 1024 * 1024 * 1024;
        t.eq(F.usage(9.7 * gib, 31.1 * gib), "9,7 / 31,1 GiB");
        t.eq(F.usage(454 * gib, 915 * gib), "454 / 915 GiB");
        t.eq(F.usage(4.83 * gib, 224 * gib), "4,8 / 224 GiB", "casas de cada número");
        t.eq(F.usage(47.6 * gib, 915 * gib), "47,6 / 915 GiB");
        t.eq(F.usage(512 * 1024 * 1024, 2 * gib), "0,5 / 2,0 GiB");
        t.eq(F.usage(50 * gib, 99.97 * gib), "50,0 / 100 GiB", "logo abaixo de 100: sem \"100,0\"");
        t.eq(F.usage(500 * gib, 1010 * gib), "0,5 / 1,0 TiB", "de 1000 a 1023: a unidade de cima");
        t.eq(F.usage(0, 0), "0 / 0 B");
    });

    t.test("format: unidade e casas decimais", () => {
        t.eq([F.unitIndex(999), F.unitIndex(1000), F.unitIndex(1023 * 1024), F.unitIndex(Math.pow(1024, 6))], [0, 1, 2, 4]);
        t.eq([F.decimals(5, 0), F.decimals(5, 1), F.decimals(99.94, 1), F.decimals(99.95, 1), F.decimals(150, 1)], [0, 1, 1, 0, 0]);
        t.eq(F.bytes(99.97 * 1024), "100 KiB", "sem \"100,0\"");
        t.eq(F.bytes(1010 * 1024 * 1024), "1,0 GiB", "sem \"1010 MiB\"");
        t.eq(F.bytes(1000), "1,0 KiB");
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
