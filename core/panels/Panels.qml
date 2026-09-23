pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Ponte entre features: diz qual painel está aberto. Só um fica aberto por vez;
// abrir outro fecha o anterior. Nomes em uso: launcher, dashboard, notifications, themes, power.
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

    function isOpen(name: string): bool {
        return current === name;
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
