import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.core.theme
import qs.core.widgets

// Uma linha de resultado: ícone do app (ou glifo da ação), nome e descrição.
Clickable {
    id: item

    required property var result
    property bool selected: false

    height: 48
    radius: ThemeManager.radius.normal
    color: selected ? ThemeManager.alpha(ThemeManager.colors.accent, 0.14) : "transparent"

    readonly property string iconPath: result.icon ? Quickshell.iconPath(result.icon, true) : ""

    Item {
        id: iconBox

        anchors.left: parent.left
        anchors.leftMargin: ThemeManager.spacing.small
        anchors.verticalCenter: parent.verticalCenter
        width: 32
        height: 32

        IconImage {
            anchors.fill: parent
            visible: item.iconPath !== ""
            implicitSize: 32
            source: item.iconPath
            asynchronous: true
        }

        Icon {
            anchors.centerIn: parent
            visible: item.iconPath === ""
            icon: item.result.glyph ?? Icons.application
            size: 22
            color: item.selected ? ThemeManager.colors.accent : ThemeManager.colors.textMuted
        }
    }

    Column {
        anchors {
            left: iconBox.right
            right: arrow.left
            leftMargin: ThemeManager.spacing.normal
            rightMargin: ThemeManager.spacing.small
            verticalCenter: parent.verticalCenter
        }

        Txt {
            width: parent.width
            text: item.result.name
            font.weight: item.selected ? Font.DemiBold : Font.Normal
        }

        Txt {
            width: parent.width
            visible: text !== ""
            text: item.result.description
            muted: true
            font.pixelSize: ThemeManager.font.small
        }
    }

    Icon {
        id: arrow

        anchors.right: parent.right
        anchors.rightMargin: ThemeManager.spacing.normal
        anchors.verticalCenter: parent.verticalCenter
        icon: Icons.arrowRight
        size: 14
        color: ThemeManager.colors.accent
        opacity: item.selected ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: ThemeManager.anim.fast } }
    }
}
