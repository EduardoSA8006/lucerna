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
    readonly property string cpuModel: SystemStats.cpuModel.replace(/\((R|TM)\)/g, "").replace(/ CPU/, "") || "Processador"
    readonly property string cpuThreads: SystemStats.cpuThreads ? `${SystemStats.cpuThreads} threads` : ""
    readonly property real cpuUsage: SystemStats.cpuUsage
    readonly property string cpuUsageText: Format.percent(cpuUsage)
    readonly property bool hasTemp: isFinite(SystemStats.cpuTemp)
    readonly property string cpuTempText: hasTemp ? `${Math.round(SystemStats.cpuTemp)} °C` : "—"
    // Escala de 30 a 100 °C para a barra de temperatura.
    readonly property real cpuTempFraction: hasTemp ? (SystemStats.cpuTemp - 30) / 70 : 0
    readonly property bool cpuHot: hasTemp && SystemStats.cpuTemp >= 85

    // Memória
    readonly property real memFraction: SystemStats.memTotal > 0 ? SystemStats.memUsed / SystemStats.memTotal : 0
    readonly property string memText: `${Format.bytes(SystemStats.memUsed)} de ${Format.bytes(SystemStats.memTotal)}`
    readonly property bool hasSwap: SystemStats.swapTotal > 0
    readonly property string swapText: hasSwap ? `Swap: ${Format.bytes(SystemStats.swapUsed)} de ${Format.bytes(SystemStats.swapTotal)}` : ""

    // Discos
    readonly property var disks: SystemStats.disks.map(d => ({
        mount: d.mount,
        fraction: d.size > 0 ? d.used / d.size : 0,
        text: `${Format.bytes(d.used)} de ${Format.bytes(d.size)}`
    }))

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
    readonly property var gpus: SystemStats.gpus.map(g => gpuView(g))
    property string gpuCard: ""
    readonly property int gpuIndex: gpuPick(gpus, gpuCard)
    readonly property var gpu: gpus[gpuIndex] ?? null

    // Uma GPU do SystemStats para o card: com uso, "Uso" e a %; sem uso (a
    // Intel sem root), "Clock" e os MHz, com o véu em freq/maxFreq; em
    // repouso, "Em repouso", véu vazio e sem temperatura (não acorda a placa).
    function gpuView(g: var): var {
        const asleep = g.state === "suspended";
        const hasUsage = !asleep && isFinite(g.usage);
        const hasFreq = !asleep && !hasUsage && isFinite(g.freq) && isFinite(g.maxFreq) && g.maxFreq > 0;
        const hasTemp = !asleep && isFinite(g.temp);
        return {
            card: g.card,
            name: g.name.replace(/^NVIDIA /, "").replace(/ Laptop GPU$/, ""),
            dedicated: g.vendor !== "intel",
            asleep: asleep,
            label: asleep ? "Em repouso" : hasFreq ? "Clock" : "Uso",
            fraction: hasUsage ? g.usage : hasFreq ? g.freq / g.maxFreq : 0,
            value: hasUsage ? `${Math.round(g.usage * 100)}` : hasFreq ? `${g.freq}` : "—",
            unit: hasUsage ? "%" : hasFreq ? "MHz" : "",
            hasTemp: hasTemp,
            tempText: hasTemp ? `${Math.round(g.temp)} °C` : "",
            tempFraction: hasTemp ? (g.temp - 30) / 70 : 0,
            hot: hasTemp && g.temp >= 85
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
}
