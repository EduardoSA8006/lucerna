import QtQuick
import qs.core.theme

// Separador vertical discreto entre os grupos da barra.
Rectangle {
    anchors.verticalCenter: parent.verticalCenter
    width: 1
    height: 16
    color: ThemeManager.colors.border
    opacity: 0.8
}
