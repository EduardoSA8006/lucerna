pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Uso do sistema lido direto do kernel (/proc e /sys), sem bibliotecas externas.
// Só coleta enquanto `active` for verdadeiro (quem mostra os dados liga), a
// cada `interval` ms. Disco usa `df` (coreutils) e `lsblk` (util-linux); GPU, services/scripts/gpu-status.sh.
Singleton {
    id: root

    property bool active: false
    property int interval: 2000
    // A GPU pode ser desligada (nem a consulta leve ao estado da placa roda).
    property bool gpuEnabled: true

    onGpuEnabledChanged: {
        if (!gpuEnabled) {
            gpus = [];
            resetDrm();
        }
    }

    // Parado, a leitura anterior fica velha: ao voltar, o primeiro delta
    // cobriria minutos e o uso sairia baixo.
    onActiveChanged: {
        if (!active)
            resetDrm();
    }
    readonly property int historyLength: 30

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

    property var lastCpu: null
    property var lastNet: null
    // Leitura anterior do fdinfo do DRM e o uso (0-1) de cada GPU pelo PCI.
    property var lastDrm: null
    property var drmUsage: ({})
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
                usage: usage !== "" ? Number(usage) / 100 : (drmUsage[pci] ?? NaN),
                temp: temp !== "" ? Number(temp) : NaN,
                freq: freq !== "" ? Number(freq) : NaN,
                maxFreq: max !== "" ? Number(max) : NaN
            };
        });
    }

    // Saída do drm-fdinfo.sh: { ts (ns), clients: { "pdev/id": { driver, pdev, v: { chave: valor } } } }.
    function parseDrm(text: string): var {
        const snap = { ts: NaN, clients: ({}) };
        for (const line of text.split("\n")) {
            const f = line.split("|");
            if (f[0] === "T") {
                snap.ts = Number(f[1]);
            } else if (f.length >= 4 && f[2] !== "") {
                const v = ({});
                for (const kv of f[3].split(",")) {
                    const i = kv.indexOf("=");
                    const raw = kv.slice(i + 1);
                    // Linha malformada ou valor que não é número: fora, para
                    // nenhum NaN contaminar o Math.max da conta.
                    if (i > 0 && raw !== "" && isFinite(Number(raw)))
                        v[kv.slice(0, i)] = Number(raw);
                }
                snap.clients[`${f[1]}/${f[2]}`] = { driver: f[0], pdev: f[1], v: v };
            }
        }
        return snap;
    }

    // Uso (0-1) da GPU `pdev` entre duas leituras do fdinfo: a classe de motor mais
    // ocupada, como o intel_gpu_top. Só entram os clientes presentes nas duas
    // leituras: quem nasce e morre dentro da janela não é contado (o uso fica
    // um pouco subestimado). i915: Δns do engine-<classe> / (Δns da janela ×
    // engine-capacity-<classe>, padrão 1). xe: Δcycles-<classe> /
    // Δtotal-cycles-<classe>. NaN sem leitura anterior, sem janela, com janela
    // maior que 3 intervalos (leitura velha) ou sem cliente em comum; contador
    // que volta conta 0.
    function drmBusy(prev: var, cur: var, pdev: string): real {
        if (!prev || !cur || !(cur.ts > prev.ts))
            return NaN;
        const window = cur.ts - prev.ts;
        if (window > 3 * interval * 1e6)
            return NaN;
        const ns = ({}), cap = ({}), cycles = ({}), total = ({});
        let common = 0;
        for (const key in cur.clients) {
            const c = cur.clients[key], p = prev.clients[key];
            if (!p || c.pdev !== pdev)
                continue;
            common++;
            for (const name in c.v) {
                if (name.startsWith("engine-capacity-")) {
                    cap[name.slice(16)] = Math.max(cap[name.slice(16)] ?? 0, c.v[name]);
                    continue;
                }
                const d = Math.max(0, c.v[name] - (p.v[name] ?? c.v[name]));
                if (name.startsWith("engine-"))
                    ns[name.slice(7)] = (ns[name.slice(7)] ?? 0) + d;
                else if (name.startsWith("total-cycles-"))
                    total[name.slice(13)] = Math.max(total[name.slice(13)] ?? 0, d);
                else if (name.startsWith("cycles-"))
                    cycles[name.slice(7)] = (cycles[name.slice(7)] ?? 0) + d;
            }
        }
        if (!common)
            return NaN;
        let busy = 0;
        for (const name in ns)
            busy = Math.max(busy, ns[name] / (window * (cap[name] > 0 ? cap[name] : 1)));
        for (const name in cycles)
            if (total[name] > 0)
                busy = Math.max(busy, cycles[name] / total[name]);
        return Math.min(1, busy);
    }

    function resetDrm(): void {
        lastDrm = null;
        drmUsage = ({});
    }

    // Lê o fdinfo só com uma Intel acordada (em repouso o uso é 0 e a leitura é
    // desperdício); sem ela, esquece a leitura anterior.
    function probeDrm(): void {
        if (gpus.some(g => g.vendor === "intel" && g.state === "active")) {
            if (!drmProbe.running)
                drmProbe.running = true;
        } else {
            resetDrm();
        }
    }

    // Guarda a leitura e atualiza o uso das GPUs Intel (as outras trazem o uso no gpu-status).
    function applyDrm(text: string): void {
        if (!gpuEnabled)
            return;
        const cur = parseDrm(text);
        const next = ({});
        for (const g of gpus) {
            if (g.vendor !== "intel")
                continue;
            const u = drmBusy(lastDrm, cur, g.pci);
            if (isFinite(u))
                next[g.pci] = u;
        }
        lastDrm = cur;
        drmUsage = next;
        gpus = gpus.map(g => !(g.pci in next) ? g : Object.assign({}, g, { usage: next[g.pci] }));
    }

    // Saída do lsblk -lnpo NAME,TYPE,PKNAME: { caminho: { type, parent } }.
    function parseBlock(text: string): var {
        const blocks = ({});
        for (const line of text.split("\n")) {
            const f = line.trim().split(/\s+/);
            if (f.length >= 2)
                blocks[f[0]] = { type: f[1], parent: f[2] ?? "" };
        }
        return blocks;
    }

    // O nome curto do disco físico de uma origem do df ("/dev/nvme0n1p2" →
    // "nvme0n1"), subindo pelos pais (LUKS, LVM) até o tipo "disk". Fora do
    // lsblk, o próprio nome; "" para o que não é dispositivo (tmpfs, overlay,
    // rede), para loop e zram.
    function diskOf(blocks: var, source: string): string {
        if (!source.startsWith("/dev/") || /^\/dev\/(loop|zram|ram)\d/.test(source))
            return "";
        let dev = source;
        for (let step = 0; step < 8; step++) {
            const b = blocks[dev];
            if (!b)
                return step === 0 ? source.replace(/^.*\//, "") : "";
            if (b.type === "disk")
                return dev.replace(/^.*\//, "");
            if (!b.parent)
                return "";
            dev = b.parent;
        }
        return "";
    }

    // Saída do df (origem, tamanho, usado e ponto de montagem), uma linha "--" e
    // a do lsblk. Cada partição conta uma vez (montada em vários lugares, os
    // números são os mesmos); as de um disco são somadas.
    function parseDf(text: string): void {
        const parts = text.split("\n--\n");
        const blocks = parseBlock(parts[1] ?? "");
        const seen = new Set();
        const byName = ({});
        const list = [];
        for (const line of parts[0].split("\n").slice(1)) {
            const f = line.trim().split(/\s+/);
            if (f.length < 4)
                continue;
            const name = diskOf(blocks, f[0]);
            const root = f.slice(3).join(" ") === "/";
            if (!name || seen.has(f[0])) {
                if (name && root)
                    byName[name].root = true;
                continue;
            }
            seen.add(f[0]);
            if (!byName[name]) {
                byName[name] = { name: name, size: 0, used: 0, root: false };
                list.push(byName[name]);
            }
            byName[name].size += Number(f[1]);
            byName[name].used += Number(f[2]);
            byName[name].root = byName[name].root || root;
        }
        disks = list.filter(d => d.root).concat(list.filter(d => !d.root));
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

        // -l: só sistemas de arquivos locais (um de rede travado não trava a
        // leitura).
        command: ["sh", "-c", "df -lB1 --output=source,size,used,target; echo --; lsblk -lnpo NAME,TYPE,PKNAME"]
        stdout: StdioCollector {
            onStreamFinished: root.parseDf(text)
        }
    }

    Process {
        id: gpuProbe

        command: ["sh", Quickshell.shellPath("services/scripts/gpu-status.sh")]
        stdout: StdioCollector {
            onStreamFinished: {
                root.parseGpus(text);
                root.probeDrm();
            }
        }
    }

    Process {
        id: drmProbe

        command: ["sh", Quickshell.shellPath("services/scripts/drm-fdinfo.sh")]
        stdout: StdioCollector {
            onStreamFinished: {
                // Resposta que chega depois de parar não vale (a leitura ficaria velha).
                if (root.active)
                    root.applyDrm(text);
            }
        }
    }
}
