import QtQuick
import Quickshell
import qs.core.theme
import qs.core.widgets
import qs.features.bar.state

// Ilha: recolhida, só a hora (com sinais de atenção); com o mouse em cima,
// cresce para os dois lados com mola: workspaces, data e ações.
Item {
    id: root

    required property real progress
    readonly property bool expanded: BarState.expanded
    readonly property real gap: ThemeManager.spacing.small

    readonly property Region mask: Region {
        item: island
    }

    Glass {
        id: island

        anchors.horizontalCenter: parent.horizontalCenter
        y: root.gap - (1 - root.progress) * (height + root.gap * 2)
        width: content.width + ThemeManager.spacing.small * 2
        height: ThemeManager.barHeight
        radius: height / 2
        clip: true

        Row {
            id: content

            anchors.centerIn: parent
            height: parent.height

            Wing {
                open: root.expanded

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: ThemeManager.spacing.small
                    leftPadding: ThemeManager.spacing.small

                    Workspaces {
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Divider {}
                }
            }

            ClockButton {
                anchors.verticalCenter: parent.verticalCenter
                stacked: true
                showDate: root.expanded && BarState.showDate
                hints: !root.expanded
            }

            Wing {
                open: root.expanded

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: ThemeManager.spacing.tiny
                    rightPadding: ThemeManager.spacing.tiny

                    Divider {}

                    Actions {}
                }
            }
        }
    }
}
