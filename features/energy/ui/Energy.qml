import QtQuick
import Quickshell
import qs.features.energy.state

// A feature de energia não desenha nada: este objeto só a coloca para rodar
// (os avisos e automações vivem no EnergyState).
Scope {
    readonly property bool running: EnergyState.available
}
