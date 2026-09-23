pragma Singleton

import QtQuick
import Quickshell

// Modo de desenvolvimento (LUCERNA_DEV=1, definido pelo dev/run.sh). No
// container, o D-Bus do sistema é o do host: ações que mudam o sistema
// (desligar, trocar de rede, ligar o Bluetooth...) chegariam à máquina real.
// Nesse modo os serviços só as simulam, com um aviso.
Singleton {
    readonly property bool active: Quickshell.env("LUCERNA_DEV") === "1"

    // Registra e avisa a ação simulada. Retorna true se simulou (o chamador para aí).
    function simulate(label: string): bool {
        if (!active)
            return false;
        console.info(`DevMode: ${label} (simulado)`);
        Quickshell.execDetached(["notify-send", "-a", "Lucerna", "Modo de desenvolvimento", `${label}: ação simulada.`]);
        return true;
    }
}
