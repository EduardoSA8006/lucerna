// Testes de core/input/ShellShortcuts: padrões e comparação de combinações.
function run(t) {
    const S = t.ShellShortcuts;

    t.test("shellshortcuts: sem mudanças, tudo vem dos padrões", () => {
        const list = S.effective({});
        t.eq(list.length, S.defaults.length);
        t.check(list.every(s => !s.custom), "nenhum custom");
        t.eq(list[0], { id: "launcher", keys: [{ mods: "SUPER", trigger: "space" }], custom: false });
    });

    t.test("shellshortcuts: a mudança do usuário vale, até lista vazia", () => {
        const list = S.effective({ launcher: [], lock: [{ mods: "ALT", trigger: "l" }] });
        t.eq(list.find(s => s.id === "launcher"), { id: "launcher", keys: [], custom: true });
        t.eq(list.find(s => s.id === "lock").keys, [{ mods: "ALT", trigger: "l" }]);
    });

    t.test("shellshortcuts: a tecla salva no nome antigo (sidebar) vale na central", () => {
        const old = [{ mods: "SUPER SHIFT", trigger: "c" }];
        t.eq(S.effective({ sidebar: old }).find(s => s.id === "central"), { id: "central", keys: old, custom: true });
        t.eq(S.effective({ sidebar: old, central: [] }).find(s => s.id === "central").keys, [], "a do nome novo vence");
        t.eq(S.effective({}).find(s => s.id === "central").keys, [{ mods: S.mod, trigger: "c" }]);
        t.check(!S.effective({ sidebar: old }).some(s => s.id === "sidebar"), "o nome antigo não vira atalho");
    });

    t.test("shellshortcuts: teclas padrão de uma ação", () => {
        t.eq(S.defaultKeys("capture-screen"), [{ mods: "SHIFT", trigger: "Print" }]);
        t.eq(S.defaultKeys("nada"), []);
    });

    t.test("shellshortcuts: modificadores em ordem fixa", () => {
        t.eq(S.normalizeMods("shift+super"), "SUPER SHIFT");
        t.eq(S.normalizeMods("ALT CTRL"), "CTRL ALT");
        t.eq(S.normalizeMods("  "), "");
    });

    t.test("shellshortcuts: mesma combinação, escrita de outro jeito", () => {
        t.check(S.same({ mods: "SHIFT SUPER", trigger: "Q" }, { mods: "SUPER+SHIFT", trigger: "q" }), "iguais");
        t.check(!S.same({ mods: "SUPER", trigger: "q" }, { mods: "SUPER", trigger: "w" }), "outra tecla");
        t.check(!S.same({ mods: "SUPER", trigger: "q" }, { mods: "ALT", trigger: "q" }), "outro modificador");
    });

    t.test("shellshortcuts: tecla do Hyprland e máscara de modificadores", () => {
        t.eq(S.fromKey("SUPER + SHIFT + q"), { mods: "SUPER SHIFT", trigger: "q" });
        t.eq(S.fromKey("Print"), { mods: "", trigger: "Print" });
        t.eq(S.modsFromMask(64 | 1), "SUPER SHIFT");
        t.eq(S.modsFromMask(4 | 8), "CTRL ALT");
        t.eq(S.modsFromMask(0), "");
    });
}
