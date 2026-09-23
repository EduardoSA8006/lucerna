pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Brilho da tela, via brightnessctl. No modo de desenvolvimento (LUCERNA_DEV=1)
// a escrita costuma falhar por falta de sessão do logind; aí o valor é só simulado.
Singleton {
    id: root

    readonly property bool devMode: Quickshell.env("LUCERNA_DEV") === "1"
    property bool available: false
    property string device: ""
    property real value: 0

    // Emitido a cada pedido de ajuste, mesmo que o valor já esteja no limite.
    signal adjusted

    function set(fraction: real): void {
        const percent = Math.round(Math.max(0.01, Math.min(1, fraction)) * 100);
        writer.target = percent / 100;
        writer.exec(["brightnessctl", "-m", "-c", "backlight", "set", `${percent}%`]);
        adjusted();
    }

    function change(delta: real): void {
        if (available)
            set(value + delta);
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

    IpcHandler {
        target: "brightness"

        function up(): void {
            root.change(0.05);
        }

        function down(): void {
            root.change(-0.05);
        }

        function set(percent: int): void {
            root.set(percent / 100);
        }
    }
}
