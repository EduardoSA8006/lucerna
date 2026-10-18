pragma Singleton

import QtQuick
import Quickshell
import qs.core.config
import qs.core.format
import qs.services

// View model da aba Desempenho.
Singleton {
    id: root

    // CPU
    readonly property string cpuModel: shortCpu(SystemStats.cpuModel)
    readonly property real cpuUsage: SystemStats.cpuUsage
    readonly property bool hasTemp: isFinite(SystemStats.cpuTemp)
    readonly property string cpuTempText: hasTemp ? `${Math.round(SystemStats.cpuTemp)} °C` : ""
    // Escala de 30 a 100 °C para a barra de temperatura.
    readonly property real cpuTempFraction: hasTemp ? (SystemStats.cpuTemp - 30) / 70 : 0
    readonly property bool cpuHot: hasTemp && SystemStats.cpuTemp >= 85

    // Memória
    readonly property real memFraction: SystemStats.memTotal > 0 ? SystemStats.memUsed / SystemStats.memTotal : 0
    readonly property string memText: Format.usage(SystemStats.memUsed, SystemStats.memTotal)
    readonly property bool hasSwap: SystemStats.swapTotal > 0
    readonly property string swapText: hasSwap ? `Swap: ${Format.bytes(SystemStats.swapUsed)} de ${Format.bytes(SystemStats.swapTotal)}` : ""

    // Discos físicos, prontos para o card (diskView). O card mostra um por vez:
    // o escolhido pelo clique (diskName, que vale até reiniciar o shell e não
    // vai para o config) ou, sem escolha, o primeiro, que é o da raiz.
    readonly property var disks: SystemStats.disks.map(d => diskView(d))
    property string diskName: ""
    readonly property int diskIndex: diskPick(disks, diskName)
    readonly property var disk: disks[diskIndex] ?? null

    // Rede
    readonly property string download: Format.rate(SystemStats.rxRate)
    readonly property string upload: Format.rate(SystemStats.txRate)
    readonly property string totals: `↓ ${Format.bytes(SystemStats.rxTotal)}   ↑ ${Format.bytes(SystemStats.txTotal)}`
    readonly property var rxHistory: SystemStats.rxHistory
    readonly property var txHistory: SystemStats.txHistory
    readonly property real netScale: Math.max(1024, ...SystemStats.rxHistory, ...SystemStats.txHistory)

    readonly property bool showGpu: Config.showGpu

    // GPUs, na ordem do SystemStats, prontas para o card (gpuView). O card
    // mostra uma por vez: a escolhida pelo clique (gpuCard, o "card" dela, que
    // vale até reiniciar o shell) ou, sem escolha, a dedicada.
    readonly property var gpus: SystemStats.gpus.map(g => gpuView(g, SystemStats.cpuTemp))
    property string gpuCard: ""
    readonly property int gpuIndex: gpuPick(gpus, gpuCard)
    readonly property var gpu: gpus[gpuIndex] ?? null

    // O nome da CPU sem o que não ajuda no título: (R)/(TM), a geração
    // ("11th Gen"), "N-Core"/"Six-Core", "CPU", "Processor", o sufixo das APUs
    // ("w/ Radeon 780M Graphics") e a frequência.
    function shortCpu(model: string): string {
        return model.replace(/\((R|TM)\)/gi, "").replace(/\b\d+(st|nd|rd|th) Gen\b/, "").replace(/\b\w+-Core\b/, "").replace(/\b(CPU|Processor)\b/g, "").replace(/ w\/ .*$/, "").replace(/@.*$/, "").replace(/\s+/g, " ").trim() || "Processador";
    }

    // O nome da GPU: do lspci ("Intel Corporation ... [Iris Xe Graphics]"),
    // fica o fabricante e o nome entre colchetes; sem (R)/(TM), sem o "NVIDIA "
    // do começo e o "Laptop GPU" do fim. Sem nome, "desconhecida" (o título
    // já diz "GPU - ").
    function shortGpu(name: string): string {
        return name.replace(/\((R|TM)\)/gi, "").replace(/^(\S+) .*\[([^\[\]]+)\]$/, "$1 $2").replace(/^NVIDIA /, "").replace(/ Laptop GPU$/, "").replace(/\s+/g, " ").trim() || "desconhecida";
    }

    // Uma GPU do SystemStats para o card: com uso, a %; sem uso (a
    // Intel sem fdinfo do DRM), os MHz, com o véu em freq/maxFreq (sem rótulo: a
    // unidade já diz o que é); em repouso, o rótulo
    // "Em repouso", véu vazio e sem temperatura (não acorda a placa). Sem sensor
    // próprio, a GPU integrada (Intel ou AMD sem hwmon) mostra a temperatura do
    // pacote da CPU (`cpuTemp`), porque fica no mesmo chip; a dedicada não herda.
    function gpuView(g: var, cpuTemp: var): var {
        const own = isFinite(g.temp) ? g.temp : (g.vendor === "intel" || g.vendor === "amd") && isFinite(cpuTemp) ? cpuTemp : NaN;
        const asleep = g.state === "suspended";
        const hasUsage = !asleep && isFinite(g.usage);
        const hasFreq = !asleep && !hasUsage && isFinite(g.freq) && isFinite(g.maxFreq) && g.maxFreq > 0;
        const hasTemp = !asleep && isFinite(own);
        return {
            card: g.card,
            name: shortGpu(g.name),
            dedicated: g.vendor !== "intel",
            asleep: asleep,
            hasData: hasUsage || hasFreq,
            label: asleep ? "Em repouso" : "",
            fraction: hasUsage ? g.usage : hasFreq ? g.freq / g.maxFreq : 0,
            value: hasUsage ? `${Math.round(g.usage * 100)}` : hasFreq ? `${g.freq}` : "—",
            unit: hasUsage ? "%" : hasFreq ? "MHz" : "",
            hasTemp: hasTemp,
            tempText: hasTemp ? `${Math.round(own)} °C` : "",
            tempFraction: hasTemp ? (own - 30) / 70 : 0,
            hot: hasTemp && own >= 85
        };
    }

    // O índice da GPU a mostrar: a de card igual a `card` ou, sem ela, a
    // primeira dedicada (senão a primeira); -1 sem GPU.
    function gpuPick(list: var, card: string): int {
        const chosen = list.findIndex(g => g.card === card);
        if (chosen >= 0)
            return chosen;
        return list.length ? Math.max(0, list.findIndex(g => g.dedicated)) : -1;
    }

    // O card da GPU depois da de índice `index`, com volta; "" sem GPU.
    function nextGpu(list: var, index: int): string {
        return list.length ? list[(index + 1) % list.length].card : "";
    }

    function cycleGpu(): void {
        gpuCard = nextGpu(gpus, gpuIndex);
    }

    // Um disco do SystemStats para o card: o nome, a fração usada e
    // "usado / total".
    function diskView(d: var): var {
        return {
            name: d.name,
            fraction: d.size > 0 ? d.used / d.size : 0,
            text: Format.usage(d.used, d.size)
        };
    }

    // O índice do disco a mostrar: o de nome igual a `name` ou, sem ele, o
    // primeiro; -1 sem disco.
    function diskPick(list: var, name: string): int {
        return list.length ? Math.max(0, list.findIndex(d => d.name === name)) : -1;
    }

    // O nome do disco depois do de índice `index`, com volta; "" sem disco.
    function nextDisk(list: var, index: int): string {
        return list.length ? list[(index + 1) % list.length].name : "";
    }

    function cycleDisk(): void {
        diskName = nextDisk(disks, diskIndex);
    }
}
