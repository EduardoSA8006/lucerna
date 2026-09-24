pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Temperatura de cor da tela pelo hyprsunset, que usa a CTM do Hyprland (feita
// no hardware; não custa GPU, e por isso não aparece em capturas). O shell
// abre o hyprsunset só enquanto `wanted`; se já houver um rodando (do usuário),
// usa esse e não o fecha. As mudanças vão pelo `hyprctl hyprsunset`, e o
// Hyprland anima a troca.
Singleton {
    id: root

    // Quem usa decide: manter o hyprsunset aberto e a temperatura (0 = sem filtro).
    property bool wanted: false
    property int temperature: 0

    property bool available: false
    // Um hyprsunset que não foi o shell que abriu.
    property bool external: false
    readonly property bool ready: external || daemon.running

    function apply(): void {
        if (!ready)
            return;
        ctl.command = temperature > 0 ? ["hyprctl", "hyprsunset", "temperature", String(temperature)] : ["hyprctl", "hyprsunset", "identity"];
        ctl.running = false;
        ctl.running = true;
    }

    onTemperatureChanged: apply()
    onReadyChanged: apply()
    // Desligar fecha o daemon, o que devolve as cores (o Hyprland solta a CTM).
    onWantedChanged: {
        if (wanted && available)
            probe.running = true;
        else if (!wanted && daemon.running)
            daemon.running = false;
    }

    // Tem o hyprsunset instalado?
    Process {
        running: true
        command: ["sh", "-c", "command -v hyprsunset"]
        onExited: code => {
            root.available = code === 0;
            if (root.available && root.wanted)
                probe.running = true;
        }
    }

    // Já tem um rodando? Abrir um segundo derruba o socket do primeiro.
    Process {
        id: probe

        command: ["hyprctl", "hyprsunset", "temperature"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.external = /^\d+/.test(text.trim());
                if (!root.external && root.wanted)
                    daemon.running = true;
            }
        }
    }

    Process {
        id: daemon

        property real startedAt: 0

        // Sai junto com o shell (sem ficar órfão num reinício).
        command: ["setpriv", "--pdeathsig", "TERM", "hyprsunset", "-i"]

        // O socket leva um instante para aparecer.
        onStarted: {
            startedAt = Date.now();
            settle.restart();
        }
        // Caiu sozinho: tenta de novo, mas não em laço se cair logo ao abrir.
        onExited: {
            if (root.wanted && Date.now() - startedAt > 10000)
                probe.running = true;
        }
    }

    Timer {
        id: settle

        interval: 400
        onTriggered: root.apply()
    }

    Process {
        id: ctl
    }
}
