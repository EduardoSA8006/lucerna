import QtQuick
import Quickshell

// Uma barra por monitor.
Variants {
    model: Quickshell.screens

    delegate: BarWindow {}
}
