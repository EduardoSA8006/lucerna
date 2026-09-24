pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core.config
import qs.core.theme

// Ponte entre features: diz qual painel está aberto. Só um fica aberto por vez;
// abrir outro fecha o anterior. Nomes em uso: launcher, dashboard, settings, sidebar, themes, power.
Singleton {
    id: root

    property string current: ""

    function open(name: string): void {
        current = name;
    }

    function close(): void {
        current = "";
    }

    function toggle(name: string): void {
        current = current === name ? "" : name;
    }

    // Distância do topo para os painéis que descem ou encostam no topo: colados
    // à borda com a barra escondida; abaixo dela quando ela está fixa.
    readonly property real topInset: {
        const gap = ThemeManager.spacing.small;
        if (Config.barAutoHide)
            return gap;
        return Config.barStyle === "strip" ? ThemeManager.barHeight + gap : ThemeManager.barHeight + gap * 2;
    }

    function isOpen(name: string): bool {
        return current === name;
    }

    // Central lateral numa seção (wifi, bluetooth, sound, notifications, battery, display).
    function openSidebar(section: string): void {
        Config.sidebarSection = section;
        open("sidebar");
    }

    // Fecha se já estiver aberta nessa seção; senão abre (ou troca) para ela.
    function toggleSidebar(section: string): void {
        if (current === "sidebar" && Config.sidebarSection === section)
            close();
        else
            openSidebar(section);
    }

    IpcHandler {
        target: "panels"

        function open(name: string): void {
            root.open(name);
        }

        function close(): void {
            root.close();
        }

        function toggle(name: string): void {
            root.toggle(name);
        }

        function get(): string {
            return root.current;
        }
    }
}
