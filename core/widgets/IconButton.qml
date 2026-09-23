import QtQuick
import qs.core.theme

// Botão quadrado com um ícone e, opcionalmente, um rótulo ao lado.
Clickable {
    id: root

    property alias icon: glyph.icon
    property alias iconSize: glyph.size
    property alias label: caption.text
    property color foreground: active ? ThemeManager.colors.accentText : ThemeManager.colors.text

    implicitHeight: Math.max(glyph.implicitHeight, caption.implicitHeight) + ThemeManager.spacing.small
    implicitWidth: caption.text ? row.implicitWidth + ThemeManager.spacing.normal : implicitHeight

    Row {
        id: row

        anchors.centerIn: parent
        spacing: ThemeManager.spacing.tiny + 2

        Icon {
            id: glyph

            anchors.verticalCenter: parent.verticalCenter
            color: root.foreground
        }

        Txt {
            id: caption

            anchors.verticalCenter: parent.verticalCenter
            visible: text !== ""
            color: root.foreground
            mono: true
            font.pixelSize: ThemeManager.font.small
        }
    }
}
