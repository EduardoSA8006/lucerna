import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core.theme
import qs.core.widgets
import qs.features.bar.state

// Barra flutuante: uma pílula centralizada no topo. Com auto-ocultar, desce com
// mola quando o mouse encosta no topo e sobe quando ele sai; sem auto-ocultar,
// fica fixa e reserva o espaço dela.
PanelWindow {
    id: root

    readonly property bool shown: BarState.shownOn(screen)
    readonly property real gap: ThemeManager.spacing.small
    property real progress: shown ? 1 : 0

    Behavior on progress {
        Anim {
            type: root.shown ? Anim.Spatial : Anim.EmphasizedAccel
        }
    }

    visible: progress > 0
    anchors.top: true
    implicitWidth: pill.width + 32
    implicitHeight: pill.height + gap * 2
    color: "transparent"
    exclusionMode: BarState.autoHide ? ExclusionMode.Ignore : ExclusionMode.Auto
    // Só a pílula recebe o mouse; as sobras transparentes deixam passar.
    mask: Region {
        item: pill
    }
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "lucerna-panel-bar"

    Rectangle {
        id: pill

        anchors.horizontalCenter: parent.horizontalCenter
        y: root.gap - (1 - root.progress) * (height + root.gap * 2)
        width: content.implicitWidth + ThemeManager.spacing.normal * 2
        height: ThemeManager.barHeight
        radius: height / 2
        color: ThemeManager.glass(ThemeManager.colors.base, 0)
        border.width: ThemeManager.outlines ? 1 : 0
        border.color: ThemeManager.colors.border

        Behavior on width { Anim { type: Anim.FastSpatial } }

        HoverHandler {
            onHoveredChanged: BarState.setHovering(hovered)
        }

        Row {
            id: content

            anchors.centerIn: parent
            spacing: ThemeManager.spacing.small

            Workspaces {
                anchors.verticalCenter: parent.verticalCenter
            }

            Divider {}

            // Relógio: abre o painel superior.
            Clickable {
                anchors.verticalCenter: parent.verticalCenter
                width: clock.implicitWidth + ThemeManager.spacing.normal * 2
                height: pill.height - 8
                radius: height / 2
                active: BarState.openPanel === "dashboard"
                activeColor: ThemeManager.alpha(ThemeManager.colors.accent, 0.16)
                onClicked: BarState.togglePanel("dashboard")

                Row {
                    id: clock

                    anchors.centerIn: parent
                    spacing: ThemeManager.spacing.small

                    Txt {
                        anchors.verticalCenter: parent.verticalCenter
                        text: BarState.time
                        mono: true
                        font.weight: Font.DemiBold
                    }

                    Txt {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: BarState.showDate
                        text: BarState.date
                        muted: true
                    }
                }
            }

            Divider {}

            // Estado do sistema: compacto, sem rótulos (o OSD mostra o volume ao mudar).
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                IconButton {
                    icon: BarState.networkIcon
                    visible: BarState.networkAvailable
                    iconSize: 18
                    foreground: BarState.online ? ThemeManager.colors.textMuted : ThemeManager.colors.textFaint
                    onClicked: BarState.toggleSection("wifi")
                }

                IconButton {
                    icon: BarState.volumeIcon
                    visible: BarState.audioAvailable
                    iconSize: 18
                    foreground: BarState.muted ? ThemeManager.colors.textFaint : ThemeManager.colors.textMuted
                    // Clique abre o Som; botão do meio silencia; a roda ajusta o volume.
                    onClicked: event => {
                        if (event.button === Qt.MiddleButton)
                            BarState.toggleMute();
                        else
                            BarState.toggleSection("sound");
                    }
                    onWheel: event => BarState.scrollVolume(event.angleDelta.y / 120)
                }

                IconButton {
                    icon: BarState.batteryIcon
                    label: `${BarState.batteryPercent}%`
                    visible: BarState.batteryAvailable
                    iconSize: 18
                    foreground: BarState.batteryLow ? ThemeManager.colors.danger : ThemeManager.colors.textMuted
                    onClicked: BarState.toggleSection("battery")
                }
            }

            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                icon: BarState.bellIcon
                iconSize: 18
                label: BarState.notificationCount > 0 ? `${BarState.notificationCount}` : ""
                active: BarState.sectionOpen("notifications")
                onClicked: BarState.toggleSection("notifications")
            }
        }
    }
}
