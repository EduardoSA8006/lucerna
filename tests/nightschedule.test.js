// Testes de core/nightlight/NightSchedule: horário fixo, pôr do sol, rampa,
// virada à meia-noite e "até a próxima virada". Datas fixas.
function run(t) {
    const N = t.NightSchedule;
    const C = t.Config;
    const fixed = { start: 1200, end: 390 }; // 20:00 → 06:30

    t.test("nightschedule: horas e minutos", () => {
        t.eq(N.toMinutes("07:30"), 450);
        t.eq(N.toMinutes("25:00"), 60);
        t.eq(N.toMinutes("x"), 0);
        t.eq(N.clock(450), "07:30");
        t.eq(N.clock(1439.6), "00:00");
    });

    t.test("nightschedule: horário fixo", () => {
        t.eq(N.nightFor("custom", null, "20:00", "06:30"), fixed);
    });

    t.test("nightschedule: pôr do sol, e o de/até sem cidade", () => {
        t.eq(N.nightFor("sun", { sunrise: 407.4, sunset: 1048.3 }, "20:00", "06:30"), { start: 1048.3, end: 407.4 });
        t.eq(N.nightFor("sun", null, "20:00", "06:30"), fixed);
    });

    t.test("nightschedule: dia e noite polares, e sempre", () => {
        t.eq(N.nightFor("sun", { polar: "day" }, "20:00", "06:30"), { never: true });
        t.eq(N.nightFor("sun", { polar: "night" }, "20:00", "06:30"), { always: true });
        t.eq(N.nightFor("always", null, "20:00", "06:30"), { always: true });
    });

    t.test("nightschedule: rampa de 30 min na entrada e na saída", () => {
        t.eq(N.factorAt(fixed, 1200), 0);
        t.near(N.factorAt(fixed, 1215), 0.5, 1e-9, "meio da entrada");
        t.eq(N.factorAt(fixed, 1230), 1);
        t.near(N.factorAt(fixed, 375), 0.5, 1e-9, "meio da saída");
        t.eq(N.factorAt(fixed, 390), 0);
        t.eq(N.factorAt(fixed, 720), 0);
    });

    t.test("nightschedule: virada à meia-noite", () => {
        t.eq(N.factorAt(fixed, 1439), 1);
        t.eq(N.factorAt(fixed, 0), 1);
        const at = new Date(2026, 0, 10, 23, 59).getTime();
        t.eq(N.nextChangeAt(fixed, 1439, at), new Date(2026, 0, 11, 6, 30).getTime());
    });

    t.test("nightschedule: sempre, nunca, noite vazia e noite curta", () => {
        t.eq(N.factorAt({ always: true }, 720), 1);
        t.eq(N.factorAt({ never: true }, 0), 0);
        t.eq(N.factorAt({ start: 600, end: 600 }, 600), 0);
        t.eq(N.factorAt({ start: 600, end: 640 }, 620), 1);
        t.near(N.factorAt({ start: 600, end: 640 }, 610), 0.5, 1e-9, "rampa de 20 min numa noite de 40");
    });

    t.test("nightschedule: até a próxima virada", () => {
        const noon = new Date(2026, 0, 10, 12, 0).getTime();
        t.eq(N.nextChangeAt(fixed, 720, noon), new Date(2026, 0, 10, 20, 0).getTime());
        const night = new Date(2026, 0, 11, 2, 0).getTime();
        t.eq(N.nextChangeAt(fixed, 120, night), new Date(2026, 0, 11, 6, 30).getTime());
        t.eq(N.nextChangeAt({ always: true }, 0, noon), 0);
    });

    function setup() {
        C.nightLightEnabled = true;
        C.nightLightSchedule = "custom";
        C.nightLightFrom = "20:00";
        C.nightLightTo = "06:30";
        C.nightLightOverride = null;
        N.now = new Date(2026, 0, 10, 12, 0).getTime();
    }

    t.test("nightschedule: ligar à mão vale até a próxima virada", () => {
        setup();
        t.eq(N.status, "Liga às 20:00");
        N.setOn(true);
        t.eq(C.nightLightOverride, { on: true, until: new Date(2026, 0, 10, 20, 0).getTime() });
        t.eq(N.factor, 1);
        t.eq(N.status, "Ligada até 20:00");
        N.setOn(false);
        t.eq(C.nightLightOverride, null, "desligar de dia volta ao horário");
    });

    t.test("nightschedule: desligada, ligar à mão liga a função", () => {
        setup();
        C.nightLightEnabled = false;
        N.setOn(false);
        t.eq(C.nightLightEnabled, false, "desligar o que já está desligado não muda nada");
        N.setOn(true);
        t.eq(C.nightLightEnabled, true);
        t.eq(C.nightLightOverride.on, true);
    });

    t.test("nightschedule: em sempre, desligar desliga a função", () => {
        setup();
        C.nightLightSchedule = "always";
        N.setOn(false);
        t.eq(C.nightLightEnabled, false);
    });

    t.test("nightschedule: prévia da temperatura", () => {
        N.preview();
        t.check(N.previewing, "previewing ligado");
        N.previewing = false;
    });

    C.nightLightEnabled = false;
    C.nightLightSchedule = "sun";
    C.nightLightOverride = null;
}
