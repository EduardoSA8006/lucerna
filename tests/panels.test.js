// Testes de core/panels/Panels: modais, acompanhantes e a base (settings).
function run(t) {
    const P = t.Panels;
    const C = t.Config;
    C.panelsTogether = ["dashboard", "sidebar"];

    t.test("panels: tipos de painel", () => {
        t.check(P.isCompanion("dashboard") && P.isCompanion("sidebar"), "dashboard e sidebar acompanham");
        t.check(P.isModal("launcher") && P.isModal("themes"), "launcher e themes são modais");
        t.check(!P.isModal("settings") && !P.isCompanion("settings"), "settings é a base");
    });

    t.test("panels: modal fica sozinho, acompanhantes juntos", () => {
        P.close();
        P.open("dashboard");
        P.open("sidebar");
        t.eq(P.opened, ["dashboard", "sidebar"]);
        P.open("launcher");
        t.eq(P.opened, ["launcher"], "o modal fecha os outros");
        P.open("dashboard");
        t.eq(P.opened, ["dashboard"], "o acompanhante fecha o modal");
        t.eq(P.current, "dashboard");
    });

    t.test("panels: acompanhante abre por cima da base", () => {
        P.open("settings");
        t.eq(P.opened, ["settings"]);
        P.open("dashboard");
        t.eq(P.opened, ["settings", "dashboard"]);
        t.check(P.isOpen("settings") && P.isOpen("dashboard"), "os dois abertos");
    });

    t.test("panels: fechar um, alternar e fechar todos", () => {
        P.dismiss("settings");
        t.eq(P.opened, ["dashboard"]);
        t.check(P.lastDisturb > 0, "dispensar marca a perturbação do grab");
        P.toggle("launcher");
        t.eq(P.opened, ["launcher"]);
        P.toggle("launcher");
        t.eq(P.opened, []);
        P.open("sidebar");
        P.close();
        t.eq(P.opened, []);
        t.check(!P.anyOpen, "nada aberto");
    });

    t.test("panels: central lateral numa seção", () => {
        P.openSidebar("sound");
        t.eq([C.sidebarSection, P.isOpen("sidebar")], ["sound", true]);
        P.toggleSidebar("wifi");
        t.eq([C.sidebarSection, P.isOpen("sidebar")], ["wifi", true], "outra seção troca");
        P.toggleSidebar("wifi");
        t.eq(P.isOpen("sidebar"), false, "a mesma seção fecha");
        P.disturb();
        C.sidebarSection = "wifi";
    });

    t.test("panels: janelas registradas", () => {
        const w = t.object();
        P.register(w);
        t.check(P.surfaces.includes(w), "registrada");
        P.unregister(w);
        t.check(!P.surfaces.includes(w), "fora");
    });
}
