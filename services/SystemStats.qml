pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Uso do sistema lido direto do kernel (/proc e /sys), sem bibliotecas externas.
// Só coleta enquanto `active` for verdadeiro (quem mostra os dados liga), a
// cada `interval` ms. Disco usa `df` (coreutils); GPU, services/scripts/gpu-status.sh.
Singleton {
    id: root

    property bool active: false
    property int interval: 2000
    // A GPU pode ser desligada (nem a consulta leve ao estado da placa roda).
    property bool gpuEnabled: true

    onGpuEnabledChanged: {
        if (!gpuEnabled)
            gpus = [];
    }
    readonly property int historyLength: 30

    // CPU
    property string cpuModel: ""
    property int cpuThreads: 0
    property real cpuUsage: 0
    property real cpuTemp: NaN
    property var cpuHistory: []

    // Memória, em bytes
    property real memTotal: 0
    property real memUsed: 0
    property real swapTotal: 0
    property real swapUsed: 0

    // Discos: [{ mount, size, used }], em bytes
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

    property var lastCpu: null
    property var lastNet: null
    property string tempPath: ""

    function push(list: var, value: real): var {
        const next = list.concat([value]);
        return next.length > historyLength ? next.slice(next.length - historyLength) : next;
    }

    function sample(): void {
        stat.reload();
        meminfo.reload();
        netdev.reload();
        uptimeFile.reload();
        if (tempPath)
            tempFile.reload();
        if (!df.running)
            df.running = true;
        if (gpuEnabled && !gpuProbe.running)
            gpuProbe.running = true;
    }

    function parseStat(text: string): void {
        const fields = text.split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
        const idle = fields[3] + (fields[4] ?? 0);
        const total = fields.reduce((a, b) => a + b, 0);
        if (lastCpu && total > lastCpu.total) {
            cpuUsage = Math.max(0, Math.min(1, 1 - (idle - lastCpu.idle) / (total - lastCpu.total)));
            cpuHistory = push(cpuHistory, cpuUsage);
        }
        lastCpu = { idle: idle, total: total };
    }

    function parseMeminfo(text: string): void {
        const kb = key => Number(text.match(new RegExp(`^${key}:\\s+(\\d+)`, "m"))?.[1] ?? 0) * 1024;
        memTotal = kb("MemTotal");
        memUsed = memTotal - kb("MemAvailable");
        swapTotal = kb("SwapTotal");
        swapUsed = swapTotal - kb("SwapFree");
    }

    // Ignora loopback e interfaces virtuais (containers, bridges, VPN).
    function isPhysical(name: string): bool {
        return !/^(lo|docker|veth|br-|virbr|vnet|tun|tap|wg|zt)/.test(name);
    }

    function parseNetdev(text: string): void {
        let rx = 0, tx = 0;
        for (const line of text.split("\n").slice(2)) {
            const [name, data] = line.split(":");
            if (!data || !isPhysical(name.trim()))
                continue;
            const f = data.trim().split(/\s+/).map(Number);
            rx += f[0];
            tx += f[8];
        }
        const now = Date.now();
        if (lastNet && now > lastNet.time) {
            const dt = (now - lastNet.time) / 1000;
            rxRate = Math.max(0, (rx - lastNet.rx) / dt);
            txRate = Math.max(0, (tx - lastNet.tx) / dt);
            rxHistory = push(rxHistory, rxRate);
            txHistory = push(txHistory, txRate);
        }
        rxTotal = rx;
        txTotal = tx;
        lastNet = { rx: rx, tx: tx, time: now };
    }

    function parseCpuinfo(text: string): void {
        cpuModel = (text.match(/^model name\s*:\s*(.+)$/m)?.[1] ?? "").replace(/\s+/g, " ").trim();
        cpuThreads = (text.match(/^processor\s*:/gm) ?? []).length;
    }

    // Saída do probe: "<dir> <nome>" por hwmon. Prefere o sensor do pacote da CPU.
    function pickTempSensor(text: string): void {
        const chips = text.trim().split("\n").map(l => l.split(" "));
        for (const want of ["coretemp", "k10temp", "zenpower", "cpu_thermal", "acpitz"]) {
            const chip = chips.find(c => c[1] === want);
            if (chip) {
                tempPath = `${chip[0]}/temp1_input`;
                return;
            }
        }
    }

    function parseGpus(text: string): void {
        gpus = text.trim().split("\n").filter(l => l).map(line => {
            const [card, vendor, pci, state, name, usage, temp, freq, max] = line.split("|");
            const generic = { nvidia: "NVIDIA", amd: "AMD Radeon", intel: "Intel (integrada)" };
            return {
                card: card,
                vendor: vendor,
                pci: pci,
                state: state,
                name: name || generic[vendor] || vendor,
                usage: usage !== "" ? Number(usage) / 100 : NaN,
                temp: temp !== "" ? Number(temp) : NaN,
                freq: freq !== "" ? Number(freq) : NaN,
                maxFreq: max !== "" ? Number(max) : NaN
            };
        });
    }

    function parseDf(text: string): void {
        const seen = new Set();
        disks = text.trim().split("\n").slice(1).map(l => l.trim().split(/\s+/)).filter(f => {
            if (f.length < 3 || seen.has(f[0]))
                return false;
            seen.add(f[0]);
            return true;
        }).map(f => ({ mount: f[0], size: Number(f[1]), used: Number(f[2]) }));
    }

    Timer {
        running: root.active
        repeat: true
        interval: root.interval
        triggeredOnStart: true
        onTriggered: root.sample()
    }

    FileView {
        id: stat

        path: "/proc/stat"
        onLoaded: root.parseStat(text())
    }

    FileView {
        id: meminfo

        path: "/proc/meminfo"
        onLoaded: root.parseMeminfo(text())
    }

    FileView {
        id: netdev

        path: "/proc/net/dev"
        onLoaded: root.parseNetdev(text())
    }

    FileView {
        id: uptimeFile

        path: "/proc/uptime"
        onLoaded: root.uptime = Number(text().split(" ")[0])
    }

    FileView {
        path: "/proc/cpuinfo"
        onLoaded: root.parseCpuinfo(text())
    }

    FileView {
        path: "/proc/sys/kernel/hostname"
        onLoaded: root.hostname = text().trim()
    }

    FileView {
        path: "/proc/sys/kernel/osrelease"
        onLoaded: root.kernel = text().trim()
    }

    FileView {
        path: "/etc/os-release"
        onLoaded: root.osName = text().match(/^PRETTY_NAME="?([^"\n]*)"?/m)?.[1] ?? ""
    }

    Process {
        running: true
        command: ["qs", "--version"]
        stdout: StdioCollector {
            onStreamFinished: root.quickshellVersion = text.match(/\d+\.\d+\.\d+/)?.[0] ?? text.trim()
        }
    }

    FileView {
        id: tempFile

        path: root.tempPath
        printErrors: false
        onLoaded: root.cpuTemp = Number(text()) / 1000
    }

    Process {
        running: true
        command: ["sh", "-c", "for d in /sys/class/hwmon/hwmon*; do printf '%s %s\\n' \"$d\" \"$(cat \"$d/name\" 2>/dev/null)\"; done"]
        stdout: StdioCollector {
            onStreamFinished: root.pickTempSensor(text)
        }
    }

    Process {
        id: df

        command: ["df", "-B1", "--output=target,size,used", "/", "/home"]
        stdout: StdioCollector {
            onStreamFinished: root.parseDf(text)
        }
    }

    Process {
        id: gpuProbe

        command: ["sh", Quickshell.shellPath("services/scripts/gpu-status.sh")]
        stdout: StdioCollector {
            onStreamFinished: root.parseGpus(text)
        }
    }
}
