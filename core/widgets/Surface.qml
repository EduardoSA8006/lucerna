import QtQuick
import qs.core.theme

// Cartão/painel com o fundo, a borda e o raio do tema.
Rectangle {
    property bool raisedLevel: false

    color: raisedLevel ? ThemeManager.colors.raised : ThemeManager.colors.surface
    radius: ThemeManager.radius.large
    border.color: ThemeManager.colors.border
    border.width: 1
}
