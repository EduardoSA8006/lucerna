pragma Singleton

import QtQuick
import Quickshell
import qs.core.config
import qs.core.nightlight
import qs.core.panels
import qs.core.widgets
import qs.services

// View model do painel de controles da central: o brilho da tela em foco e
// os botões de ícone (luz noturna, não perturbe, não apagar a tela e
// configurações). O card de rede usa o WifiState e o BluetoothState.
Singleton {
    id: root

    // A tela em foco: a externa desse monitor, se tiver DDC; senão a integrada.
    readonly property var screenBrightness: Brightness.screens.find(s => s.id === Brightness.focusedId()) ?? null
    readonly property bool hasBrightness: screenBrightness !== null
    readonly property real brightness: screenBrightness?.value ?? 0

    function setBrightness(value: real): void {
        if (screenBrightness)
            Brightness.setScreen(screenBrightness.id, value);
    }

    // { id, icon, checked }. Sem o hyprsunset, sem a luz noturna; sem a
    // ociosidade do shell, sem o "não apagar a tela". Configurações só abre.
    readonly property var toggles: [
        ...(NightLight.available ? [{ id: "nightlight", icon: "nightlight", checked: NightSchedule.on }] : []),
        { id: "dnd", icon: Icons.bellSleep, checked: Config.doNotDisturb },
        ...(Config.idleEnabled ? [{ id: "awake", icon: "coffee", checked: Config.idleInhibit }] : []),
        { id: "settings", icon: Icons.settings, checked: false }
    ]

    function trigger(id: string): void {
        if (id === "nightlight")
            NightSchedule.setOn(!NightSchedule.on);
        else if (id === "dnd")
            Config.doNotDisturb = !Config.doNotDisturb;
        else if (id === "awake")
            Config.idleInhibit = !Config.idleInhibit;
        else if (id === "settings")
            Panels.open("settings");
    }
}
