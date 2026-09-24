pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Brilho das telas: a integrada pelo brightnessctl (backlight) e os monitores
// externos por DDC/CI, pelo ddcutil (precisa do módulo i2c-dev). As teclas
// ajustam a tela em foco. No modo de desenvolvimento (LUCERNA_DEV=1) a escrita
// do backlight costuma falhar por falta de sessão do logind; aí o valor é só
// simulado.
Singleton {
    id: root

    readonly property bool devMode: Quickshell.env("LUCERNA_DEV") === "1"

    // Tela integrada (backlight)
    property bool available: false
    property string device: ""
    property real value: 0

    // Monitores externos: [{ bus, output ("HDMI-A-1" ou ""), label, value, max }]
    property var ddc: []
    property bool ddcAvailable: false

    // Todas as telas com brilho ajustável: [{ id, label, output, value }].
    // A integrada tem id "backlight"; as externas, "ddc:<barramento>".
    readonly property var screens: (available ? [{ id: "backlight", label: "Tela integrada", output: "", value: value }] : [])
        .concat(ddc.map(d => ({ id: `ddc:${d.bus}`, label: d.label, output: d.output, value: d.value })))
    readonly property bool anyAvailable: screens.length > 0

    // O último ajustado, para o OSD mostrar o valor certo.
    property string lastId: "backlight"
    readonly property real shownValue: screens.find(s => s.id === lastId)?.value ?? value

    // Emitido a cada pedido de ajuste, mesmo que o valor já esteja no limite.
    signal adjusted

    function set(fraction: real): void {
        setScreen("backlight", fraction);
    }

    function setScreen(id: string, fraction: real): void {
        const f = Math.max(0.01, Math.min(1, fraction));
        lastId = id;
        if (id === "backlight") {
            const percent = Math.round(f * 100);
            writer.target = percent / 100;
            writer.exec(["brightnessctl", "-m", "-c", "backlight", "set", `${percent}%`]);
        } else if (id.startsWith("ddc:")) {
            const bus = Number(id.slice(4));
            ddc = ddc.map(d => d.bus === bus ? Object.assign({}, d, { value: f }) : d);
            ddcWriter.queue(bus, Math.round(f * (ddc.find(d => d.bus === bus)?.max ?? 100)));
        }
        adjusted();
    }

    // Tela em foco: a externa desse monitor, se tiver DDC; senão a integrada;
    // sem integrada, o primeiro externo.
    function focusedId(): string {
        const name = Hyprland.focusedMonitor?.name ?? "";
        const external = ddc.find(d => d.output && d.output === name);
        if (external)
            return `ddc:${external.bus}`;
        if (available)
            return "backlight";
        return ddc.length ? `ddc:${ddc[0].bus}` : "";
    }

    function change(delta: real): void {
        const id = focusedId();
        const current = screens.find(s => s.id === id);
        if (current)
            setScreen(id, current.value + delta);
    }

    function parse(text: string): bool {
        // intel_backlight,backlight,19200,40%,48000
        const fields = text.trim().split("\n")[0]?.split(",") ?? [];
        if (fields.length < 5 || fields[1] !== "backlight")
            return false;
        device = fields[0];
        value = Number(fields[2]) / Number(fields[4]);
        available = true;
        return true;
    }

    Process {
        running: true
        command: ["brightnessctl", "-m", "-c", "backlight", "info"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Process {
        id: writer

        property real target

        stdout: StdioCollector {
            id: output
        }
        onExited: code => {
            if (code === 0 && root.parse(output.text))
                return;
            if (root.devMode)
                root.value = target;
            else
                console.warn("Brightness: brightnessctl falhou com código", code);
        }
    }

    // DDC/CI: detecta os monitores e lê o brilho (VCP 10) de cada um.
    function refreshDdc(): void {
        ddcProbe.running = true;
    }

    Process {
        id: ddcProbe

        running: true
        command: ["sh", "-c", [
            "command -v ddcutil >/dev/null || exit 0",
            "tab=$(printf '\\t')",
            "ddcutil detect --brief 2>/dev/null | awk '/^Display/{ok=1} /^Invalid/{ok=0} ok && /I2C bus:/{bus=$3} ok && /DRM connector:/{c=$3} ok && /Monitor:/{sub(/^ *Monitor: */, \"\"); print bus \"\\t\" c \"\\t\" $0; ok=0}' | while IFS=\"$tab\" read -r bus conn mon; do",
            "  n=${bus##*-}; v=$(ddcutil --bus \"$n\" getvcp 10 --brief 2>/dev/null); printf '%s\\t%s\\t%s\\t%s\\n' \"$n\" \"$conn\" \"$mon\" \"$v\"",
            "done"
        ].join("\n")]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = [];
                for (const line of text.split("\n")) {
                    const [bus, conn, mon, vcp] = line.split("\t");
                    // VCP 10 C 70 100
                    const m = /VCP 10 C (\d+) (\d+)/.exec(vcp ?? "");
                    if (!bus || !m)
                        continue;
                    const [maker, model] = (mon ?? "").split(":");
                    list.push({
                        bus: Number(bus),
                        output: (conn ?? "").replace(/^card\d+-/, ""),
                        label: (model || maker || `Monitor ${bus}`).trim(),
                        value: Number(m[1]) / Math.max(1, Number(m[2])),
                        max: Number(m[2])
                    });
                }
                root.ddc = list;
                root.ddcAvailable = list.length > 0;
            }
        }
    }

    // Escrever por DDC é lento (décimos de segundo): com uma escrita em
    // andamento, guarda só o último valor de cada monitor.
    Process {
        id: ddcWriter

        property var pending: ({})
        property int bus: -1

        function queue(b: int, raw: int): void {
            const p = Object.assign({}, pending);
            p[b] = raw;
            pending = p;
            next();
        }

        function next(): void {
            if (running)
                return;
            const keys = Object.keys(pending);
            if (!keys.length)
                return;
            bus = Number(keys[0]);
            const raw = pending[keys[0]];
            const p = Object.assign({}, pending);
            delete p[keys[0]];
            pending = p;
            command = ["ddcutil", "--bus", String(bus), "--noverify", "setvcp", "10", String(raw)];
            running = true;
        }

        onExited: code => {
            if (code !== 0)
                console.warn("Brightness: ddcutil falhou no barramento", bus, "com código", code);
            next();
        }
    }

    // Monitor entrou ou saiu: procura de novo (o ddcutil leva uns segundos).
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (["monitoradded", "monitoraddedv2", "monitorremoved", "monitorremovedv2"].includes(event.name))
                ddcDelay.restart();
        }
    }

    Timer {
        id: ddcDelay

        interval: 2500
        onTriggered: root.refreshDdc()
    }

    IpcHandler {
        target: "brightness"

        // A tela em foco.
        function up(): void {
            root.change(0.05);
        }

        function down(): void {
            root.change(-0.05);
        }

        function set(percent: int): void {
            const id = root.focusedId();
            if (id)
                root.setScreen(id, percent / 100);
        }

        // Uma tela específica: "backlight" ou "ddc:<barramento>" (ver `list`).
        function setFor(id: string, percent: int): void {
            root.setScreen(id, percent / 100);
        }

        // Todas: "Tela integrada: 40%, LG ULTRAWIDE: 100%".
        function list(): string {
            return root.screens.map(s => `${s.label} (${s.id}${s.output ? `, ${s.output}` : ""}): ${Math.round(s.value * 100)}%`).join("\n");
        }
    }
}
