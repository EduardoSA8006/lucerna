import QtQuick
import Quickshell
import qs.core.theme
import qs.core.widgets
import qs.features.themeSwitcher.state

// Painel de troca rápida de tema. Clicar aplica na hora e mantém o painel
// aberto para comparar; Enter aplica o selecionado e fecha.
OverlayPanel {
    id: panel

    name: "themes"
    open: ThemeSwitcherState.open
    screen: ThemeSwitcherState.screen
    onDismissed: ThemeSwitcherState.close()

    property int selected: 0

    onOpenChanged: {
        if (open) {
            selected = Math.max(0, ThemeSwitcherState.currentIndex);
            grid.forceActiveFocus();
        }
    }

    Surface {
        level: 0
        anchors.centerIn: parent
        anchors.verticalCenterOffset: (1 - panel.progress) * 24
        width: content.implicitWidth + ThemeManager.spacing.large * 2
        height: content.implicitHeight + ThemeManager.spacing.large * 2

        Column {
            id: content

            anchors.centerIn: parent
            spacing: ThemeManager.spacing.normal

            Item {
                width: grid.width
                height: 32

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: ThemeManager.spacing.small

                    Icon {
                        icon: Icons.palette
                        filled: true
                        color: ThemeManager.colors.accent
                    }

                    Txt {
                        text: "Temas"
                        font.pixelSize: ThemeManager.font.large
                        font.weight: Font.DemiBold
                    }
                }

                IconButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    icon: Icons.tune
                    label: "Mais ajustes"
                    onClicked: ThemeSwitcherState.openSettings()
                }
            }

            Item {
                width: grid.width
                height: grid.height

                // Anel de seleção que desliza até o cartão escolhido.
                Rectangle {
                    readonly property Item target: cards.count > 0 ? cards.itemAt(panel.selected) : null

                    x: (target?.x ?? 0) - 4
                    y: (target?.y ?? 0) - 4
                    width: (target?.width ?? 0) + 8
                    height: (target?.height ?? 0) + 8
                    scale: target?.scale ?? 1
                    radius: ThemeManager.radius.normal + 4
                    color: "transparent"
                    border.width: 2
                    border.color: ThemeManager.colors.accent

                    Behavior on x { Anim { type: Anim.FastSpatial } }
                    Behavior on y { Anim { type: Anim.FastSpatial } }
                }

                Grid {
                    id: grid

                    columns: Math.min(4, Math.max(1, ThemeSwitcherState.themes.length))
                    spacing: ThemeManager.spacing.normal
                    focus: true

                    Keys.onPressed: event => {
                        const count = ThemeSwitcherState.themes.length;
                        if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab)
                            panel.selected = (panel.selected + 1) % count;
                        else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab)
                            panel.selected = (panel.selected - 1 + count) % count;
                        else if (event.key === Qt.Key_Down)
                            panel.selected = Math.min(count - 1, panel.selected + columns);
                        else if (event.key === Qt.Key_Up)
                            panel.selected = Math.max(0, panel.selected - columns);
                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            ThemeSwitcherState.apply(ThemeSwitcherState.themes[panel.selected].id);
                            ThemeSwitcherState.close();
                        } else
                            return;
                        event.accepted = true;
                    }

                    Repeater {
                        id: cards

                        model: ThemeSwitcherState.themes

                        delegate: ThemeCard {
                            required property var modelData
                            required property int index

                            theme: modelData
                            current: modelData.id === ThemeSwitcherState.current
                            selected: index === panel.selected
                            onClicked: {
                                panel.selected = index;
                                ThemeSwitcherState.apply(modelData.id);
                            }
                        }
                    }
                }

            }

            Txt {
                width: grid.width
                text: ThemeSwitcherState.themes[panel.selected]?.description ?? ""
                muted: true
                wrapMode: Text.WordWrap
                font.pixelSize: ThemeManager.font.small
            }
        }
    }
}
