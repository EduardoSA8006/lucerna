import QtQuick
import Quickshell
import qs.core.theme
import qs.core.widgets
import qs.features.bar.state

// Três ilhas: workspaces à esquerda, hora e data no meio, ações à direita.
// Descem em cascata quando a barra aparece.
Item {
    id: root

    required property real progress
    readonly property real gap: ThemeManager.spacing.small

    readonly property Region mask: Region {
        Region {
            item: left
        }

        Region {
            item: center
        }

        Region {
            item: right
        }
    }

    // Atraso por ilha: a da direita chega um pouco depois da da esquerda.
    function offset(item: Item, lag: real): real {
        const p = Math.max(0, Math.min(1.2, root.progress * (1 + lag) - lag));
        return root.gap - (1 - p) * (item.height + root.gap * 2);
    }

    Glass {
        id: left

        x: root.gap
        y: root.offset(left, 0)
        width: leftRow.implicitWidth + ThemeManager.spacing.normal * 2
        height: ThemeManager.barHeight
        radius: height / 2

        Workspaces {
            id: leftRow

            anchors.centerIn: parent
        }
    }

    Glass {
        id: center

        x: (root.width - width) / 2
        y: root.offset(center, 0.08)
        width: clock.width + ThemeManager.spacing.small * 2
        height: ThemeManager.barHeight
        radius: height / 2

        ClockButton {
            id: clock

            anchors.centerIn: parent
            stacked: true
        }
    }

    Glass {
        id: right

        x: root.width - width - root.gap
        y: root.offset(right, 0.16)
        width: actions.implicitWidth + ThemeManager.spacing.small * 2
        height: ThemeManager.barHeight
        radius: height / 2

        Actions {
            id: actions

            anchors.centerIn: parent
        }
    }
}
