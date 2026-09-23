import QtQuick
import qs.core.theme
import qs.core.widgets
import qs.features.settings.state

// Aparência: tema e velocidade das animações.
Column {
    spacing: ThemeManager.spacing.large

    SettingSection {
        title: "Tema"

        Item {
            width: parent.width
            height: themeFlow.implicitHeight + ThemeManager.spacing.large * 2

            Flow {
                id: themeFlow

                anchors.fill: parent
                anchors.margins: ThemeManager.spacing.large
                spacing: ThemeManager.spacing.normal

                Repeater {
                    model: SettingsState.themes

                    delegate: Clickable {
                        id: chip

                        required property var modelData
                        readonly property bool current: modelData.id === SettingsState.theme

                        width: 150
                        height: 64
                        radius: ThemeManager.radius.normal
                        pressScale: 0.95
                        color: modelData.colors.base ?? "black"
                        border.width: current ? 2 : ThemeManager.outlines ? 1 : 0
                        border.color: current ? ThemeManager.colors.accent : (modelData.colors.border ?? "gray")
                        onClicked: SettingsState.applyTheme(modelData.id)

                        Row {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.margins: 10
                            spacing: 4

                            Repeater {
                                model: ["accent", "text", "textMuted", "surface"]

                                delegate: Rectangle {
                                    required property string modelData

                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: chip.modelData.colors[modelData] ?? "gray"
                                    border.width: 1
                                    border.color: chip.modelData.colors.border ?? "gray"
                                }
                            }
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            anchors.margins: 10
                            text: chip.modelData.name
                            color: chip.modelData.colors.text ?? "white"
                            font.family: ThemeManager.font.sans
                            font.pixelSize: ThemeManager.font.normal
                            font.weight: Font.DemiBold
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 8
                            width: 20
                            height: 20
                            radius: 10
                            color: chip.modelData.colors.accent ?? "white"
                            scale: chip.current ? 1 : 0
                            opacity: chip.current ? 1 : 0

                            Behavior on scale { Anim { type: Anim.FastSpatial } }
                            Behavior on opacity { Anim { type: Anim.FastEffects } }

                            Icon {
                                anchors.centerIn: parent
                                icon: Icons.check
                                size: 14
                                weight: 600
                                color: chip.modelData.colors.accentText ?? "black"
                            }
                        }
                    }
                }
            }
        }
    }

    SettingSection {
        title: "Cartões"

        SettingRow {
            icon: Icons.toolbar
            title: "Contorno nos cartões"
            description: "Uma linha fina em volta de cartões e painéis. Sem ela, eles se destacam só pelo tom"

            Switch {
                checked: SettingsState.outlines
                onToggled: on => SettingsState.setOutlines(on)
            }
        }
    }

    SettingSection {
        title: "Movimento"

        SettingRow {
            icon: Icons.animation
            title: "Animações"
            description: "Velocidade das transições do shell. \"Desligadas\" troca tudo na hora"
            wide: true

            SegmentedControl {
                width: parent.width
                options: SettingsState.animationOptions
                value: SettingsState.animationScale
                onSelected: v => SettingsState.setAnimationScale(v)
            }
        }
    }
}
