import QtQuick
import qs.core.theme
import qs.core.widgets

// Título de cartão: ícone de acento e texto.
Row {
    property alias icon: glyph.icon
    property alias text: label.text

    spacing: ThemeManager.spacing.small

    Icon {
        id: glyph

        anchors.verticalCenter: parent.verticalCenter
        filled: true
        size: 20
        color: ThemeManager.colors.accent
    }

    Txt {
        id: label

        anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: ThemeManager.font.large
        font.weight: Font.DemiBold
    }
}
