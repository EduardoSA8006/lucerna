// Testes de services/Battery: o histórico de consumo, pela resposta do
// UPower (GetHistory pelo busctl --json=short) ou pelas amostras do shell.
function run(t) {
    const B = t.Battery;

    t.test("bateria: o histórico do UPower", () => {
        // Como o busctl devolve: o mais novo primeiro, [tempo, valor, estado].
        const text = '{"type":"a(udu)","data":[[[1791033476,8.1466,0],[1791033131,9.9309,1],[1791032635,13.412,2]]]}\n';
        t.eq(B.parseHistory(text), [{ time: 1791032635, value: 13.412 }, { time: 1791033131, value: 9.9309 }, { time: 1791033476, value: 8.1466 }], "do mais antigo ao mais novo");
        t.eq(B.parseHistory('{"type":"a(udu)","data":[[]]}'), [], "sem pontos");
    });

    t.test("bateria: histórico que não se lê", () => {
        t.eq(B.parseHistory(""), [], "vazio");
        t.eq(B.parseHistory("Call failed: device does not support getting history"), [], "erro do busctl");
        t.eq(B.parseHistory('{"type":"a(udu)"}'), [], "sem data");
        t.eq(B.parseHistory('{"type":"a(udu)","data":[[[1,"x",0],[2,-3,0],[3],[4,5,1]]]}'), [{ time: 4, value: 5 }], "pontos inválidos ficam de fora");
    });

    t.test("bateria: as amostras do shell guardam a última hora", () => {
        const list = [{ time: 100, value: 5 }, { time: 3000, value: 7 }];
        t.eq(B.pushSample(list, { time: 3800, value: 9 }, 3600), [{ time: 3000, value: 7 }, { time: 3800, value: 9 }], "a mais velha que uma hora sai");
        t.eq(B.pushSample([], { time: 10, value: 4 }, 3600), [{ time: 10, value: 4 }], "a primeira");
        t.eq(list.length, 2, "não mexe na lista de entrada");
    });
}
