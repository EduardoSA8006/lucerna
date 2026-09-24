import QtQuick
import Quickshell
import qs.core.theme
import qs.core.widgets
import qs.features.bar.state

// Pílula: uma só, flutuante e centralizada, com tudo à mostra.
Item {
    id: root

    required property real progress
    readonly property real gap: ThemeManager.spacing.small

    readonly property Region mask: Region {
        item: pill
    }

    Glass {
        id: pill

        anchors.horizontalCenter: parent.horizontalCenter
        y: root.gap - (1 - root.progress) * (height + root.gap * 2)
        width: row.implicitWidth + ThemeManager.spacing.normal * 2
        height: ThemeManager.barHeight
        radius: height / 2

        Behavior on width { Anim { type: Anim.FastSpatial } }

        Row {
            id: row

            anchors.centerIn: parent
            spacing: ThemeManager.spacing.small

            Workspaces {
                anchors.verticalCenter: parent.verticalCenter
            }

            Divider {}

            ClockButton {
                anchors.verticalCenter: parent.verticalCenter
            }

            Divider {}

            Actions {}
        }
    }
}
