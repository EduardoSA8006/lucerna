import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core.theme
import qs.core.widgets
import qs.features.osd.state

// Indicador de volume/brilho na parte de baixo da tela. Não recebe cliques.
PanelWindow {
    id: window

    screen: OsdState.screen
    visible: pill.opacity > 0
    anchors.bottom: true
    margins.bottom: 72
    implicitWidth: pill.width
    implicitHeight: pill.height + 32
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lucerna-panel-osd"

    Surface {
        id: pill

        width: 280
        height: 52
        level: 0
        radius: height / 2
        // Sobe de baixo com mola ao aparecer e desce ao sumir.
        opacity: OsdState.shown ? 1 : 0
        scale: OsdState.shown ? 1 : 0.94
        transform: Translate {
            y: OsdState.shown ? 0 : 28

            Behavior on y { Anim { type: OsdState.shown ? Anim.Spatial : Anim.EmphasizedAccel } }
        }

        Behavior on opacity { Anim { type: Anim.Effects } }
        Behavior on scale { Anim { type: Anim.Spatial } }

        Icon {
            id: glyph

            anchors.left: parent.left
            anchors.leftMargin: ThemeManager.spacing.large
            anchors.verticalCenter: parent.verticalCenter
            icon: OsdState.icon
            size: 20
            color: OsdState.muted ? ThemeManager.colors.textFaint : ThemeManager.colors.accent
        }

        Rectangle {
            id: track

            anchors {
                left: glyph.right
                right: label.left
                leftMargin: ThemeManager.spacing.normal
                rightMargin: ThemeManager.spacing.normal
                verticalCenter: parent.verticalCenter
            }
            height: 6
            radius: 3
            color: ThemeManager.colors.track

            Rectangle {
                width: parent.width * Math.min(1, OsdState.value)
                height: parent.height
                radius: parent.radius
                color: OsdState.muted ? ThemeManager.colors.textFaint : ThemeManager.colors.accent

                Behavior on width { Anim { type: Anim.Standard } }
            }
        }

        Txt {
            id: label

            anchors.right: parent.right
            anchors.rightMargin: ThemeManager.spacing.large
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            horizontalAlignment: Text.AlignRight
            text: OsdState.muted ? "mudo" : OsdState.percent
            mono: true
            muted: OsdState.muted
            font.pixelSize: ThemeManager.font.small
        }
    }
}
