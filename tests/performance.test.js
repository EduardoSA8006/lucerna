// Testes de features/dashboard/state/PerformanceState: a GPU pronta para o
// card (rótulo, valor, fração e temperatura), qual mostrar e a próxima.
function run(t) {
    const P = t.PerformanceState;
    const gpu = (over) => Object.assign({ card: "card1", vendor: "nvidia", pci: "", state: "active", name: "NVIDIA GeForce RTX 3050 Laptop GPU", usage: NaN, temp: NaN, freq: NaN, maxFreq: NaN }, over);
    const nvidia = gpu({ usage: 0.37, temp: 61 });
    const intel = gpu({ card: "card0", vendor: "intel", name: "Intel (integrada)", freq: 1400, maxFreq: 1450 });
    const asleep = gpu({ state: "suspended" });

    t.test("performance: nomes curtos da CPU", () => {
        t.eq(P.shortCpu("11th Gen Intel(R) Core(TM) i5-11400H @ 2.70GHz"), "Intel Core i5-11400H");
        t.eq(P.shortCpu("AMD Ryzen 5 2600X Six-Core Processor"), "AMD Ryzen 5 2600X");
        t.eq(P.shortCpu("AMD Ryzen 7 5800X 8-Core Processor"), "AMD Ryzen 7 5800X");
        t.eq(P.shortCpu("Intel(R) Core(TM) i7-8700 CPU @ 3.20GHz"), "Intel Core i7-8700");
        t.eq(P.shortCpu("13th Gen Intel(R) Core(TM) i7-13700K"), "Intel Core i7-13700K");
        t.eq(P.shortCpu("AMD Ryzen 7 PRO 7840U w/ Radeon 780M Graphics"), "AMD Ryzen 7 PRO 7840U", "sufixo da APU");
        t.eq(P.shortCpu("Quad-Core AMD Opteron(tm) Processor 2376"), "AMD Opteron 2376", "(tm) minúsculo e Quad-Core no começo");
        t.eq(P.shortCpu(""), "Processador", "sem nome: o de reserva");
    });

    t.test("performance: nomes curtos da GPU", () => {
        t.eq(P.shortGpu("NVIDIA GeForce RTX 3050 Laptop GPU"), "GeForce RTX 3050");
        t.eq(P.shortGpu("Intel UHD Graphics"), "Intel UHD Graphics");
        t.eq(P.shortGpu("Intel(R) UHD Graphics 630"), "Intel UHD Graphics 630");
        t.eq(P.shortGpu("Intel(r) UHD Graphics 630"), "Intel UHD Graphics 630", "(r) minúsculo");
        t.eq(P.shortGpu("Intel Corporation Alder Lake-P GT2 [Iris Xe Graphics]"), "Intel Iris Xe Graphics", "formato do lspci");
        t.eq(P.shortGpu(""), "desconhecida", "sem nome: combina com \"GPU - \"");
    });

    t.test("performance: GPU com uso", () => {
        const v = P.gpuView(nvidia);
        t.eq([v.card, v.name, v.dedicated, v.asleep, v.hasData, v.label, v.value, v.unit], ["card1", "GeForce RTX 3050", true, false, true, "", "37", "%"]);
        t.near(v.fraction, 0.37, 1e-9);
        t.eq([v.hasTemp, v.tempText, v.hot], [true, "61 °C", false]);
        t.near(v.tempFraction, 31 / 70, 1e-9, "escala de 30 a 100 °C");
        t.eq(P.gpuView(gpu({ usage: 0.5, temp: 88 })).hot, true, "quente a partir de 85 °C");
    });

    t.test("performance: GPU sem uso, com clock", () => {
        const v = P.gpuView(intel);
        t.eq([v.dedicated, v.hasData, v.label, v.value, v.unit, v.hasTemp, v.tempText], [false, true, "", "1400", "MHz", false, ""]);
        t.near(v.fraction, 1400 / 1450, 1e-9, "véu = freq / maxFreq");
    });

    t.test("performance: temperatura da GPU integrada vem da CPU", () => {
        const v = P.gpuView(intel, 62);
        t.eq([v.hasTemp, v.tempText, v.hot], [true, "62 °C", false]);
        t.near(v.tempFraction, 32 / 70, 1e-9, "mesma escala da CPU");
        t.eq(P.gpuView(intel, 90).hot, true, "esquenta junto com a CPU");
        t.eq(P.gpuView(intel, NaN).hasTemp, false, "sem temperatura da CPU, nada");
        t.eq(P.gpuView(gpu({ vendor: "intel", state: "suspended" }), 62).hasTemp, false, "em repouso, nada");
        t.eq(P.gpuView(gpu({ vendor: "intel", temp: 50 }), 62).tempText, "50 °C", "com sensor próprio, o dela");
        t.eq(P.gpuView(gpu({ vendor: "amd", temp: NaN }), 62).tempText, "62 °C", "AMD sem hwmon: a da CPU");
        t.eq(P.gpuView(gpu({ vendor: "amd", temp: 71 }), 62).tempText, "71 °C", "AMD com hwmon: o dela");
        t.eq(P.gpuView(nvidia, 62).tempText, "61 °C", "dedicada: a da NVML");
        t.eq(P.gpuView(gpu({ usage: 0.1 }), 62).hasTemp, false, "dedicada sem sensor não herda a da CPU");
    });

    t.test("performance: GPU em repouso e sem dados", () => {
        const v = P.gpuView(asleep);
        t.eq([v.asleep, v.hasData, v.label, v.fraction, v.value, v.unit, v.hasTemp], [true, false, "Em repouso", 0, "—", "", false]);
        t.eq(P.gpuView(gpu({ state: "suspended", temp: 40 })).hasTemp, false, "em repouso não mostra temperatura velha");
        const none = P.gpuView(gpu({}));
        t.eq([none.hasData, none.label, none.fraction, none.value, none.unit], [false, "", 0, "—", ""]);
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

    const gib = 1024 * 1024 * 1024;
    const disks = [{ name: "nvme0n1", size: 915 * gib, used: 454 * gib, root: true }, { name: "sda", size: 0, used: 0, root: false }];

    t.test("performance: o disco pronto para o card", () => {
        const v = P.diskView(disks[0]);
        t.eq([v.name, v.text], ["nvme0n1", "454 / 915 GiB"]);
        t.near(v.fraction, 454 / 915, 1e-9);
        t.eq(P.diskView(disks[1]).fraction, 0, "tamanho 0 não divide");
    });

    t.test("performance: qual disco mostrar e o próximo", () => {
        const list = disks.map(d => P.diskView(d));
        t.eq(P.diskPick(list, ""), 0, "sem escolha, o primeiro (o da raiz)");
        t.eq(P.diskPick(list, "sda"), 1, "o escolhido");
        t.eq(P.diskPick(list, "sdb"), 0, "o escolhido sumiu: o primeiro");
        t.eq(P.diskPick([], ""), -1, "nenhum");
        t.eq([P.nextDisk(list, 0), P.nextDisk(list, 1)], ["sda", "nvme0n1"]);
        t.eq(P.nextDisk([], -1), "", "nenhum");
    });
}
