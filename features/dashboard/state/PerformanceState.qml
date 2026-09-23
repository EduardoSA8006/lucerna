pragma Singleton

import QtQuick
import Quickshell
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
    readonly property var cpuHistory: SystemStats.cpuHistory
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

    // GPUs: a mais "interessante" primeiro (dedicada ativa > integrada > dedicada em repouso).
    readonly property var gpus: SystemStats.gpus.map(g => {
        const asleep = g.state === "suspended";
        const hasUsage = isFinite(g.usage);
        const hasFreq = isFinite(g.freq) && isFinite(g.maxFreq) && g.maxFreq > 0;
        return {
            name: g.name.replace(/^NVIDIA /, "").replace(/ Laptop GPU$/, ""),
            vendor: g.vendor,
            asleep: asleep,
            fraction: asleep ? 0 : hasUsage ? g.usage : hasFreq ? g.freq / g.maxFreq : 0,
            valueText: asleep ? "em repouso" : hasUsage ? Format.percent(g.usage) : hasFreq ? `${g.freq} MHz` : "sem dados",
            detail: asleep ? "Desligada para economizar energia"
                : [isFinite(g.temp) ? `${g.temp} °C` : "", hasUsage ? "" : hasFreq ? `de ${g.maxFreq} MHz` : "", g.vendor === "intel" ? "uso não disponível sem root" : ""].filter(x => x).join(" · ")
        };
    }).sort((a, b) => (a.asleep - b.asleep) || ((b.vendor !== "intel") - (a.vendor !== "intel")))
}
