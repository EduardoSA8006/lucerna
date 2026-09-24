import QtQuick
import qs.core.theme
import qs.core.widgets
import qs.features.settings.state

// Escolha do estilo da barra: cartões com uma miniatura de cada um.
Flow {
    id: root

    spacing: ThemeManager.spacing.normal

    Repeater {
        model: SettingsState.barStyles

        delegate: Clickable {
            id: card

            required property var modelData
            readonly property bool current: modelData.id === SettingsState.barStyle

            width: 150
            height: 118
            radius: ThemeManager.radius.normal + 2
            pressScale: 0.95
            color: current ? ThemeManager.alpha(ThemeManager.colors.accent, 0.12) : ThemeManager.alpha(ThemeManager.colors.text, 0.04)
            border.width: current ? 2 : 0
            border.color: ThemeManager.colors.accent
            onClicked: SettingsState.setBarStyle(modelData.id)

            // Miniatura: uma "tela" com a barra desenhada no topo.
            Rectangle {
                id: screen

                x: 10
                y: 10
                width: parent.width - 20
                height: 62
                radius: ThemeManager.radius.small
                color: ThemeManager.colors.base
                clip: true

                readonly property color bar: card.current ? ThemeManager.colors.accent : ThemeManager.colors.textMuted

                // Faixa
                Rectangle {
                    visible: card.modelData.id === "strip"
                    width: parent.width
                    height: 9
                    color: screen.bar
                    opacity: 0.85
                }

                // Pílula
                Rectangle {
                    visible: card.modelData.id === "pill"
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 5
                    width: parent.width * 0.62
                    height: 9
                    radius: 4.5
                    color: screen.bar
                    opacity: 0.85
                }

                // Ilha: pequena, com o contorno da versão expandida
                Rectangle {
                    visible: card.modelData.id === "island"
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 5
                    width: parent.width * 0.5
                    height: 9
                    radius: 4.5
                    color: "transparent"
                    border.width: 1
                    border.color: screen.bar
                    opacity: 0.45
                }

                Rectangle {
                    visible: card.modelData.id === "island"
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 5
                    width: 22
                    height: 9
                    radius: 4.5
                    color: screen.bar
                    opacity: 0.85
                }

                // Três ilhas
                Repeater {
                    model: card.modelData.id === "islands" ? [{ x: 5, w: 28 }, { x: (screen.width - 20) / 2, w: 20 }, { x: screen.width - 33, w: 28 }] : []

                    delegate: Rectangle {
                        required property var modelData

                        x: modelData.x
                        y: 5
                        width: modelData.w
                        height: 9
                        radius: 4.5
                        color: screen.bar
                        opacity: 0.85
                    }
                }

                // Uma janela, para dar escala.
                Rectangle {
                    x: 12
                    y: 22
                    width: parent.width - 24
                    height: 32
                    radius: 4
                    color: ThemeManager.colors.surface
                    opacity: 0.8
                }
            }

            Column {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: 10
                spacing: 0

                Txt {
                    text: card.modelData.label
                    font.weight: card.current ? Font.DemiBold : Font.Normal
                    color: card.current ? ThemeManager.colors.accent : ThemeManager.colors.text
                    font.pixelSize: ThemeManager.font.small + 1
                }

                Txt {
                    text: card.modelData.hint
                    faint: true
                    font.pixelSize: ThemeManager.font.small - 1
                }
            }
        }
    }
}
