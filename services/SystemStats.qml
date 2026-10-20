pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Dados do sistema vindos do módulo system do lucernad (services/Lucernad).
// Mesmas propriedades de antes; sem o daemon, `available` fica falso.
// Os tópicos de medida só são assinados com `active` (quem mostra os dados
// liga), e o das GPUs só com `gpuEnabled` também: o lucernad mede só com
// assinante, a cada `interval` ms.
Singleton {
    id: root

    property bool active: false
    property int interval: 2000
    // A GPU pode ser desligada (o tópico dela nem é assinado).
    property bool gpuEnabled: true

    readonly property var client: Lucernad.client
    // O system.status do daemon: o módulo pode estar indisponível com o
    // daemon de pé (o /proc/stat ilegível, um erro interno).
    property bool moduleAvailable: false
    property string moduleError: ""
    readonly property bool connected: client.connected
    readonly property bool available: connected && moduleAvailable

    // CPU
    property string cpuModel: ""
    property int cpuThreads: 0
    property real cpuUsage: 0
    property real cpuTemp: NaN

    // Memória, em bytes
    property real memTotal: 0
    property real memUsed: 0
    property real swapTotal: 0
    property real swapUsed: 0

    // Discos físicos: [{ name ("nvme0n1", "sda"), size, used (em bytes, as
    // partições montadas somadas), root (tem a raiz "/") }], o da raiz primeiro.
    property var disks: []

    // Rede (interfaces físicas e Wi-Fi), em bytes e bytes/s
    property real rxRate: 0
    property real txRate: 0
    property real rxTotal: 0
    property real txTotal: 0
    property var rxHistory: []
    property var txHistory: []

    // GPUs: [{ card, vendor, pci, state ("active" | "suspended"), name, usage (0-1 ou NaN), temp, freq, maxFreq }]
    property var gpus: []

    property real uptime: 0
    property string hostname: ""
    property string osName: ""
    property string kernel: ""
    property string quickshellVersion: ""

    // Os tópicos a assinar: os da máquina e do estado sempre; as medidas com a
    // aba à mostra; as GPUs só com ela ligada também.
    function wantedTopics(active: bool, gpuEnabled: bool): var {
        const topics = ["system.info", "system.status"];
        if (active)
            topics.push("system.stats", "system.disks");
        if (active && gpuEnabled)
            topics.push("system.gpus");
        return topics;
    }

    function sync(): void {
        client.setTopics(wantedTopics(active, gpuEnabled));
    }

    // O intervalo da amostragem do daemon, só com a conexão feita (a cada
    // conexão nova, o onConnectedChanged manda de novo).
    function configure(): void {
        if (client.connected)
            client.call("system.configure", {
                interval_ms: interval
            }, null);
    }

    // Um estado recebido do daemon; `null` (o tópico ainda sem amostra) e
    // tópico desconhecido não mudam nada.
    function apply(topic: string, data: var): void {
        if (data === null || data === undefined)
            return;
        switch (topic) {
        case "system.info":
            applyInfo(data);
            break;
        case "system.stats":
            applyStats(data);
            break;
        case "system.disks":
            applyDisks(data);
            break;
        case "system.gpus":
            applyGpus(data);
            break;
        case "system.status":
            applyStatus(data);
            break;
        }
    }

    function applyInfo(data: var): void {
        cpuModel = data.cpuModel;
        cpuThreads = data.cpuThreads;
        hostname = data.hostname;
        osName = data.osName;
        kernel = data.kernel;
    }

    function applyStats(data: var): void {
        cpuUsage = data.cpuUsage;
        cpuTemp = data.cpuTemp ?? NaN;
        memTotal = data.memTotal;
        memUsed = data.memUsed;
        swapTotal = data.swapTotal;
        swapUsed = data.swapUsed;
        rxRate = data.rxRate;
        txRate = data.txRate;
        rxTotal = data.rxTotal;
        txTotal = data.txTotal;
        rxHistory = data.rxHistory;
        txHistory = data.txHistory;
        uptime = data.uptime;
    }

    function applyDisks(data: var): void {
        disks = data.disks;
    }

    // O daemon manda `null` no que não leu (placa suspensa, sem sensor); a
    // interface espera NaN.
    // Com a GPU desligada, um system.gpus que ainda estava a caminho não repovoa.
    function applyGpus(data: var): void {
        if (!gpuEnabled)
            return;
        gpus = data.gpus.map(g => Object.assign({}, g, {
            usage: g.usage ?? NaN,
            temp: g.temp ?? NaN,
            freq: g.freq ?? NaN,
            maxFreq: g.maxFreq ?? NaN
        }));
    }

    function applyStatus(data: var): void {
        moduleAvailable = data.available === true;
        moduleError = data.error ?? "";
    }

    // A conexão abriu ou caiu: caída, o estado do módulo era da conexão
    // anterior e não vale mais (ao reconectar, só o system.status novo);
    // aberta, reassina e manda o intervalo.
    function connectionChanged(connected: bool): void {
        if (!connected) {
            moduleAvailable = false;
            moduleError = "";
        }
        sync();
        configure();
    }

    // Um dado da máquina para mostrar: "—" sem o daemon ou sem o valor.
    function machineText(connected: bool, value: string): string {
        return connected && value ? value : "—";
    }

    onActiveChanged: sync()
    onGpuEnabledChanged: {
        if (!gpuEnabled)
            gpus = [];
        sync();
    }
    onIntervalChanged: configure()

    Connections {
        target: root.client

        function onReceived(topic: string, data: var): void {
            root.apply(topic, data);
        }

        function onConnectedChanged(): void {
            root.connectionChanged(root.client.connected);
        }
    }

    Process {
        running: true
        command: ["qs", "--version"]
        stdout: StdioCollector {
            onStreamFinished: root.quickshellVersion = text.match(/\d+\.\d+\.\d+/)?.[0] ?? text.trim()
        }
    }

    Component.onCompleted: sync()
}
