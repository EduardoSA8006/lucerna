// Testes de core/time/Sun: nascer e pôr do sol com datas fixas, no fuso de
// São Paulo (o ci/unit.sh fixa TZ=America/Sao_Paulo).
function run(t) {
    t.test("ambiente: fuso de São Paulo (UTC−3, sem horário de verão)", () => {
        t.eq(new Date(2026, 0, 1).getTimezoneOffset(), 180, "rode pelo ci/unit.sh, que fixa TZ=America/Sao_Paulo");
        t.eq(new Date(2026, 6, 1).getTimezoneOffset(), 180, "julho também em UTC−3");
    });

    t.test("sun: São Paulo no solstício de junho", () => {
        const s = t.Sun.times(new Date(2026, 5, 21, 12, 0), -23.55, -46.63);
        t.near(s.sunrise, 407.4, 2, "nascer por volta de 06:47");
        t.near(s.sunset, 1048.3, 2, "pôr por volta de 17:28");
    });

    t.test("sun: São Paulo no solstício de dezembro", () => {
        const s = t.Sun.times(new Date(2026, 11, 21, 12, 0), -23.55, -46.63);
        t.near(s.sunrise, 316.8, 2, "nascer por volta de 05:17");
        t.near(s.sunset, 1131.9, 2, "pôr por volta de 18:52");
    });

    t.test("sun: equador no equinócio, na longitude 0", () => {
        const s = t.Sun.times(new Date(2026, 2, 20), 0, 0);
        t.near(s.sunrise, 184.8, 2, "06:00 UTC são 03:05 em São Paulo");
        t.near(s.sunset, 911.5, 2, "pôr");
    });

    t.test("sun: dia polar em Svalbard em junho", () => {
        t.eq(t.Sun.times(new Date(2026, 5, 21), 78.22, 15.65), { polar: "day" });
    });

    t.test("sun: noite polar em Svalbard em dezembro", () => {
        t.eq(t.Sun.times(new Date(2026, 11, 21), 78.22, 15.65), { polar: "night" });
    });

    t.test("sun: horários sempre entre 0 e 1440 minutos", () => {
        for (const lon of [-179, -90, 0, 90, 179]) {
            const s = t.Sun.times(new Date(2026, 3, 1), 10, lon);
            t.check(s.sunrise >= 0 && s.sunrise < 1440 && s.sunset >= 0 && s.sunset < 1440, `longitude ${lon}: ${JSON.stringify(s)}`);
        }
    });
}
