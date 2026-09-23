import QtQuick
import qs.core.theme

// Abas com ícone e rótulo. O indicador desliza e estica até a aba atual, e o
// ícone da aba atual fica preenchido.
Item {
    id: root

    // [{ icon, label }]
    required property var tabs
    property int currentIndex: 0

    signal activated(int index)

    implicitHeight: 52

    Row {
        id: row

        anchors.fill: parent

        Repeater {
            id: repeater

            model: root.tabs

            delegate: Clickable {
                id: tab

                required property var modelData
                required property int index
                readonly property bool current: index === root.currentIndex
                readonly property real labelWidth: label.width

                width: row.width / root.tabs.length
                height: row.height
                radius: ThemeManager.radius.normal
                onClicked: root.activated(index)

                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        icon: tab.modelData.icon
                        filled: tab.current
                        color: tab.current ? ThemeManager.colors.accent : ThemeManager.colors.textMuted

                        Behavior on color { ColorAnim {} }
                    }

                    Txt {
                        id: label

                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tab.modelData.label
                        color: tab.current ? ThemeManager.colors.accent : ThemeManager.colors.textMuted
                        font.pixelSize: ThemeManager.font.small + 1

                        Behavior on color { ColorAnim {} }
                    }
                }
            }
        }
    }

    // Indicador: a largura do rótulo da aba atual, colado embaixo.
    Rectangle {
        readonly property Item target: repeater.itemAt(root.currentIndex)
        readonly property real targetWidth: Math.max(28, (target?.labelWidth ?? 40) + 12)

        anchors.bottom: parent.bottom
        x: target ? target.x + (target.width - width) / 2 : 0
        width: targetWidth
        height: 3
        radius: 1.5
        color: ThemeManager.colors.accent

        Behavior on x { Anim { type: Anim.Spatial } }
        Behavior on width { Anim { type: Anim.FastSpatial } }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: ThemeManager.colors.border
        z: -1
    }
}
