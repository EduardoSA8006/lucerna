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

    t.test("panels: faixa da barra que fica clicável", () => {
        const T = t.ThemeManager;
        const hide0 = C.barAutoHide;
        const style0 = C.barStyle;
        try {
            C.barAutoHide = false;
            C.barStyle = "strip";
            t.eq(P.barStrip, T.barHeight, "em faixa: a altura da barra");
            C.barStyle = "island";
            t.eq(P.barStrip, T.barHeight + T.spacing.small, "flutuante: a barra e a folga de cima");
            C.barAutoHide = true;
            t.eq(P.barStrip, 0, "escondida sozinha: nenhuma");
        } finally {
            C.barAutoHide = hide0;
            C.barStyle = style0;
        }
    });

    t.test("panels: central pela entrada", () => {
        P.close();
        try {
            P.openCentral("rede");
            t.eq([P.opened, P.centralEntry], [["central"], "rede"]);
            P.openCentral("som");
            t.eq([P.opened, P.centralEntry], [["central"], "som"], "outra entrada troca, aberta");
            P.openCentral("sound");
            t.eq(P.centralEntry, "", "entrada desconhecida vale como a vazia");
            P.close();
            t.eq(P.centralEntry, "", "fechada, esquece a entrada");
        } finally {
            P.close();
        }
    });

    t.test("panels: alternar a central", () => {
        try {
            P.toggleCentral("notificacoes");
            t.eq([P.isOpen("central"), P.centralEntry], [true, "notificacoes"]);
            P.toggleCentral("rede");
            t.eq([P.isOpen("central"), P.centralEntry], [true, "rede"], "outra entrada troca");
            P.toggleCentral("rede");
            t.eq([P.isOpen("central"), P.centralEntry], [false, ""], "a mesma entrada fecha");
            P.toggleCentral("");
            t.eq([P.isOpen("central"), P.centralEntry], [true, ""], "o atalho abre no estado inicial");
            P.toggleCentral("som");
            t.eq(P.centralEntry, "som");
            P.toggleCentral("");
            t.eq(P.isOpen("central"), false, "o atalho fecha de qualquer entrada");
        } finally {
            P.close();
        }
    });

    t.test("panels: a central é modal", () => {
        try {
            P.open("dashboard");
            P.openCentral("som");
            t.eq(P.opened, ["central"], "fecha o painel superior");
            P.open("dashboard");
            t.eq([P.opened, P.centralEntry], [["dashboard"], ""], "o painel superior fecha a central");
            P.open("settings");
            P.openCentral("");
            t.eq(P.opened, ["central"], "fecha as configurações");
            P.open("launcher");
            t.eq(P.opened, ["launcher"], "o launcher fecha a central");
        } finally {
            P.close();
        }
    });

    t.test("panels: aviso de abertura da central", () => {
        const got = [];
        const listen = entry => got.push(entry);
        P.centralOpened.connect(listen);
        try {
            P.openCentral("bluetooth");
            P.openCentral("wifi");
            P.toggleCentral("bluetooth");
        } finally {
            P.centralOpened.disconnect(listen);
            P.close();
        }
        t.eq(got, ["bluetooth", "", "bluetooth"], "uma vez por abertura ou troca, com a entrada que valeu");
    });

    t.test("panels: janelas registradas", () => {
        const w = t.object();
        P.register(w);
        t.check(P.surfaces.includes(w), "registrada");
        P.unregister(w);
        t.check(!P.surfaces.includes(w), "fora");
    });
}
