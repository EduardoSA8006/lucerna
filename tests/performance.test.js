// Testes de features/dashboard/state/PerformanceState: a GPU pronta para o
// card (rótulo, valor, fração e temperatura), qual mostrar e a próxima.
function run(t) {
    const P = t.PerformanceState;
    const gpu = (over) => Object.assign({ card: "card1", vendor: "nvidia", pci: "", state: "active", name: "NVIDIA GeForce RTX 3050 Laptop GPU", usage: NaN, temp: NaN, freq: NaN, maxFreq: NaN }, over);
    const nvidia = gpu({ usage: 0.37, temp: 61 });
    const intel = gpu({ card: "card0", vendor: "intel", name: "Intel (integrada)", freq: 1400, maxFreq: 1450 });
    const asleep = gpu({ state: "suspended" });

    t.test("performance: GPU com uso", () => {
        const v = P.gpuView(nvidia);
        t.eq([v.card, v.name, v.dedicated, v.asleep, v.label, v.value, v.unit], ["card1", "GeForce RTX 3050", true, false, "Uso", "37", "%"]);
        t.near(v.fraction, 0.37, 1e-9);
        t.eq([v.hasTemp, v.tempText, v.hot], [true, "61 °C", false]);
        t.near(v.tempFraction, 31 / 70, 1e-9, "escala de 30 a 100 °C");
        t.eq(P.gpuView(gpu({ usage: 0.5, temp: 88 })).hot, true, "quente a partir de 85 °C");
    });

    t.test("performance: GPU sem uso, com clock", () => {
        const v = P.gpuView(intel);
        t.eq([v.dedicated, v.label, v.value, v.unit, v.hasTemp, v.tempText], [false, "Clock", "1400", "MHz", false, ""]);
        t.near(v.fraction, 1400 / 1450, 1e-9, "véu = freq / maxFreq");
    });

    t.test("performance: GPU em repouso e sem dados", () => {
        const v = P.gpuView(asleep);
        t.eq([v.asleep, v.label, v.fraction, v.value, v.unit, v.hasTemp], [true, "Em repouso", 0, "—", "", false]);
        t.eq(P.gpuView(gpu({ state: "suspended", temp: 40 })).hasTemp, false, "em repouso não mostra temperatura velha");
        const none = P.gpuView(gpu({}));
        t.eq([none.label, none.fraction, none.value, none.unit], ["Uso", 0, "—", ""]);
    });

    t.test("performance: qual GPU mostrar", () => {
        const list = [intel, nvidia].map(g => P.gpuView(g));
        t.eq(P.gpuPick(list, ""), 1, "sem escolha, a dedicada");
        t.eq(P.gpuPick(list, "card0"), 0, "a escolhida");
        t.eq(P.gpuPick(list, "card9"), 1, "a escolhida sumiu: a dedicada");
        t.eq(P.gpuPick([P.gpuView(intel)], ""), 0, "só a integrada");
        t.eq(P.gpuPick([], ""), -1, "nenhuma");
    });

    t.test("performance: a próxima GPU", () => {
        const list = [intel, nvidia, gpu({ card: "card2", vendor: "amd" })].map(g => P.gpuView(g));
        t.eq([P.nextGpu(list, 0), P.nextGpu(list, 1), P.nextGpu(list, 2)], ["card1", "card2", "card0"]);
        t.eq(P.nextGpu(list.slice(0, 1), 0), "card0", "uma só: fica");
        t.eq(P.nextGpu([], -1), "", "nenhuma");
    });
}
