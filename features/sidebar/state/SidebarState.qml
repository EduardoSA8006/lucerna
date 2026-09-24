pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core.config
import qs.core.panels
import qs.core.theme
import qs.core.widgets
import qs.services

// View model da central lateral: abertura, lado da tela e seções. Cada seção
// só liga o que precisa (busca de redes, de dispositivos) enquanto está à mostra.
Singleton {
    id: root

    readonly property bool open: Panels.isOpen("sidebar")
    readonly property var screen: Hypr.focusedScreen
    readonly property bool onLeft: Config.sidebarSide === "left"
    readonly property real topOffset: Panels.topInset

    readonly property var sections: [
        { id: "wifi", icon: Icons.wifiOn, label: "Wi-Fi" },
        { id: "bluetooth", icon: Icons.bluetooth, label: "Bluetooth" },
        { id: "sound", icon: Icons.sound, label: "Som" },
        { id: "notifications", icon: Icons.bell, label: "Avisos" },
        { id: "battery", icon: Icons.battery[7], label: "Bateria" },
        { id: "display", icon: Icons.brightnessMedium, label: "Tela" }
    ]
    readonly property int currentIndex: Math.max(0, sections.findIndex(s => s.id === Config.sidebarSection))
    readonly property string current: sections[currentIndex].id

    function close(): void {
        Panels.close();
    }

    function setSection(index: int): void {
        const n = sections.length;
        Config.sidebarSection = sections[(index % n + n) % n].id;
    }

    function isShowing(id: string): bool {
        return open && current === id;
    }

    // Wi-Fi procura redes enquanto a seção está à mostra.
    Binding {
        target: Network
        property: "scanning"
        value: root.isShowing("wifi")
    }

    IpcHandler {
        target: "sidebar"

        // Abre numa seção: wifi, bluetooth, sound, notifications, battery, display.
        function open(section: string): void {
            Panels.openSidebar(section);
        }

        function toggle(section: string): void {
            Panels.toggleSidebar(section || Config.sidebarSection);
        }
    }
}
