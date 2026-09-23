import QtQuick
import qs.core.theme
import qs.core.widgets
import qs.features.sidebar.state

// Trilho de seções, no estilo do "navigation rail" do Material 3: ícone num
// indicador em pílula e rótulo embaixo. Rola se não couber.
FocusScope {
    id: root

    property bool onLeft: false
    property real radius: 0

    Keys.onUpPressed: SidebarState.setSection(SidebarState.currentIndex - 1)
    Keys.onDownPressed: SidebarState.setSection(SidebarState.currentIndex + 1)
    Keys.onTabPressed: SidebarState.setSection(SidebarState.currentIndex + 1)
    Keys.onBacktabPressed: SidebarState.setSection(SidebarState.currentIndex - 1)

    // Fundo levemente mais escuro, arredondado só do lado da borda da tela.
    Rectangle {
        anchors.fill: parent
        topLeftRadius: root.onLeft ? root.radius : 0
        bottomLeftRadius: root.onLeft ? root.radius : 0
        topRightRadius: root.onLeft ? 0 : root.radius
        bottomRightRadius: root.onLeft ? 0 : root.radius
        color: ThemeManager.alpha(ThemeManager.colors.base, 0.35)
    }

    Flickable {
        anchors.fill: parent
        anchors.topMargin: ThemeManager.spacing.large
        anchors.bottomMargin: ThemeManager.spacing.large
        contentHeight: items.height
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Item {
            id: items

            width: parent.width
            height: column.height

            // Indicador da seção atual: pílula atrás do ícone, desliza com mola.
            Rectangle {
                readonly property Item target: rows.count > 0 ? rows.itemAt(SidebarState.currentIndex) : null

                anchors.horizontalCenter: parent.horizontalCenter
                y: (target?.y ?? 0) + 6
                width: 56
                height: 32
                radius: 16
                color: ThemeManager.colors.accent

                Behavior on y { Anim { type: Anim.FastSpatial } }
            }

            Column {
                id: column

                width: parent.width
                spacing: ThemeManager.spacing.small

                Repeater {
                    id: rows

                    model: SidebarState.sections

                    delegate: Item {
                        id: item

                        required property var modelData
                        required property int index
                        readonly property bool current: index === SidebarState.currentIndex

                        width: column.width
                        height: 66

                        // Véu de hover do tamanho do indicador.
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 6
                            width: 56
                            height: 32
                            radius: 16
                            color: ThemeManager.colors.text
                            opacity: mouse.containsMouse && !item.current ? 0.08 : 0

                            Behavior on opacity { Anim { type: Anim.FastEffects } }
                        }

                        Icon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 6 + (32 - height) / 2
                            icon: item.modelData.icon
                            size: 22
                            filled: item.current || mouse.containsMouse
                            color: item.current ? ThemeManager.colors.accentText : ThemeManager.colors.textMuted

                            Behavior on color { ColorAnim {} }
                        }

                        Txt {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 42
                            text: item.modelData.label
                            color: item.current ? ThemeManager.colors.text : ThemeManager.colors.textMuted
                            font.pixelSize: ThemeManager.font.small
                            font.weight: item.current ? Font.DemiBold : Font.Normal

                            Behavior on color { ColorAnim {} }
                        }

                        MouseArea {
                            id: mouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: SidebarState.setSection(item.index)
                        }
                    }
                }
            }
        }
    }
}
