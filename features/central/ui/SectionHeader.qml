import QtQuick
import qs.core.theme
import qs.core.widgets

// Cabeçalho de seção: título grande, estado embaixo e controles à direita.
Item {
    id: root

    property string title
    property string subtitle
    default property alias controls: slot.data

    width: parent?.width ?? 0
    implicitHeight: Math.max(labels.height, slot.childrenRect.height) + ThemeManager.spacing.normal

    Column {
        id: labels

        anchors.left: parent.left
        anchors.right: slot.left
        anchors.rightMargin: ThemeManager.spacing.small
        spacing: 2

        Txt {
            width: parent.width
            text: root.title
            font.pixelSize: ThemeManager.font.huge - 20
            font.weight: Font.DemiBold
        }

        Txt {
            width: parent.width
            visible: root.subtitle !== ""
            text: root.subtitle
            muted: true
            font.pixelSize: ThemeManager.font.small + 1
        }
    }

    Row {
        id: slot

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 4
        spacing: ThemeManager.spacing.small
    }
}
