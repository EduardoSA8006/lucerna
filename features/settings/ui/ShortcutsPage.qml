import QtQuick
import qs.core.input
import qs.core.theme
import qs.core.widgets
import qs.features.settings.state

// Atalhos: as teclas do próprio shell, editáveis. Clicar numa tecla troca por
// outra; "+" acrescenta mais uma. Os atalhos do Hyprland (janelas, workspaces)
// continuam no hyprland.lua.
Column {
    spacing: ThemeManager.spacing.large

    Component.onDestruction: {
        if (ShortcutsState.capturing)
            ShortcutsState.cancel();
    }

    Txt {
        width: parent.width
        wrapMode: Text.Wrap
        muted: true
        text: "Clique numa tecla para trocar, ou em + para acrescentar outra. Uma tecla que o hyprland.lua também usa passa a ser do Lucerna. As janelas e os workspaces continuam no hyprland.lua; teclas e botões extras, nas abas Teclado e Mouse."
    }

    Txt {
        width: parent.width
        visible: ShortcutsState.notice !== ""
        wrapMode: Text.Wrap
        text: ShortcutsState.notice
        color: ThemeManager.colors.accent
        font.pixelSize: ThemeManager.font.small + 1
    }

    Repeater {
        model: ShortcutsState.groups

        delegate: SettingSection {
            id: group

            required property var modelData

            title: modelData.title

            Repeater {
                model: group.modelData.ids

                delegate: Column {
                    id: entry

                    required property string modelData
                    readonly property var shortcut: ShortcutsState.shortcut(modelData)
                    readonly property bool capturingHere: ShortcutsState.capturing?.id === modelData

                    width: parent.width

                    SettingRow {
                        icon: ShortcutsState.icon(entry.modelData)
                        title: ShortcutsState.label(entry.modelData)
                        description: entry.shortcut.keys.length ? "" : "Sem atalho"

                        Row {
                            spacing: ThemeManager.spacing.small

                            Repeater {
                                model: entry.shortcut.keys

                                delegate: Clickable {
                                    required property var modelData
                                    required property int index
                                    readonly property bool current: entry.capturingHere && ShortcutsState.capturing.index === index

                                    anchors.verticalCenter: parent.verticalCenter
                                    width: keyText.implicitWidth + 20
                                    height: 30
                                    radius: 8
                                    color: current ? ThemeManager.alpha(ThemeManager.colors.accent, 0.2) : ThemeManager.glass(ThemeManager.colors.raised, 1)
                                    border.width: current ? 1 : ThemeManager.outlines ? 1 : 0
                                    border.color: current ? ThemeManager.colors.accent : ThemeManager.colors.border
                                    onClicked: ShortcutsState.start(entry.modelData, index)

                                    Txt {
                                        id: keyText

                                        anchors.centerIn: parent
                                        text: ShortcutsState.pretty(parent.modelData)
                                        mono: true
                                        font.pixelSize: ThemeManager.font.small + 1
                                    }
                                }
                            }

                            IconButton {
                                anchors.verticalCenter: parent.verticalCenter
                                icon: Icons.add
                                iconSize: 18
                                onClicked: ShortcutsState.start(entry.modelData, -1)
                            }

                            IconButton {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: entry.shortcut.custom
                                icon: "restart_alt"
                                iconSize: 18
                                onClicked: ShortcutsState.reset(entry.modelData)
                            }
                        }
                    }

                    Loader {
                        x: ThemeManager.spacing.large
                        width: parent.width - x * 2
                        active: entry.capturingHere
                        visible: active
                        height: active ? item.implicitHeight + ThemeManager.spacing.large : 0

                        sourceComponent: Column {
                            spacing: ThemeManager.spacing.small

                            CaptureBox {
                                width: parent.width
                                mode: "key"
                                hint: "Com Super, Ctrl, Alt ou Shift, ou uma tecla de mídia ou extra"
                                onKey: (k, c, m) => {
                                    if (!ShortcutsState.captured(k, c, m) && !InputActions.modifierKeys.includes(k))
                                        hint = "Essa tecla não tem nome no layout atual";
                                }
                            }

                            Row {
                                anchors.right: parent.right
                                spacing: ThemeManager.spacing.small

                                TonalButton {
                                    visible: ShortcutsState.capturing?.index >= 0
                                    icon: Icons.trash
                                    text: "Tirar esta tecla"
                                    onClicked: ShortcutsState.removeKey(entry.modelData, ShortcutsState.capturing.index)
                                }

                                TonalButton {
                                    icon: Icons.close
                                    text: "Cancelar"
                                    onClicked: ShortcutsState.cancel()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    TonalButton {
        anchors.right: parent.right
        enabled: ShortcutsState.anyCustom
        icon: "restart_alt"
        text: "Voltar aos padrões"
        onClicked: ShortcutsState.resetAll()
    }
}
