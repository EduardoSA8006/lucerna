// Testes de services/Brightness: a leitura do brightnessctl -m.
function run(t) {
    const B = t.Brightness;

    // B.parse() não é pura: grava device/value/available no singleton
    // quando reconhece a linha. Guarda o estado de antes para restaurar
    // no fim (a suíte roda no mesmo processo que as seguintes).
    const original = { device: B.device, value: B.value, available: B.available };

    t.test("brightness: linha do brightnessctl", () => {
        t.check(B.parse("intel_backlight,backlight,19200,40%,48000\n"), "reconhece");
        t.eq([B.device, B.available], ["intel_backlight", true]);
        t.near(B.value, 0.4, 1e-9);
        t.eq(B.screens[0].id, "backlight");
    });

    t.test("brightness: saída que não é de backlight", () => {
        t.check(!B.parse(""), "vazio");
        t.check(!B.parse("ddcci15,display,1,50%,100"), "outra classe");
        t.check(!B.parse("a,backlight,1"), "campos de menos");
    });

    B.device = original.device;
    B.value = original.value;
    B.available = original.available;

    t.test("brightness: estado original restaurado", () => {
        t.eq([B.device, B.value, B.available], [original.device, original.value, original.available]);
    });
}
