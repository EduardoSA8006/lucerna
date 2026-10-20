// Testes de services/SystemStats: o adaptador dos tópicos do lucernad; as
// leituras do /proc e do /sys ficaram no daemon, com os testes em Rust.
function run(t) {
    const S = t.SystemStats;

    // apply() e as applyX() gravam as propriedades de dados e o estado do
    // módulo. Guarda o de antes para restaurar no fim (a suíte roda no mesmo
    // processo que as seguintes).
    const keys = ["cpuModel", "cpuThreads", "cpuUsage", "cpuTemp", "memTotal", "memUsed", "swapTotal", "swapUsed", "disks", "rxRate", "txRate", "rxTotal", "txTotal", "rxHistory", "txHistory", "gpus", "uptime", "hostname", "osName", "kernel", "moduleAvailable", "moduleError"];
    const original = ({});
    for (const key of keys)
        original[key] = S[key];

    t.test("systemstats: tópicos conforme a aba e a GPU", () => {
        t.eq(S.wantedTopics(false, true), ["system.info", "system.status"]);
        t.eq(S.wantedTopics(true, false), ["system.info", "system.status", "system.stats", "system.disks"]);
        t.eq(S.wantedTopics(true, true), ["system.info", "system.status", "system.stats", "system.disks", "system.gpus"]);
    });

    t.test("systemstats: dados da máquina", () => {
        S.apply("system.info", {
            cpuModel: "Intel(R) Core(TM) i7-1165G7",
            cpuThreads: 8,
            hostname: "maquina",
            osName: "Arch Linux",
            kernel: "6.17.2-arch1-1"
        });
        t.eq([S.cpuModel, S.cpuThreads, S.hostname, S.osName, S.kernel], ["Intel(R) Core(TM) i7-1165G7", 8, "maquina", "Arch Linux", "6.17.2-arch1-1"]);
    });

    const stats = {
        cpuUsage: 0.23,
        cpuTemp: null,
        memTotal: 16384000000,
        memUsed: 10240000000,
        swapTotal: 2048000000,
        swapUsed: 0,
        rxRate: 1532.5,
        txRate: 220.0,
        rxTotal: 123456789,
        txTotal: 2345678,
        rxHistory: [0.0, 1532.5],
        txHistory: [0.0, 220.0],
        uptime: 12345.67
    };
    const others = ["cpuUsage", "memTotal", "memUsed", "swapTotal", "swapUsed", "rxRate", "txRate", "rxTotal", "txTotal", "rxHistory", "txHistory", "uptime"];

    t.test("systemstats: medidas, com temperatura ausente em NaN", () => {
        S.apply("system.stats", stats);
        t.check(Number.isNaN(S.cpuTemp), "sem sensor, NaN");
        t.eq(others.map(key => S[key]), others.map(key => stats[key]));
        S.apply("system.stats", Object.assign({}, stats, {
            cpuTemp: 48.5
        }));
        t.eq(S.cpuTemp, 48.5);
    });

    t.test("systemstats: discos e GPUs, com null em NaN", () => {
        const disks = [
            {
                name: "nvme0n1",
                size: 2400,
                used: 540,
                root: true
            },
            {
                name: "sda",
                size: 1000,
                used: 400,
                root: false
            }
        ];
        S.apply("system.disks", {
            disks: disks
        });
        t.eq(S.disks, disks);
        S.apply("system.gpus", {
            gpus: [
                {
                    card: "card1",
                    vendor: "nvidia",
                    pci: "0000:01:00.0",
                    state: "suspended",
                    name: "NVIDIA",
                    usage: null,
                    temp: null,
                    freq: null,
                    maxFreq: null
                }
            ]
        });
        const g = S.gpus[0];
        t.eq(S.gpus.length, 1);
        t.check([g.usage, g.temp, g.freq, g.maxFreq].every(v => Number.isNaN(v)), "null vira NaN");
        t.eq([g.card, g.vendor, g.state, g.name], ["card1", "nvidia", "suspended", "NVIDIA"]);
    });

    t.test("systemstats: estado do módulo", () => {
        S.apply("system.status", {
            available: false,
            error: "O módulo de sistema parou por um erro interno."
        });
        t.eq([S.moduleAvailable, S.moduleError], [false, "O módulo de sistema parou por um erro interno."]);
        S.apply("system.status", {
            available: true,
            error: null
        });
        t.eq([S.moduleAvailable, S.moduleError], [true, ""]);
        t.eq(S.available, false, "sem o daemon no teste, indisponível");
    });

    t.test("systemstats: null e tópico desconhecido não mudam nada", () => {
        const before = [S.cpuUsage, S.disks, S.gpus.length];
        S.apply("system.stats", null);
        S.apply("system.disks", null);
        S.apply("outro.topico", {
            cpuUsage: 0.99,
            disks: [],
            gpus: []
        });
        t.eq([S.cpuUsage, S.disks, S.gpus.length], before);
    });

    t.test("systemstats: sincronizar e configurar sem conexão só guardam", () => {
        const before = {
            active: S.active,
            gpuEnabled: S.gpuEnabled
        };
        const gpus = {
            gpus: [
                {
                    card: "card0",
                    vendor: "intel",
                    pci: "0000:00:02.0",
                    state: "active",
                    name: "Intel (integrada)",
                    usage: null,
                    temp: null,
                    freq: 1450,
                    maxFreq: 1500
                }
            ]
        };
        try {
            S.sync();
            t.eq(S.client.wanted, S.wantedTopics(S.active, S.gpuEnabled));

            S.gpuEnabled = true;
            S.active = false;
            t.eq(S.client.wanted, ["system.info", "system.status"], "aba fechada: só a máquina e o estado");
            S.active = true;
            t.eq(S.client.wanted, ["system.info", "system.status", "system.stats", "system.disks", "system.gpus"], "aba à mostra: as medidas e as GPUs");

            S.apply("system.gpus", gpus);
            t.eq(S.gpus.length, 1);
            S.gpuEnabled = false;
            t.eq(S.gpus, [], "GPU desligada: a lista zera");
            t.eq(S.client.wanted, ["system.info", "system.status", "system.stats", "system.disks"], "GPU desligada: sem system.gpus");
            S.apply("system.gpus", gpus);
            t.eq(S.gpus, [], "um system.gpus a caminho não repovoa");

            const ids = [S.client.nextId, Object.keys(S.client.pending).length];
            S.configure();
            t.eq([S.client.nextId, Object.keys(S.client.pending).length], ids, "sem conexão, configure() não pede nada");
        } finally {
            S.active = before.active;
            S.gpuEnabled = before.gpuEnabled;
        }
        t.eq(S.client.wanted, S.wantedTopics(before.active, before.gpuEnabled), "tópicos de volta");
    });

    t.test("systemstats: a conexão que cai esquece o estado do módulo", () => {
        S.apply("system.status", {
            available: false,
            error: "O módulo de sistema parou por um erro interno."
        });
        S.connectionChanged(false);
        t.eq([S.moduleAvailable, S.moduleError], [false, ""], "o erro era da conexão anterior");
        S.apply("system.status", {
            available: true,
            error: null
        });
        S.connectionChanged(false);
        t.eq(S.moduleAvailable, false, "ao reconectar, só vale o system.status novo");
        t.eq(S.client.wanted, S.wantedTopics(S.active, S.gpuEnabled), "e os tópicos seguem pedidos");
    });

    t.test("systemstats: o texto da máquina sem o daemon", () => {
        t.eq(S.machineText(true, "maquina"), "maquina");
        t.eq(S.machineText(false, "maquina"), "—");
        t.eq(S.machineText(true, ""), "—");
    });

    for (const key of keys)
        S[key] = original[key];

    t.test("systemstats: estado original restaurado", () => {
        t.eq(keys.map(key => S[key]), keys.map(key => original[key]));
    });
}
