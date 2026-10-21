// Testes de services/Spectrum: o adaptador do spectrum.bands e do
// spectrum.status do lucernad; a captura e a análise ficaram no daemon, com os
// testes em Rust.
function run(t) {
    const S = t.Spectrum;

    // Guarda o estado de antes para restaurar no fim (a suíte roda no mesmo
    // processo que as seguintes).
    const original = { active: S.active, values: S.values, moduleAvailable: S.moduleAvailable };

    function frame(n, v) {
        return { bands: Array.from({ length: n }, () => v) };
    }

    t.test("spectrum: tópicos conforme o pedido", () => {
        t.eq(S.wantedTopics(false), ["spectrum.status"]);
        t.eq(S.wantedTopics(true), ["spectrum.status", "spectrum.bands"]);
    });

    t.test("spectrum: o player vai como nome ou null", () => {
        t.eq(S.playerParam("org.mpris.MediaPlayer2.spotify"), "org.mpris.MediaPlayer2.spotify");
        t.eq(S.playerParam(""), null);
    });

    t.test("spectrum: o quadro só vale pedindo", () => {
        try {
            S.active = true;
            S.apply("spectrum.bands", frame(48, 0.5));
            t.eq(S.values.length, 48);
            t.eq(S.values[0], 0.5);
            S.apply("spectrum.bands", frame(32, 0.9));
            t.eq([S.values.length, S.values[0]], [48, 0.5], "quadro de outro tamanho não vale");
            S.apply("spectrum.bands", { bands: "x" });
            t.eq(S.values.length, 48, "sem array não vale");
            S.active = false;
            t.eq(S.values, [], "desligado, zera");
            S.apply("spectrum.bands", frame(48, 0.5));
            t.eq(S.values, [], "desligado, o quadro não entra");
        } finally {
            S.active = original.active;
        }
    });

    t.test("spectrum: o quadro pelo sinal do cliente", () => {
        try {
            S.active = true;
            // A mesma passagem dos dados do daemon: o JSON vira lista do QML.
            S.client.received("spectrum.bands", JSON.parse(JSON.stringify(frame(48, 0.25))));
            t.eq(S.values.length, 48, "o quadro real entra");
            t.eq(S.values[47], 0.25);
            S.client.received("spectrum.bands", { bands: "x" });
            t.eq(S.values.length, 48, "sem lista não vale");
        } finally {
            S.active = original.active;
        }
    });

    t.test("spectrum: estado do módulo", () => {
        S.applyStatus({ available: false, capturing: false, player: null, error: "x" });
        t.eq(S.moduleAvailable, false);
        S.applyStatus({ available: true, capturing: false, player: null, error: null });
        t.eq(S.moduleAvailable, true);
        t.eq(S.available, false, "sem daemon no teste, indisponível");
        S.moduleAvailable = original.moduleAvailable;
    });

    t.test("spectrum: a conexão caída zera", () => {
        S.moduleAvailable = true;
        S.values = [0.1];
        S.connectionChanged(false);
        t.eq([S.moduleAvailable, S.values], [false, []]);
        S.moduleAvailable = original.moduleAvailable;
        S.values = original.values;
    });

    t.test("spectrum: sincronizar e configurar sem conexão só guardam", () => {
        S.sync();
        t.eq(S.client.owners.spectrum, S.wantedTopics(S.active));
        const before = [S.client.nextId, Object.keys(S.client.pending).length];
        S.configure();
        t.eq([S.client.nextId, Object.keys(S.client.pending).length], before, "sem conexão, nada é pedido");
    });

    t.test("spectrum: conectado, configure manda o player", () => {
        const c = S.client;
        const saved = { pending: c.pending, nextId: c.nextId };
        const last = () => {
            const ids = Object.keys(c.pending).map(Number);
            return c.pending[ids[ids.length - 1]];
        };
        try {
            c.connected = true;
            const sent = last();
            t.eq(sent.method, "spectrum.configure", "a conexão nova configura");
            t.eq(sent.params, { player: S.playerParam(S.player) });
            c.pending = {};
            S.configure();
            const again = last();
            t.eq([again.method, again.params], ["spectrum.configure", { player: S.playerParam(S.player) }]);
        } finally {
            c.connected = false;
            c.pending = saved.pending;
            c.nextId = saved.nextId;
        }
    });

    t.test("spectrum: null e tópico desconhecido não mudam nada", () => {
        try {
            S.active = true;
            S.apply("spectrum.bands", frame(48, 0.5));
            S.apply("spectrum.bands", null);
            S.apply("spectrum.status", null);
            S.apply("spectrum.xyz", { available: true });
            t.eq([S.values.length, S.moduleAvailable], [48, original.moduleAvailable]);
        } finally {
            S.active = original.active;
            S.moduleAvailable = original.moduleAvailable;
        }
    });

    t.test("spectrum: estado original restaurado", () => {
        S.active = original.active;
        S.values = original.values;
        S.moduleAvailable = original.moduleAvailable;
        t.eq([S.active, S.values, S.moduleAvailable], [false, [], false]);
    });
}
