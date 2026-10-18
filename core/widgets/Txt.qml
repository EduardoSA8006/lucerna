import QtQuick
import qs.core.theme

// Texto no estilo do tema. Use `muted`/`faint` para hierarquia e `mono` para números.
Text {
    property bool muted: false
    property bool faint: false
    property bool mono: false

    color: faint ? ThemeManager.colors.textFaint : muted ? ThemeManager.colors.textMuted : ThemeManager.colors.text
    font.family: mono ? ThemeManager.font.mono : ThemeManager.font.sans
    font.pixelSize: ThemeManager.font.normal
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter

    // A Rubik dos temas é variável e carregada pelo FontLoader: o Qt não leva o
    // `font.weight` para o eixo wght dela (ficava a instância padrão, Light, e
    // os pesos maiores saíam como negrito sintético). O eixo explícito aplica
    // o peso de verdade; numa fonte estática, o eixo é ignorado. Atualizado à
    // mão: uma binding de font.variableAxes lendo font.weight é um laço.
    onFontChanged: syncWeight()
    Component.onCompleted: syncWeight()

    function syncWeight(): void {
        if (font.variableAxes.wght !== font.weight)
            font.variableAxes = ThemeManager.fontAxes(font.weight);
    }
}
