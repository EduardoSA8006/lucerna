import QtQuick
import qs.core.theme
import qs.core.widgets

// Botão de ícone da central: cheio (o acento) quando ligado, vazio quando
// desligado. Quem usa dá o tamanho.
Clickable {
    id: root

    property string icon
    property bool checked: false

    active: checked
    radius: ThemeManager.radius.normal
    pressScale: 0.94
    color: checked ? ThemeManager.colors.accent : ThemeManager.alpha(ThemeManager.colors.text, 0.06)

    Icon {
        anchors.centerIn: parent
        icon: root.icon
        size: 22
        filled: root.checked
        color: root.checked ? ThemeManager.colors.accentText : ThemeManager.colors.textMuted

        Behavior on color { ColorAnim {} }
    }
}
