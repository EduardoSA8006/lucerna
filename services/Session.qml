pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Bloqueio e energia. No modo de desenvolvimento (LUCERNA_DEV=1) suspender,
// reiniciar e desligar são só simulados: dentro do container, com o D-Bus do
// sistema montado, o comando chegaria ao host.
Singleton {
    id: root

    readonly property bool devMode: Quickshell.env("LUCERNA_DEV") === "1"
    property bool locked: false

    function lock(): void {
        locked = true;
    }

    function unlock(): void {
        locked = false;
    }

    function suspend(): void {
        lock();
        run(["systemctl", "suspend"], "Suspender");
    }

    function reboot(): void {
        run(["systemctl", "reboot"], "Reiniciar");
    }

    function poweroff(): void {
        run(["systemctl", "poweroff"], "Desligar");
    }

    function run(command: var, label: string): void {
        if (devMode) {
            console.info(`Session: ${label} simulado (${command.join(" ")})`);
            Quickshell.execDetached(["notify-send", "-a", "Lucerna", "Modo de desenvolvimento", `${label}: ação simulada.`]);
            return;
        }
        Quickshell.execDetached(command);
    }

    IpcHandler {
        target: "session"

        function lock(): void {
            root.lock();
        }
    }
}
