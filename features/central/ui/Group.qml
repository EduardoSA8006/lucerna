import QtQuick
import qs.core.theme
import qs.core.widgets

// Cartão interno de um painel da central (o mesmo tom dos cartões de
// notificação), com uma folga pequena. O conteúdo vai numa coluna, e a altura
// acompanha.
Surface {
    id: root

    default property alias content: column.data

    raisedLevel: true
    radius: ThemeManager.radius.normal
    width: parent?.width ?? 0
    height: column.implicitHeight + ThemeManager.spacing.tiny * 2

    Column {
        id: column

        x: ThemeManager.spacing.tiny
        y: ThemeManager.spacing.tiny
        width: root.width - x * 2
    }
}
