import QtQuick
import qs.core.theme
import qs.core.widgets

// Estado vazio de uma seção: forma orgânica com ícone e uma frase.
Column {
    property string icon
    property string text

    width: parent?.width ?? 0
    topPadding: ThemeManager.spacing.large * 2
    spacing: ThemeManager.spacing.normal

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 88
        height: 88

        Blob {
            anchors.fill: parent
            lobes: 7
            amplitude: 0.06
            color: ThemeManager.colors.track
            spinning: parent.visible
            spinDuration: 30000
        }

        Icon {
            anchors.centerIn: parent
            icon: parent.parent.icon
            size: 36
            color: ThemeManager.colors.textFaint
        }
    }

    Txt {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        text: parent.text
        faint: true
    }
}
