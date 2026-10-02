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

    scenario("central: a reabertura começa do zero", () => {
        P.openCentral("rede");
        S.setControlsPage("bluetooth");
        S.setSoundPage("outputs");
        P.toggleCentral("rede");
        t.eq([S.open, S.entry, S.controlsPage, S.soundPage], [false, "", "bluetooth", "outputs"], "na saída, as páginas ficam até o painel sumir");
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
        S.setControlsPage("bluetooth");
        P.open("launcher");
        t.eq([S.open, S.entry], [false, ""]);
        P.openCentral("");
        t.eq(S.controlsPage, "", "reaberta, começa do zero");
    });

    const K = t.ControlsState;
    const C = t.Config;

    t.test("controles: botões de ícone", () => {
        const dnd0 = C.doNotDisturb;
        const idle0 = C.idleEnabled;
        const awake0 = C.idleInhibit;
        // A luz noturna depende do hyprsunset da máquina; fica fora da conta.
        const ids = () => K.toggles.map(b => b.id).filter(id => id !== "nightlight");
        const checked = id => K.toggles.find(b => b.id === id)?.checked;
        try {
            C.idleEnabled = false;
            t.eq(ids(), ["dnd", "settings"], "sem a ociosidade do shell, sem o não apagar a tela");
            C.idleEnabled = true;
            C.idleInhibit = false;
            C.doNotDisturb = false;
            t.eq(ids(), ["dnd", "awake", "settings"]);
            t.eq([checked("dnd"), checked("awake"), checked("settings")], [false, false, false], "vazios");
            K.trigger("dnd");
            K.trigger("awake");
            t.eq([C.doNotDisturb, C.idleInhibit], [true, true]);
            t.eq([checked("dnd"), checked("awake"), checked("settings")], [true, true, false], "cheios; configurações nunca");
        } finally {
            C.doNotDisturb = dnd0;
            C.idleEnabled = idle0;
            C.idleInhibit = awake0;
        }
    });

    scenario("controles: o botão de configurações abre as configurações e fecha a central", () => {
        P.openCentral("");
        K.trigger("settings");
        t.eq([P.opened, S.open], [["settings"], false]);
    });

    const E = t.PowerState;
    const B = t.Battery;

    t.test("energia: o que aparece sem bateria, sem perfil e sem dispositivos", () => {
        const simulated0 = B.simulated;
        const profiles0 = B.profilesAvailable;
        try {
            B.simulated = null;
            B.profilesAvailable = false;
            t.eq([E.hasBattery, E.profilesAvailable, E.devices.length, E.any], [false, false, 0, false], "desktop sem nada: o painel some");
            B.profilesAvailable = true;
            t.eq([E.hasBattery, E.any], [false, true], "só o perfil");
            t.eq(E.profileButtons.map(b => b.value), B.hasPerformance ? [0, 1, 2] : [0, 1], "desempenho só se o daemon tiver");
            B.profilesAvailable = false;
            B.simulated = { percentage: 0.78, onBattery: true };
            t.eq([E.hasBattery, E.any, E.batteryNote], [true, true, ""], "na bateria, sem o tempo (a simulada não tem)");
            B.simulated = { percentage: 0.5, onBattery: false };
            t.eq(E.batteryNote, "Carregando");
            B.simulated = { percentage: 1, onBattery: false };
            t.eq(E.batteryNote, "Carregada");
        } finally {
            B.simulated = simulated0;
            B.profilesAvailable = profiles0;
        }
    });

    t.test("energia: bateria baixa pelo limite do serviço", () => {
        const simulated0 = B.simulated;
        try {
            B.simulated = { percentage: B.low - 0.01, onBattery: true };
            t.eq([B.isLow, E.low], [true, true], "abaixo do limite, na bateria");
            B.simulated = { percentage: B.low - 0.01, onBattery: false };
            t.eq([B.isLow, E.low], [false, false], "carregando não é baixa");
            B.simulated = { percentage: B.low, onBattery: true };
            t.eq([B.isLow, E.low], [false, false], "no limite ainda não");
        } finally {
            B.simulated = simulated0;
        }
    });

    t.test("energia: bateria dos dispositivos Bluetooth", () => {
        const list = E.withBattery([
            { name: "WH-1000", address: "AA", icon: "audio-headset", connected: true, batteryAvailable: true, battery: 0.82 },
            { name: "", address: "BB", icon: "input-mouse", connected: true, batteryAvailable: true, battery: 0.41 },
            { name: "Teclado", address: "CC", icon: "input-keyboard", connected: true, batteryAvailable: false, battery: 0 },
            { name: "Caixa", address: "DD", icon: "audio-card", connected: false, batteryAvailable: true, battery: 0.9 }
        ]);
        t.eq(list, [{ name: "WH-1000", icon: "headset_mic", battery: 0.82 }, { name: "BB", icon: "mouse", battery: 0.41 }], "conectados e com bateria; sem nome, o endereço");
        t.eq(E.withBattery([]), []);
        t.eq(E.withBattery(null), []);
    });
}
