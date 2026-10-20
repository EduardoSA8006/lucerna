// Testes de services/LucernaClient: as mensagens, as linhas, o seq e o aperto
// de mão, sem socket. Cada cliente vem da fábrica t.lucernaClient() (app
// "teste", sem socketPath: o socket nunca conecta, e os pedidos ficam só no
// pending) e é destruído no fim do caso.
function run(t) {
    // A resposta JSON-RPC de sucesso, numa linha.
    function ok(id, result) {
        return JSON.stringify({ jsonrpc: "2.0", id: id, result: result });
    }

    // As chaves de c.pending, como números.
    function ids(c) {
        return Object.keys(c.pending).map(Number);
    }

    // Os métodos pendentes, na ordem dos ids.
    function methods(c) {
        return ids(c).map(id => c.pending[id].method);
    }

    // Um cliente com os tópicos pedidos, o socket "aberto" e o hello respondido.
    function ready(topics) {
        const c = t.lucernaClient();
        c.setTopics(topics);
        c.opened();
        c.receive(ok(ids(c)[0], { protocol: "1.0", app: "teste", version: "0.1.0", topics: [], streams: [], methods: [] }));
        return c;
    }

    // Um caso com um cliente novo, destruído no fim (mesmo com exceção).
    function withClient(name, body) {
        t.test(name, () => {
            const c = t.lucernaClient();
            try {
                body(c);
            } finally {
                c.destroy();
            }
        });
    }

    withClient("lucernaclient: espera crescente até 5 s", c => {
        t.eq([0, 1, 2, 5, 6, 20].map(a => c.backoff(a)), [100, 200, 400, 3200, 5000, 5000]);
    });

    withClient("lucernaclient: pedido e notificação numa linha de JSON", c => {
        t.eq(c.encode(3, "system.configure", { interval_ms: 1000 }), '{"jsonrpc":"2.0","id":3,"method":"system.configure","params":{"interval_ms":1000}}\n');
        t.eq(c.encode(null, "x.y", null), '{"jsonrpc":"2.0","method":"x.y"}\n', "notificação sem params");
        t.eq(c.helloParams(), { protocol: "1.0", client: "shell", app: "teste" });
    });

    withClient("lucernaclient: linha que não é objeto JSON vira null", c => {
        t.eq(["lixo", "", "[1]", "3"].map(l => c.parse(l)), [null, null, null, null]);
        t.eq(c.parse('{"a":1}'), { a: 1 }, "um objeto passa");
        c.receive("lixo");
        t.eq(c.states, {});
    });

    withClient("lucernaclient: seq velho é descartado; o retrato vale com seq igual", c => {
        t.eq([[2, false], [2, false], [1, false], [2, true], [3, false]].map(([seq, snapshot]) => c.accept("a", seq, snapshot)), [true, false, false, true, true]);
    });

    withClient("lucernaclient: o aperto de mão conecta, assina e o retrato avisa", c => {
        const got = [];
        c.received.connect((topic, data) => got.push([topic, data]));
        c.setTopics(["system.info"]);
        t.eq(ids(c), [], "desconectado, não assina");
        t.eq(c.wanted, ["system.info"]);
        c.opened();
        t.eq(methods(c), ["lucerna.hello"]);
        c.receive(ok(ids(c)[0], { protocol: "1.0", app: "teste" }));
        t.eq([c.connected, c.attempt, c.error], [true, 0, ""]);
        t.eq(methods(c), ["lucerna.subscribe"]);
        c.receive(ok(ids(c)[0], { states: [{ topic: "system.info", seq: 0, data: { hostname: "maquina" } }] }));
        t.eq(c.states["system.info"], { hostname: "maquina" });
        t.eq(got, [["system.info", { hostname: "maquina" }]], "o retrato emite received");
        t.eq(ids(c), [], "o subscribe saiu do pending");
    });

    t.test("lucernaclient: lucerna.state atualiza o tópico e descarta o repetido", () => {
        const c = ready([]);
        const got = [];
        c.received.connect((topic, data) => got.push([topic, data]));
        for (const [seq, data] of [[1, "a"], [1, "b"], [2, "c"]])
            c.receive(JSON.stringify({ jsonrpc: "2.0", method: "lucerna.state", params: { topic: "x", seq: seq, data: data } }));
        t.eq(got, [["x", "a"], ["x", "c"]]);
        t.eq(c.states.x, "c");
        c.destroy();
    });

    withClient("lucernaclient: reconectar zera os seq vistos", c => {
        t.check(c.accept("a", 5, false));
        c.lost();
        c.opened();
        t.eq(c.seqs, {});
        t.check(c.accept("a", 1, false), "o seq 1 do daemon novo vale");
    });

    withClient("lucernaclient: erro no hello não conecta e guarda a mensagem", c => {
        c.opened();
        c.receive(JSON.stringify({ jsonrpc: "2.0", id: ids(c)[0], error: { code: -32010, message: "Versão do protocolo incompatível." } }));
        t.eq([c.connected, c.error], [false, "Versão do protocolo incompatível."]);
    });

    t.test("lucernaclient: trocar os tópicos assina o novo e larga o velho", () => {
        const c = ready(["a"]);
        c.receive(ok(ids(c)[0], { states: [] }));
        t.eq(ids(c), []);
        c.setTopics(["b"]);
        t.eq(methods(c), ["lucerna.subscribe", "lucerna.unsubscribe"]);
        t.eq(c.wanted, ["b"]);
        c.destroy();
    });

    withClient("lucernaclient: chamada sem conexão responde erro na hora", c => {
        let got = null;
        t.eq(c.call("x.y", {}, r => got = r), -1);
        t.eq(got, { error: { code: -1, message: "Sem conexão com o teste." } });
        t.eq(c.call("x.y", {}, null), -1, "sem callback");
        t.eq(ids(c), []);
    });

    t.test("lucernaclient: a resposta de uma chamada chega a quem pediu", () => {
        const c = ready([]);
        let got = null;
        const id = c.call("system.configure", { interval_ms: 1000 }, r => got = r);
        t.check(id > 0, "um id de verdade");
        t.eq(c.pending[id].method, "system.configure");
        c.receive(ok(id, {}));
        t.eq(got.result, {});
        t.check(!(id in c.pending), "o id saiu do pending");
        c.destroy();
    });

    t.test("lucernaclient: chamada sem callback não quebra", () => {
        const c = ready([]);
        const id = c.call("x.y", {}, null);
        c.receive(ok(id, {}));
        c.call("x.y", {}, null);
        c.lost();
        t.eq(ids(c), []);
        c.destroy();
    });

    t.test("lucernaclient: conexão perdida falha os pedidos e agenda nova tentativa", () => {
        const c = ready([]);
        let got = null;
        c.call("x.y", {}, r => got = r);
        c.lost();
        t.eq([c.connected, ids(c)], [false, []]);
        t.eq(got.error.message, "Sem conexão com o teste.");
        t.eq(c.attempt, 1);
        c.lost();
        t.eq(c.attempt, 1, "a mesma queda não conta duas vezes");
        c.open();
        c.lost();
        t.eq(c.attempt, 2);
        c.open();
        t.eq([c.connected, ids(c)], [false, []], "sem socketPath, o open() não conecta");
        c.destroy();
    });
}
