pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core.config

// View model de Configurações → Tela e ociosidade. Os tempos ficam na config;
// a feature idle aplica.
Singleton {
    id: root

    readonly property var stages: [
        { id: "dim", label: "Escurecer a tela", icon: "brightness_low" },
        { id: "off", label: "Desligar a tela", icon: "desktop_access_disabled" },
        { id: "lock", label: "Bloquear", icon: "lock" },
        { id: "suspend", label: "Suspender", icon: "bedtime" }
    ]
    readonly property var timeOptions: [
        { label: "Nunca", value: 0 },
        { label: "30 segundos", value: 30 },
        { label: "1 minuto", value: 60 },
        { label: "2 minutos", value: 120 },
        { label: "3 minutos", value: 180 },
        { label: "4 minutos", value: 240 },
        { label: "5 minutos", value: 300 },
        { label: "10 minutos", value: 600 },
        { label: "15 minutos", value: 900 },
        { label: "20 minutos", value: 1200 },
        { label: "30 minutos", value: 1800 },
        { label: "45 minutos", value: 2700 },
        { label: "1 hora", value: 3600 },
        { label: "2 horas", value: 7200 }
    ]

    function timeOf(power: string, stage: string): int {
        return Number((power === "battery" ? Config.idleBattery : Config.idleAC)?.[stage] ?? 0);
    }

    // Um tempo fora da lista (editado à mão) entra nela para aparecer escolhido.
    function optionsFor(power: string, stage: string): var {
        const v = timeOf(power, stage);
        if (timeOptions.some(o => o.value === v))
            return timeOptions;
        return timeOptions.concat([{ label: `${Math.round(v / 60)} minutos`, value: v }]).sort((a, b) => a.value - b.value);
    }

    function setTime(power: string, stage: string, seconds: int): void {
        const key = power === "battery" ? "idleBattery" : "idleAC";
        const all = Object.assign({}, Config[key] ?? {});
        all[stage] = seconds;
        Config[key] = all;
    }

    // O hypridle rodando junto faria cada coisa duas vezes.
    property bool hypridleRunning: false

    function check(): void {
        probe.running = true;
    }

    Process {
        id: probe

        command: ["pgrep", "-x", "hypridle"]
        onExited: code => root.hypridleRunning = code === 0
    }
}
