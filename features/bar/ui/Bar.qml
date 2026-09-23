import QtQuick
import Quickshell

// Em cada monitor: a faixa invisível que detecta o mouse no topo e a barra.
Variants {
    model: Quickshell.screens

    delegate: Scope {
        id: scope

        required property var modelData

        BarTrigger {
            screen: scope.modelData
        }

        BarWindow {
            screen: scope.modelData
        }
    }
}
