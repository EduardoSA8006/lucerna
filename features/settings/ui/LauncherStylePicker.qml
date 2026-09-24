import QtQuick
import qs.core.theme
import qs.core.widgets
import qs.features.settings.state

// Escolha do estilo do launcher: cartões com uma miniatura de cada um.
Flow {
    id: root

    spacing: ThemeManager.spacing.normal

    readonly property int columns: Math.min(LauncherSettings.styles.length, Math.max(1, Math.floor((width + spacing) / (150 + spacing))))
    readonly property real cardWidth: (width - (columns - 1) * spacing) / columns

    Repeater {
        model: LauncherSettings.styles

        delegate: Clickable {
            id: card

            required property var modelData
            readonly property bool current: modelData.id === LauncherSettings.style
            readonly property color ink: current ? ThemeManager.colors.accent : ThemeManager.colors.textMuted

            width: root.cardWidth
            height: 132
            radius: ThemeManager.radius.normal + 2
            pressScale: 0.95
            color: current ? ThemeManager.alpha(ThemeManager.colors.accent, 0.12) : ThemeManager.alpha(ThemeManager.colors.text, 0.04)
            border.width: current ? 2 : 0
            border.color: ThemeManager.colors.accent
            onClicked: LauncherSettings.setStyle(modelData.id)

            // Miniatura: uma "tela" com o launcher desenhado.
            Rectangle {
                id: screen

                x: 10
                y: 10
                width: parent.width - 20
                height: 76
                radius: ThemeManager.radius.small
                color: ThemeManager.colors.base
                clip: true

                // Compacto: campo e uma lista curta, no alto.
                Item {
                    visible: card.modelData.id === "compact"
                    anchors.fill: parent

                    Rectangle {
                        x: parent.width * 0.25
                        y: 12
                        width: parent.width * 0.5
                        height: 40
                        radius: 4
                        color: ThemeManager.colors.surface

                        Rectangle { x: 4; y: 4; width: parent.width - 8; height: 7; radius: 3; color: card.ink; opacity: 0.8 }

                        Repeater {
                            model: 3

                            delegate: Rectangle {
                                required property int index

                                x: 6
                                y: 16 + index * 8
                                width: parent.width * (0.7 - index * 0.12)
                                height: 4
                                radius: 2
                                color: ThemeManager.colors.textFaint
                            }
                        }
                    }
                }

                // Completo: coluna de categorias, grade e detalhes.
                Item {
                    visible: card.modelData.id === "full"
                    anchors.fill: parent

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 8
                        radius: 4
                        color: ThemeManager.colors.surface

                        Rectangle { x: 4; y: 4; width: parent.width * 0.66; height: 6; radius: 3; color: card.ink; opacity: 0.8 }

                        Repeater {
                            model: 4

                            delegate: Rectangle {
                                required property int index

                                x: 4
                                y: 15 + index * 9
                                width: parent.width * 0.16
                                height: 4
                                radius: 2
                                color: index === 0 ? card.ink : ThemeManager.colors.textFaint
                            }
                        }

                        Grid {
                            x: parent.width * 0.23
                            y: 15
                            columns: 4
                            spacing: 3

                            Repeater {
                                model: 8

                                delegate: Rectangle {
                                    width: 9
                                    height: 9
                                    radius: 2
                                    color: ThemeManager.colors.textFaint
                                    opacity: 0.7
                                }
                            }
                        }

                        Rectangle {
                            x: parent.width * 0.72
                            y: 4
                            width: parent.width * 0.26
                            height: parent.height - 8
                            radius: 3
                            color: ThemeManager.colors.raised

                            Rectangle { x: 4; y: 6; width: 10; height: 10; radius: 3; color: card.ink }
                            Rectangle { x: 4; y: 22; width: parent.width - 8; height: 5; radius: 2; color: card.ink; opacity: 0.8 }
                        }
                    }
                }

                // Tela cheia: grade grande sobre a tela toda.
                Item {
                    visible: card.modelData.id === "grid"
                    anchors.fill: parent

                    Rectangle {
                        anchors.fill: parent
                        color: ThemeManager.alpha(ThemeManager.colors.surface, 0.8)
                    }

                    Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 7; width: parent.width * 0.4; height: 6; radius: 3; color: card.ink; opacity: 0.8 }

                    Grid {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 22
                        columns: 6
                        spacing: 6

                        Repeater {
                            model: 12

                            delegate: Rectangle {
                                width: 12
                                height: 12
                                radius: 3
                                color: ThemeManager.colors.textFaint
                                opacity: 0.7
                            }
                        }
                    }
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
