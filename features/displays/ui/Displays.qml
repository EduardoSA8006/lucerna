import QtQuick
import Quickshell
import qs.features.displays.state

// A feature de monitores não desenha nada: este objeto só a coloca para rodar
// (a restauração do arranjo salvo vive no DisplaysState).
Scope {
    readonly property string setup: DisplaysState.setup
}
