import QtQuick
import qs.core.theme

// Glifo da fonte de ícones do tema. Os nomes ficam em Icons.qml.
Text {
    property string icon
    property int size: ThemeManager.font.large

    text: icon
    color: ThemeManager.colors.text
    font.family: ThemeManager.font.icon
    font.pixelSize: size
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
