pragma Singleton

import QtQuick
import Quickshell
import qs.core.panels
import qs.core.widgets
import qs.services

// View model do menu de energia. Ações destrutivas pedem um segundo clique.
Singleton {
    id: root

    readonly property bool open: Panels.isOpen("power")
    readonly property var screen: Hypr.focusedScreen
    readonly property bool devMode: Session.devMode

    readonly property var actions: [
        { id: "lock", name: "Bloquear", icon: Icons.lock, confirm: false },
        { id: "suspend", name: "Suspender", icon: Icons.sleep, confirm: false },
        { id: "logout", name: "Sair", icon: Icons.logout, confirm: true },
        { id: "reboot", name: "Reiniciar", icon: Icons.restart, confirm: true },
        { id: "poweroff", name: "Desligar", icon: Icons.power, confirm: true }
    ]

    // Ação esperando confirmação.
    property string pending: ""

    onOpenChanged: pending = ""

    function close(): void {
        Panels.close();
    }

    function cancel(): void {
        pending = "";
    }

    function trigger(id: string): void {
        const action = actions.find(a => a.id === id);
        if (!action)
            return;
        if (action.confirm && pending !== id) {
            pending = id;
            return;
        }
        Panels.close();
        switch (id) {
        case "lock":
            Session.lock();
            break;
        case "suspend":
            Session.suspend();
            break;
        case "logout":
            Hypr.exit();
            break;
        case "reboot":
            Session.reboot();
            break;
        case "poweroff":
            Session.poweroff();
            break;
        }
    }
}
