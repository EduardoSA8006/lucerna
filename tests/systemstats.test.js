// Testes de services/SystemStats: a leitura do /proc e das saídas do df e do
// gpu-status, com textos fixos (nada lê o /proc de verdade).
function run(t) {
    const S = t.SystemStats;

    // Nenhuma das funções abaixo é pura: parseStat grava lastCpu/cpuUsage;
    // parseMeminfo grava memTotal/memUsed/swapTotal/swapUsed; parseNetdev
    // grava rxTotal/txTotal/lastNet; parseCpuinfo grava cpuModel/cpuThreads;
    // pickTempSensor grava tempPath; parseGpus grava gpus; parseDf grava
    // disks. Guarda o estado de antes para restaurar no fim (a suíte roda no
    // mesmo processo que as seguintes, e o singleton pode já ter valores reais
    // lidos pelo FileView antes deste teste rodar).
    const original = {
        lastCpu: S.lastCpu,
        cpuUsage: S.cpuUsage,
        memTotal: S.memTotal,
        memUsed: S.memUsed,
        swapTotal: S.swapTotal,
        swapUsed: S.swapUsed,
        rxTotal: S.rxTotal,
        txTotal: S.txTotal,
        lastNet: S.lastNet,
        cpuModel: S.cpuModel,
        cpuThreads: S.cpuThreads,
        tempPath: S.tempPath,
        gpus: S.gpus,
        lastDrm: S.lastDrm,
        drmUsage: S.drmUsage,
        disks: S.disks
    };

    t.test("systemstats: histórico limitado", () => {
        t.eq(S.push([1, 2], 3), [1, 2, 3]);
        const full = Array.from({ length: 30 }, (_, i) => i);
        const next = S.push(full, 99);
        t.eq([next.length, next[0], next[29]], [30, 1, 99]);
    });

    t.test("systemstats: uso de CPU entre duas leituras do /proc/stat", () => {
        S.lastCpu = null;
        S.parseStat("cpu  100 0 100 700 100 0 0 0 0 0\ncpu0 1 2 3 4\n");
        t.eq(S.lastCpu, { idle: 800, total: 1000 });
        S.parseStat("cpu  200 0 200 1300 300 0 0 0 0 0\n");
        t.near(S.cpuUsage, 0.2, 1e-9);
    });

    t.test("systemstats: memória e swap do /proc/meminfo", () => {
        S.parseMeminfo("MemTotal:       16000 kB\nMemFree:  1000 kB\nMemAvailable:    6000 kB\nSwapTotal:  2000 kB\nSwapFree:  500 kB\n");
        t.eq([S.memTotal, S.memUsed, S.swapTotal, S.swapUsed], [16384000, 10240000, 2048000, 1536000]);
    });

    t.test("systemstats: interfaces físicas e virtuais", () => {
        t.check(S.isPhysical("enp3s0") && S.isPhysical("wlan0"), "físicas");
        for (const name of ["lo", "docker0", "veth1a2b", "br-123", "wg0", "tun0"])
            t.check(!S.isPhysical(name), name);
    });

    t.test("systemstats: totais de rede do /proc/net/dev", () => {
        S.lastNet = null;
        S.parseNetdev([
            "Inter-|   Receive                            |  Transmit",
            " face |bytes    packets errs drop fifo frame compressed multicast|bytes",
            "    lo:  500 0 0 0 0 0 0 0  500 0 0 0 0 0 0 0",
            "  eth0: 1000 0 0 0 0 0 0 0 2000 0 0 0 0 0 0 0",
            "docker0: 300 0 0 0 0 0 0 0 300 0 0 0 0 0 0 0"
        ].join("\n"));
        t.eq([S.rxTotal, S.txTotal, S.lastNet.rx, S.lastNet.tx], [1000, 2000, 1000, 2000]);
    });

    t.test("systemstats: modelo e threads do /proc/cpuinfo", () => {
        S.parseCpuinfo("processor\t: 0\nmodel name\t: Intel(R)  Core(TM)   i7-1165G7\nprocessor\t: 1\n");
        t.eq([S.cpuModel, S.cpuThreads], ["Intel(R) Core(TM) i7-1165G7", 2]);
    });

    t.test("systemstats: sensor de temperatura preferido", () => {
        S.tempPath = "";
        S.pickTempSensor("/inexistente/hwmon0 nvme\n");
        t.eq(S.tempPath, "", "sem sensor de CPU conhecido");
        S.pickTempSensor("/inexistente/hwmon0 acpitz\n/inexistente/hwmon1 coretemp\n");
        t.eq(S.tempPath, "/inexistente/hwmon1/temp1_input", "coretemp antes do acpitz");
    });

    t.test("systemstats: GPUs do gpu-status.sh", () => {
        S.parseGpus("card1|nvidia|0000:01:00.0|active||35|48|1200|2100\ncard0|intel|0000:00:02.0|suspended|||||\n");
        const g = S.gpus;
        t.eq([g[0].name, g[0].usage, g[0].temp, g[0].freq, g[0].maxFreq, g[0].state], ["NVIDIA", 0.35, 48, 1200, 2100, "active"]);
        t.check(g[1].name === "Intel (integrada)" && isNaN(g[1].usage) && isNaN(g[1].temp), JSON.stringify(g[1]));
    });

    // Leituras do drm-fdinfo.sh: ts em ns e os clientes por "pdev/id".
    const GPU = "0000:00:02.0";
    const snap = (ts, clients) => {
        const out = { ts: ts, clients: ({}) };
        for (const c of clients)
            out.clients[`${c.pdev ?? GPU}/${c.id}`] = { driver: c.driver ?? "i915", pdev: c.pdev ?? GPU, v: c.v };
        return out;
    };
    const SEC = 2e9;

    t.test("systemstats: fdinfo do DRM, texto do drm-fdinfo.sh", () => {
        const s = S.parseDrm("T|1000\ni915|0000:00:02.0|7|engine-render=500,engine-copy=0\nxe|0000:03:00.0|9|cycles-rcs=10,total-cycles-rcs=40\n");
        t.eq(s, { ts: 1000, clients: {
            "0000:00:02.0/7": { driver: "i915", pdev: "0000:00:02.0", v: { "engine-render": 500, "engine-copy": 0 } },
            "0000:03:00.0/9": { driver: "xe", pdev: "0000:03:00.0", v: { "cycles-rcs": 10, "total-cycles-rcs": 40 } }
        } });
        t.eq(S.parseDrm("T|5\n"), { ts: 5, clients: {} });
    });

    t.test("systemstats: uso i915 de um cliente, pela classe mais ocupada", () => {
        const a = snap(0, [{ id: 1, v: { "engine-render": 100, "engine-video": 0 } }]);
        const b = snap(SEC, [{ id: 1, v: { "engine-render": 100 + 0.25 * SEC, "engine-video": 0.5 * SEC } }]);
        t.near(S.drmBusy(a, b, GPU), 0.5, 1e-9);
    });

    t.test("systemstats: uso i915 soma os clientes e limita a 1", () => {
        const a = snap(0, [{ id: 1, v: { "engine-render": 0 } }, { id: 2, v: { "engine-render": 0 } }]);
        const b = snap(SEC, [{ id: 1, v: { "engine-render": 0.25 * SEC } }, { id: 2, v: { "engine-render": 0.5 * SEC } }]);
        t.near(S.drmBusy(a, b, GPU), 0.75, 1e-9);
        const c = snap(SEC, [{ id: 1, v: { "engine-render": 0.9 * SEC } }, { id: 2, v: { "engine-render": 0.9 * SEC } }]);
        t.eq(S.drmBusy(a, c, GPU), 1);
    });

    t.test("systemstats: cliente que some entre as leituras fica de fora", () => {
        const a = snap(0, [{ id: 1, v: { "engine-render": 0 } }, { id: 2, v: { "engine-render": 5 * SEC } }]);
        const b = snap(SEC, [{ id: 1, v: { "engine-render": 0.2 * SEC } }, { id: 3, v: { "engine-render": 9 * SEC } }]);
        t.near(S.drmBusy(a, b, GPU), 0.2, 1e-9);
    });

    t.test("systemstats: uso xe por ciclos", () => {
        const v = (c, tot) => ({ "cycles-rcs": c, "total-cycles-rcs": tot, "cycles-vcs": 0, "total-cycles-vcs": tot });
        const a = snap(0, [{ id: 1, driver: "xe", v: v(100, 1000) }, { id: 2, driver: "xe", v: v(0, 1000) }]);
        const b = snap(SEC, [{ id: 1, driver: "xe", v: v(300, 2000) }, { id: 2, driver: "xe", v: v(100, 2000) }]);
        t.near(S.drmBusy(a, b, GPU), 0.3, 1e-9);
    });

    t.test("systemstats: outra placa (pdev diferente) é ignorada", () => {
        const other = "0000:01:00.0";
        const a = snap(0, [{ id: 1, v: { "engine-render": 0 } }, { id: 1, pdev: other, v: { "engine-render": 0 } }]);
        const b = snap(SEC, [{ id: 1, v: { "engine-render": 0.1 * SEC } }, { id: 1, pdev: other, v: { "engine-render": 0.9 * SEC } }]);
        t.near(S.drmBusy(a, b, GPU), 0.1, 1e-9);
        t.near(S.drmBusy(a, b, other), 0.9, 1e-9);
        t.check(isNaN(S.drmBusy(a, b, "0000:09:00.0")), "sem cliente na placa");
    });

    t.test("systemstats: sem leitura anterior ou sem janela, NaN", () => {
        const b = snap(SEC, [{ id: 1, v: { "engine-render": SEC } }]);
        t.check(isNaN(S.drmBusy(null, b, GPU)), "primeira leitura");
        t.check(isNaN(S.drmBusy(b, b, GPU)), "janela zero");
        t.check(isNaN(S.drmBusy(snap(0, [{ id: 2, v: { "engine-render": 0 } }]), b, GPU)), "nenhum cliente em comum");
    });

    t.test("systemstats: contador que volta conta 0", () => {
        const a = snap(0, [{ id: 1, v: { "engine-render": 5 * SEC } }, { id: 2, v: { "engine-render": 0 } }]);
        const b = snap(SEC, [{ id: 1, v: { "engine-render": 1 } }, { id: 2, v: { "engine-render": 0.3 * SEC } }]);
        t.near(S.drmBusy(a, b, GPU), 0.3, 1e-9);
        const c = snap(SEC, [{ id: 1, v: { "engine-render": 1 } }]);
        t.eq(S.drmBusy(a, c, GPU), 0);
    });

    t.test("systemstats: o uso da Intel vem do fdinfo, sem tocar as outras GPUs", () => {
        S.lastDrm = null;
        S.drmUsage = ({});
        S.parseGpus("card1|nvidia|0000:01:00.0|active||35|48|1200|2100\ncard2|intel|0000:00:02.0|active||||1450|1500\n");
        S.applyDrm("T|0\ni915|0000:00:02.0|1|engine-render=0\n");
        t.check(isNaN(S.gpus[1].usage), "primeira leitura: sem uso, fica o Clock");
        S.applyDrm(`T|${SEC}\ni915|0000:00:02.0|1|engine-render=${0.4 * SEC}\n`);
        t.near(S.gpus[1].usage, 0.4, 1e-9);
        t.eq(S.gpus[0].usage, 0.35);
        S.parseGpus("card2|intel|0000:00:02.0|active||||1450|1500\n");
        t.near(S.gpus[0].usage, 0.4, 1e-9);
    });

    t.test("systemstats: leitura anterior velha (mais de 3 intervalos) é descartada", () => {
        const a = snap(0, [{ id: 1, v: { "engine-render": 0 } }]);
        const ok = snap(6 * 1e9, [{ id: 1, v: { "engine-render": 3 * 1e9 } }]);
        const old = snap(6 * 1e9 + 1, [{ id: 1, v: { "engine-render": 3 * 1e9 } }]);
        t.near(S.drmBusy(a, ok, GPU), 0.5, 1e-9);
        t.check(isNaN(S.drmBusy(a, old, GPU)), "janela de mais de 6 s com intervalo de 2 s");
    });

    t.test("systemstats: o uso se divide pela capacidade da classe", () => {
        const v = (r, vid) => ({ "engine-render": r, "engine-video": vid, "engine-capacity-video": 2 });
        const a = snap(0, [{ id: 1, v: v(0, 0) }, { id: 2, v: v(0, 0) }]);
        const b = snap(SEC, [{ id: 1, v: v(0.1 * SEC, 0.8 * SEC) }, { id: 2, v: v(0, 0.8 * SEC) }]);
        // video: 1,6 s ocupados em 2 s de janela com 2 motores = 0,8 (capacidade fora da conta de ns)
        t.near(S.drmBusy(a, b, GPU), 0.8, 1e-9);
    });

    t.test("systemstats: fdinfo malformado não contamina a conta", () => {
        const s = S.parseDrm("T|10\nlixo\ni915|0000:00:02.0||engine-render=5\ni915|0000:00:02.0|3|engine-render=abc,engine-copy=,sem-igual,engine-video=7,=4\n");
        t.eq(s, { ts: 10, clients: { "0000:00:02.0/3": { driver: "i915", pdev: "0000:00:02.0", v: { "engine-video": 7 } } } });
        t.check(isNaN(S.parseDrm("T|xx\n").ts), "ts inválido");
        t.check(isNaN(S.drmBusy(snap(0, []), S.parseDrm("T|xx\n"), GPU)), "ts inválido dá NaN");
    });

    t.test("systemstats: duas Intel, cada uma com o seu uso", () => {
        const B = "0000:03:00.0";
        S.lastDrm = null;
        S.parseGpus("card0|intel|0000:00:02.0|active||||1|2\ncard3|intel|0000:03:00.0|active||||1|2\n");
        S.applyDrm(`T|0\ni915|${GPU}|1|engine-render=0\ni915|${B}|1|engine-render=0\n`);
        S.applyDrm(`T|${SEC}\ni915|${GPU}|1|engine-render=${0.2 * SEC}\ni915|${B}|1|engine-render=${0.7 * SEC}\n`);
        t.near(S.gpus[0].usage, 0.2, 1e-9);
        t.near(S.gpus[1].usage, 0.7, 1e-9);
    });

    t.test("systemstats: sem GPU habilitada a leitura é esquecida e o resultado ignorado", () => {
        S.parseGpus("card2|intel|0000:00:02.0|active||||1450|1500\n");
        S.applyDrm(`T|0\ni915|${GPU}|1|engine-render=0\n`);
        t.check(S.lastDrm !== null, "guardou a leitura");
        S.gpuEnabled = false;
        t.eq([S.lastDrm, S.drmUsage], [null, {}]);
        S.applyDrm(`T|${SEC}\ni915|${GPU}|1|engine-render=0\n`);
        t.eq(S.lastDrm, null);
        S.gpuEnabled = true;
    });

    t.test("systemstats: Intel em repouso não lê o fdinfo e esquece a leitura", () => {
        S.parseGpus("card2|intel|0000:00:02.0|suspended|||||\n");
        S.probeDrm();
        t.eq([S.lastDrm, S.drmUsage], [null, {}]);
    });

    t.test("systemstats: discos do df, sem repetir", () => {
        S.parseDf("Mounted on     1B-blocks      Used\n/ 1000 400\n/home 2000 500\n/ 1000 400\n");
        t.eq(S.disks, [{ mount: "/", size: 1000, used: 400 }, { mount: "/home", size: 2000, used: 500 }]);
    });

    S.lastCpu = original.lastCpu;
    S.cpuUsage = original.cpuUsage;
    S.memTotal = original.memTotal;
    S.memUsed = original.memUsed;
    S.swapTotal = original.swapTotal;
    S.swapUsed = original.swapUsed;
    S.rxTotal = original.rxTotal;
    S.txTotal = original.txTotal;
    S.lastNet = original.lastNet;
    S.cpuModel = original.cpuModel;
    S.cpuThreads = original.cpuThreads;
    S.tempPath = original.tempPath;
    S.gpus = original.gpus;
    S.lastDrm = original.lastDrm;
    S.drmUsage = original.drmUsage;
    S.disks = original.disks;

    t.test("systemstats: estado original restaurado", () => {
        t.eq([S.lastCpu, S.cpuUsage, S.memTotal, S.memUsed, S.swapTotal, S.swapUsed, S.rxTotal, S.txTotal, S.lastNet, S.cpuModel, S.cpuThreads, S.tempPath, S.gpus, S.lastDrm, S.drmUsage, S.disks],
             [original.lastCpu, original.cpuUsage, original.memTotal, original.memUsed, original.swapTotal, original.swapUsed, original.rxTotal, original.txTotal, original.lastNet, original.cpuModel, original.cpuThreads, original.tempPath, original.gpus, original.lastDrm, original.drmUsage, original.disks]);
    });
}
