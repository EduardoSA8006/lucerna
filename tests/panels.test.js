// Testes de core/panels/Panels: modais, o acompanhante (dashboard), a base
// (settings) e a central pela entrada.
function run(t) {
    const P = t.Panels;
    const C = t.Config;
    const together0 = C.panelsTogether;
    C.panelsTogether = ["dashboard"];

    t.test("panels: tipos de painel", () => {
        t.check(P.isCompanion("dashboard"), "o dashboard acompanha");
        t.check(P.isModal("launcher") && P.isModal("themes") && P.isModal("central"), "launcher, themes e central são modais");
        t.check(!P.isModal("settings") && !P.isCompanion("settings"), "settings é a base");
        try {
            C.panelsTogether = ["dashboard", "sidebar"];
            t.check(!P.isCompanion("sidebar"), "um sidebar velho no config não acompanha");
        } finally {
            C.panelsTogether = ["dashboard"];
        }
    });

    t.test("panels: só os nomes de painel valem no IPC", () => {
        for (const n of ["launcher", "dashboard", "central", "settings", "themes", "power", "clipboard", "capture", "overview"])
            t.check(P.isPanel(n), n + " é painel");
        t.check(!P.isPanel("sidebar"), "o sidebar antigo não é painel");
        t.check(!P.isPanel(""), "nome vazio não é painel");
        t.check(!P.isPanel("Central"), "o nome tem de ser exato");
    });

    t.test("panels: modal fica sozinho", () => {
        P.close();
        P.open("dashboard");
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
        P.open("central");
        P.close();
        t.eq(P.opened, []);
        t.check(!P.anyOpen, "nada aberto");
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
            P.openCentral("microfone");
            t.eq(P.centralEntry, "microfone", "a entrada só do IPC");
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

    P.close();
    C.panelsTogether = together0;
}
