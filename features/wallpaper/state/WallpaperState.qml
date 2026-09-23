pragma Singleton

import QtQuick
import Quickshell
import qs.core.theme

// O wallpaper vem do tema ativo.
Singleton {
    readonly property string source: ThemeManager.wallpaper ? `file://${ThemeManager.wallpaper}` : ""
    readonly property int fadeDuration: ThemeManager.anim.extraLarge
}
