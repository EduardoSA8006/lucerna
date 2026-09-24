import QtQuick
import Quickshell
import qs.features.nightlight.state

// A luz noturna não desenha nada (a cor muda na CTM do Hyprland): este objeto
// só a coloca para rodar. O horário vive em core/nightlight e a aplicação no NightLightState.
Scope {
    readonly property bool ready: NightLightState.ready
}
