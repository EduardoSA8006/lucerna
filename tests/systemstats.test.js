// Testes de services/SystemStats: a leitura do /proc e das saídas do df e do
// gpu-status, com textos fixos (nada lê o /proc de verdade).
function run(t) {
    const S = t.SystemStats;

    // Nenhuma das funções abaixo é pura: parseStat grava lastCpu/cpuHistory/
    // cpuUsage; parseMeminfo grava memTotal/memUsed/swapTotal/swapUsed;
    // parseNetdev grava rxTotal/txTotal/lastNet; parseCpuinfo grava cpuModel/
    // cpuThreads; pickTempSensor grava tempPath; parseGpus grava gpus; parseDf
    // grava disks. Guarda o estado de antes para restaurar no fim (a suíte
    // roda no mesmo processo que as seguintes, e o singleton pode já ter
    // valores reais lidos pelo FileView antes deste teste rodar).
    const original = {
        lastCpu: S.lastCpu,
        cpuHistory: S.cpuHistory,
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
        S.cpuHistory = [];
        S.parseStat("cpu  100 0 100 700 100 0 0 0 0 0\ncpu0 1 2 3 4\n");
        t.eq(S.lastCpu, { idle: 800, total: 1000 });
        S.parseStat("cpu  200 0 200 1300 300 0 0 0 0 0\n");
        t.near(S.cpuUsage, 0.2, 1e-9);
        t.eq(S.cpuHistory.length, 1);
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

    t.test("systemstats: discos do df, sem repetir", () => {
        S.parseDf("Mounted on     1B-blocks      Used\n/ 1000 400\n/home 2000 500\n/ 1000 400\n");
        t.eq(S.disks, [{ mount: "/", size: 1000, used: 400 }, { mount: "/home", size: 2000, used: 500 }]);
    });

    S.lastCpu = original.lastCpu;
    S.cpuHistory = original.cpuHistory;
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
    S.disks = original.disks;

    t.test("systemstats: estado original restaurado", () => {
        t.eq([S.lastCpu, S.cpuHistory, S.cpuUsage, S.memTotal, S.memUsed, S.swapTotal, S.swapUsed, S.rxTotal, S.txTotal, S.lastNet, S.cpuModel, S.cpuThreads, S.tempPath, S.gpus, S.disks],
             [original.lastCpu, original.cpuHistory, original.cpuUsage, original.memTotal, original.memUsed, original.swapTotal, original.swapUsed, original.rxTotal, original.txTotal, original.lastNet, original.cpuModel, original.cpuThreads, original.tempPath, original.gpus, original.disks]);
    });
}
