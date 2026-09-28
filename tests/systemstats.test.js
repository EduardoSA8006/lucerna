// Testes de services/SystemStats: a leitura do /proc e das saídas do df e do
// gpu-status, com textos fixos (nada lê o /proc de verdade).
function run(t) {
    const S = t.SystemStats;

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
        S.tempPath = "";
    });

    t.test("systemstats: GPUs do gpu-status.sh", () => {
        S.parseGpus("card1|nvidia|0000:01:00.0|active||35|48|1200|2100\ncard0|intel|0000:00:02.0|suspended|||||\n");
        const g = S.gpus;
        t.eq([g[0].name, g[0].usage, g[0].temp, g[0].freq, g[0].maxFreq, g[0].state], ["NVIDIA", 0.35, 48, 1200, 2100, "active"]);
        t.check(g[1].name === "Intel (integrada)" && isNaN(g[1].usage) && isNaN(g[1].temp), JSON.stringify(g[1]));
        S.gpus = [];
    });

    t.test("systemstats: discos do df, sem repetir", () => {
        S.parseDf("Mounted on     1B-blocks      Used\n/ 1000 400\n/home 2000 500\n/ 1000 400\n");
        t.eq(S.disks, [{ mount: "/", size: 1000, used: 400 }, { mount: "/home", size: 2000, used: 500 }]);
    });
}
