import QtQuick
import Quickshell
import qs.core.theme
import qs.core.widgets
import qs.features.launcher.state

// Launcher: campo de busca e lista de resultados. Setas navegam, Enter abre.
OverlayPanel {
    id: panel

    name: "launcher"
    open: LauncherState.open
    screen: LauncherState.screen
    onDismissed: LauncherState.close()

    property int selected: 0

    onOpenChanged: {
        if (open) {
            input.text = "";
            selected = 0;
            input.forceActiveFocus();
        }
    }

    Surface {
        id: box

        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.22 + (1 - panel.progress) * 16
        width: 560
        height: column.implicitHeight + ThemeManager.spacing.normal * 2

        Column {
            id: column

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: ThemeManager.spacing.normal
            }
            spacing: ThemeManager.spacing.small

            // Campo de busca
            Rectangle {
                width: parent.width
                height: 44
                radius: ThemeManager.radius.normal
                color: ThemeManager.colors.raised

                Icon {
                    id: searchIcon

                    anchors.left: parent.left
                    anchors.leftMargin: ThemeManager.spacing.normal
                    anchors.verticalCenter: parent.verticalCenter
                    icon: Icons.magnify
                    color: ThemeManager.colors.accent
                }

                TextInput {
                    id: input

                    anchors {
                        left: searchIcon.right
                        right: parent.right
                        leftMargin: ThemeManager.spacing.small
                        rightMargin: ThemeManager.spacing.normal
                        verticalCenter: parent.verticalCenter
                    }
                    color: ThemeManager.colors.text
                    selectionColor: ThemeManager.alpha(ThemeManager.colors.accent, 0.35)
                    selectedTextColor: ThemeManager.colors.text
                    font.family: ThemeManager.font.sans
                    font.pixelSize: ThemeManager.font.large
                    clip: true
                    onTextChanged: {
                        LauncherState.query = text;
                        panel.selected = 0;
                    }

                    Keys.onPressed: event => {
                        const count = LauncherState.results.length;
                        if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && count)) {
                            panel.selected = (panel.selected + 1) % count;
                        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                            panel.selected = (panel.selected - 1 + count) % count;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            LauncherState.activate(LauncherState.results[panel.selected]);
                        } else {
                            return;
                        }
                        event.accepted = true;
                    }

                    Txt {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !input.text
                        text: "Buscar aplicativos e ações"
                        faint: true
                        font.pixelSize: ThemeManager.font.large
                    }
                }
            }

            Repeater {
                model: LauncherState.results

                delegate: ResultItem {
                    required property var modelData
                    required property int index

                    width: column.width
                    result: modelData
                    selected: index === panel.selected
                    onHoveredChanged: {
                        if (hovered)
                            panel.selected = index;
                    }
                    onClicked: LauncherState.activate(modelData)
                }
            }

            Txt {
                visible: LauncherState.results.length === 0
                width: parent.width
                height: 48
                horizontalAlignment: Text.AlignHCenter
                text: "Nada encontrado"
                faint: true
            }
        }
    }
}
