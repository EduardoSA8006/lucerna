import QtQuick
import Quickshell
import qs.core.theme
import qs.core.widgets
import qs.features.bar.state

// Faixa: a barra clássica, de ponta a ponta, colada ao topo. Workspaces à
// esquerda, hora e data no centro, ações à direita.
Item {
    id: root

    required property real progress

    readonly property Region mask: Region {
        item: strip
    }

    Glass {
        id: strip

        y: -(1 - root.progress) * height
        width: parent.width
        height: ThemeManager.barHeight
        border.width: 0

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: ThemeManager.colors.border
            opacity: ThemeManager.outlines ? 1 : 0.5
        }

        Workspaces {
            anchors.left: parent.left
            anchors.leftMargin: ThemeManager.spacing.large
            anchors.verticalCenter: parent.verticalCenter
        }

        ClockButton {
            anchors.centerIn: parent
        }

        Actions {
            anchors.right: parent.right
            anchors.rightMargin: ThemeManager.spacing.normal
        }
    }
}
