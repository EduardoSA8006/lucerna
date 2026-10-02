// Testes da central (features/central/state): o que cada entrada abre e a
// volta ao estado inicial; as Tarefas 3 e 5 acrescentam os botões dos
// controles e o que some no painel de energia. Abre pelo Panels, como a barra
// e os atalhos; cada caso fecha a central e devolve os painéis abertos ao que
// eram.
function run(t) {
    const S = t.CentralState;
    const P = t.Panels;
    const opened0 = P.opened;

    // Roda o corpo e, mesmo com exceção, fecha e restaura os painéis.
    function scenario(name, body) {
        t.test(name, () => {
            try {
                body();
            } finally {
                P.close();
                P.opened = opened0;
            }
        });
    }

    t.test("central: a página de cada entrada", () => {
        t.eq([S.pageFor("rede", true), S.pageFor("rede", false)], ["wifi", ""], "sem placa Wi-Fi (desktop com cabo), sem subpágina");
        t.eq([S.pageFor("bluetooth", true), S.pageFor("bluetooth", false)], ["bluetooth", "bluetooth"]);
        t.eq(["som", "notificacoes", "energia", ""].map(e => S.pageFor(e, true)), ["", "", "", ""]);
    });

    scenario("central: a entrada escolhe a página dos controles", () => {
        P.openCentral("rede");
        t.eq([S.open, S.entry, S.controlsPage, S.soundPage], [true, "rede", S.hasWifi ? "wifi" : "", ""], "a lista de redes, se houver placa Wi-Fi");
        P.openCentral("bluetooth");
        t.eq([S.entry, S.controlsPage], ["bluetooth", "bluetooth"], "outra entrada com a central aberta");
        for (const entry of ["som", "notificacoes", "energia", ""]) {
            P.openCentral(entry);
            t.eq(S.controlsPage, "", `entrada "${entry}": o estado inicial`);
        }
    });

    scenario("central: entrada desconhecida abre o estado inicial", () => {
        P.openCentral("wifi");
        t.eq([S.open, S.entry, S.controlsPage], [true, "", ""], "o nome antigo do IPC");
    });

    scenario("central: fechar volta ao estado inicial", () => {
        P.openCentral("rede");
        S.setSoundPage("outputs");
        P.toggleCentral("rede");
        t.eq([S.open, S.entry, S.controlsPage, S.soundPage], [false, "", "", ""]);
        P.open("central");
        t.eq([S.open, S.entry, S.controlsPage, S.soundPage], [true, "", "", ""], "aberta sem entrada (panels open central)");
    });

    scenario("central: trocar de entrada fecha as páginas", () => {
        P.openCentral("som");
        S.setSoundPage("inputs");
        S.setControlsPage("bluetooth");
        P.openCentral("notificacoes");
        t.eq([S.controlsPage, S.soundPage], ["", ""]);
    });

    scenario("central: outro painel fecha a central e esquece a página", () => {
        P.openCentral("rede");
        P.open("launcher");
        t.eq([S.open, S.controlsPage, S.entry], [false, "", ""]);
        P.openCentral("");
        t.eq(S.controlsPage, "", "reaberta, começa do zero");
    });
}
