import QtQuick
import Quickshell
import qs.features.wallpaper.ui

// Papel de parede em cada monitor. Um monitor que sai de Quickshell.screens
// leva a janela junto.
Variants {
    model: Quickshell.screens

    delegate: WallpaperWindow {
        required property var modelData

        targetScreen: modelData
    }
}
