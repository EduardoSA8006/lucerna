// Testes de services/Battery: o histórico de consumo, pela resposta do
// UPower (GetHistory pelo busctl --json=short) ou pelas amostras do shell.
function run(t) {
    const B = t.Battery;

    t.test("bateria: o histórico do UPower", () => {
        // Como o busctl devolve: o mais novo primeiro, [tempo, valor, estado].
        const text = '{"type":"a(udu)","data":[[[1791033476,8.1466,0],[1791033131,9.9309,1],[1791032635,13.412,2]]]}\n';
        t.eq(B.parseHistory(text), [{ time: 1791032635, value: 13.412, state: 2 }, { time: 1791033131, value: 9.9309, state: 1 }, { time: 1791033476, value: 8.1466, state: 0 }], "do mais antigo ao mais novo, com o estado");
        t.eq(B.parseHistory('{"type":"a(udu)","data":[[]]}'), [], "sem pontos");
    });

    t.test("bateria: o histórico como o busctl escreve, com expoente", () => {
        const text = '{"type":"a(udu)","data":[[[1791033716,5.2514000000000002899e+00,2],[1791033686,1.2e+01,1]]]}';
        t.eq(B.parseHistory(text), [{ time: 1791033686, value: 12, state: 1 }, { time: 1791033716, value: 5.2514000000000002899, state: 2 }]);
    });

    t.test("bateria: histórico que não se lê", () => {
        t.eq(B.parseHistory(""), [], "vazio");
        t.eq(B.parseHistory("Call failed: device does not support getting history"), [], "erro do busctl");
        t.eq(B.parseHistory('{"type":"a(udu)"}'), [], "sem data");
        t.eq(B.parseHistory('{"type":"a(udu)","data":[[[1,"x",0],[2,-3,0],[3],[4,5,1]]]}'), [{ time: 4, value: 5, state: 1 }], "pontos inválidos ficam de fora");
    });

    t.test("bateria: as amostras do shell guardam a última hora", () => {
        const list = [{ time: 100, value: 5 }, { time: 3000, value: 7 }];
        t.eq(B.pushSample(list, { time: 3800, value: 9 }, 3600), [{ time: 3000, value: 7 }, { time: 3800, value: 9 }], "a mais velha que uma hora sai");
        t.eq(B.pushSample([], { time: 10, value: 4 }, 3600), [{ time: 10, value: 4 }], "a primeira");
        t.eq(list.length, 2, "não mexe na lista de entrada");
    });

    t.test("bateria: a fonte do histórico", () => {
        const pts = [{ time: 1, value: 5, state: 2 }];
        const samples = [{ time: 2, value: 7, state: 2 }];
        t.eq(B.historyAfter({ history: samples, upower: false, failures: 0 }, pts), { history: pts, upower: true, failures: 0 }, "o UPower respondeu: as amostras saem");
        t.eq(B.historyAfter({ history: pts, upower: true, failures: 0 }, []), { history: pts, upower: true, failures: 1 }, "uma falha: fica o UPower");
        t.eq(B.historyAfter({ history: pts, upower: true, failures: 1 }, []), { history: pts, upower: true, failures: 2 });
        t.eq(B.historyAfter({ history: pts, upower: true, failures: 2 }, []), { history: [], upower: false, failures: 3 }, "três seguidas: volta às amostras, do zero");
        t.eq(B.historyAfter({ history: pts, upower: true, failures: 2 }, pts), { history: pts, upower: true, failures: 0 }, "voltou: zera a conta");
        t.eq(B.historyAfter({ history: samples, upower: false, failures: 1 }, []), { history: samples, upower: false, failures: 2 }, "sem UPower: as amostras ficam");
    });
}
