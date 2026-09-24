import QtQuick
import Quickshell
import qs.features.input.state

// A feature de entrada não desenha nada: este objeto só a coloca para rodar
// (a aplicação dos ajustes e as ações vivem no InputState).
Scope {
    readonly property bool ready: InputState.ready
}
