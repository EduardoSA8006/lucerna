// Testes de services/Input: o Lua gerado e o keymap remapeado (texto puro,
// sem hyprctl nem xkbcli). O keymap de exemplo usa espaços no lugar de tabs.
function run(t) {
    const I = t.Input;
    const keymap = [
        "xkb_keymap {",
        "xkb_keycodes \"evdev\" {",
        "    <ESC> = 9;",
        "    <CAPS> = 66;",
        "    <LCTL> = 37;",
        "};",
        "xkb_types \"complete\" {",
        "};",
        "xkb_symbols \"pc+us\" {",
        "    key <ESC> { [ Escape ] };",
        "    key <CAPS> { type= \"ONE_LEVEL\", symbols[1]= [ Caps_Lock ] };",
        "    key <LCTL> { [ Control_L ] };",
        "    modifier_map Lock { <CAPS> };",
        "    modifier_map Control { <LCTL> };",
        "};",
        "};",
        ""
    ].join("\n");

    // I.parseKeymap() não é pura: grava keyNames/keySymbols no singleton.
    // Guarda o estado de antes para restaurar no fim (a suíte roda no mesmo
    // processo que as seguintes).
    const originalKeyNames = I.keyNames;
    const originalKeySymbols = I.keySymbols;

    t.test("input: opção lida do Hyprland", () => {
        I.options = { "input.sensitivity": { value: 0.5, set: true } };
        t.eq(I.option("input.sensitivity"), 0.5);
        t.check(I.option("nada") === undefined, "opção que não existe");
        I.options = {};
    });

    t.test("input: string Lua escapada", () => {
        t.eq(I.luaString('a"b\\c\nd'), '"a\\"b\\\\c\\nd"');
    });

    t.test("input: valores Lua", () => {
        t.eq([I.luaValue(true), I.luaValue(3), I.luaValue("x")], ["true", "3", '"x"']);
        t.eq(I.luaValue(["a", 1]), '{ "a", 1 }');
        t.eq(I.luaValue({ input: { kb_layout: "br" } }), '{ input = { kb_layout = "br" } }');
        t.eq(I.luaValue({ "a-b": 1 }), '{ ["a-b"] = 1 }');
    });

    t.test("input: opções com ponto viram tabelas aninhadas", () => {
        t.eq(I.nest({ "input.touchpad.tap_to_click": true, "input.sensitivity": 0.2 }), { input: { touchpad: { tap_to_click: true }, sensitivity: 0.2 } });
    });

    t.test("input: binds e unbinds", () => {
        t.eq(I.unbindLua([{ key: "SUPER + d" }, { key: "ALT + q" }]), 'hl.unbind("SUPER + d")\nhl.unbind("ALT + q")');
        t.eq(I.bindLua([{ key: "SUPER + d", lua: "hl.dsp.exit()", repeating: true, locked: true }, { key: "ALT + q", lua: "x()" }]),
             'hl.bind("SUPER + d", hl.dsp.exit(), { repeating = true, locked = true })\nhl.bind("ALT + q", x())');
    });

    t.test("input: nomes e símbolos das teclas do keymap", () => {
        I.parseKeymap(keymap);
        t.eq(I.keyNames, { 9: "ESC", 37: "LCTL", 66: "CAPS" });
        t.eq(I.keySymbols, { ESC: "Escape", CAPS: "Caps_Lock", LCTL: "Control_L" });
    });

    t.test("input: bloco de uma tecla", () => {
        t.eq(I.keyBlock(keymap, "CAPS").text.trim(), 'key <CAPS> { type= "ONE_LEVEL", symbols[1]= [ Caps_Lock ] };');
        t.eq(I.keyBlock(keymap, "NADA"), null);
    });

    t.test("input: remapear Caps Lock para Esc", () => {
        const out = I.patchKeymap(keymap, [{ from: "CAPS", to: { kind: "key", value: "ESC" } }]);
        t.check(out.includes("key <CAPS> { [ Escape ] };"), "Caps copia o Esc");
        t.check(!out.includes("Caps_Lock"), "o bloco antigo saiu");
        t.check(!out.includes("modifier_map Lock"), "Caps saiu do Lock");
        t.check(out.includes("modifier_map Control { <LCTL> };"), "o resto dos modificadores fica");
        t.check(out.startsWith("xkb_keymap {\nxkb_keycodes"), "o começo do keymap fica igual");
    });

    t.test("input: remapear para um modificador leva o modifier_map junto", () => {
        const out = I.patchKeymap(keymap, [{ from: "CAPS", to: { kind: "key", value: "LCTL" } }]);
        t.check(out.includes("key <CAPS> { [ Control_L ] };"), out);
        t.check(out.includes("modifier_map Control { <CAPS> };"), out);
    });

    t.test("input: remapear para um símbolo ou para nada", () => {
        const sym = I.patchKeymap(keymap, [{ from: "CAPS", to: { kind: "sym", value: "XF86AudioPlay" } }]);
        t.check(sym.includes('key <CAPS> { type= "ONE_LEVEL", symbols[1]= [ XF86AudioPlay ] };'), sym);
        const none = I.patchKeymap(keymap, [{ from: "CAPS", to: { kind: "none" } }]);
        t.check(none.includes('key <CAPS> { type= "ONE_LEVEL", symbols[1]= [ NoSymbol ] };'), none);
    });

    I.keyNames = originalKeyNames;
    I.keySymbols = originalKeySymbols;

    t.test("input: estado original restaurado", () => {
        t.eq([I.keyNames, I.keySymbols], [originalKeyNames, originalKeySymbols]);
    });
}
