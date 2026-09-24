import QtQuick
import qs.core.theme
import qs.features.bar.state

// Fundo de vidro de um pedaço da barra, que avisa o hover para a lógica de
// mostrar/esconder e de expandir.
Rectangle {
    color: ThemeManager.glass(ThemeManager.colors.base, 0)
    border.width: ThemeManager.outlines ? 1 : 0
    border.color: ThemeManager.colors.border

    HoverHandler {
        onHoveredChanged: BarState.setHovering(hovered)
    }
}
