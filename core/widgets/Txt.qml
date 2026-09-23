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
}
