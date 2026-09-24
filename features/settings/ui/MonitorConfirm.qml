import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core.theme
import qs.core.widgets
import qs.features.settings.state

// Depois de aplicar um arranjo: "manter?" em cada tela, com a contagem. Fica
// fora das configurações de propósito: se uma tela apagar ou a janela das
// configurações fechar, dá para confirmar ou reverter por qualquer outra.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: window

        required property var modelData
        property real shown: MonitorsState.pending ? 1 : 0

        Behavior on shown { Anim { type: MonitorsState.pending ? Anim.Spatial : Anim.EmphasizedAccel } }

        screen: modelData
        visible: shown > 0
        anchors.top: true
        margins.top: 90
        implicitWidth: 460
        implicitHeight: card.height + 20
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "lucerna-panel-monitor-confirm"

        Component.onCompleted: MonitorsState.registerSurface(window)
        Component.onDestruction: MonitorsState.unregisterSurface(window)

        Surface {
            id: card

            x: 10
            width: parent.width - 20
            height: content.height + ThemeManager.spacing.large * 2
            level: 0
            radius: ThemeManager.radius.large
            opacity: window.shown
            y: -(1 - window.shown) * 30

            Column {
                id: content

                x: ThemeManager.spacing.large
                y: ThemeManager.spacing.large
                width: parent.width - x * 2
                spacing: ThemeManager.spacing.normal

                Row {
                    width: parent.width
                    spacing: ThemeManager.spacing.normal

                    CircularGauge {
                        width: 44
                        height: 44
                        thickness: 4
                        value: MonitorsState.countdown / MonitorsState.confirmSeconds

                        Txt {
                            anchors.centerIn: parent
                            text: MonitorsState.countdown
                            mono: true
                            font.weight: Font.DemiBold
                        }
                    }

                    Column {
                        width: parent.width - 44 - parent.spacing
                        anchors.verticalCenter: parent.verticalCenter

                        Txt {
                            text: "Manter esta configuração dos monitores?"
                            font.weight: Font.DemiBold
                        }

                        Txt {
                            width: parent.width
                            wrapMode: Text.Wrap
                            text: `Sem resposta, volta à anterior em ${MonitorsState.countdown} s`
                            muted: true
                            font.pixelSize: ThemeManager.font.small + 1
                        }
                    }
                }

                Row {
                    anchors.right: parent.right
                    spacing: ThemeManager.spacing.small

                    TonalButton {
                        text: "Reverter"
                        onClicked: MonitorsState.revert()
                    }

                    TonalButton {
                        icon: Icons.check
                        text: "Manter"
                        onClicked: MonitorsState.keep()
                    }
                }
            }
        }
    }
}
