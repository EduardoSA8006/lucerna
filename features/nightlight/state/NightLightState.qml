pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core.config
import qs.core.nightlight
import qs.services

// Aplica a luz noturna: leva a temperatura do horário (NightSchedule) ao
// hyprsunset, que só fica aberto enquanto ela está ligada ou em prévia.
Singleton {
    // O hyprsunset está aberto e respondendo.
    readonly property bool ready: NightLight.ready

    Binding {
        target: NightLight
        property: "wanted"
        value: NightSchedule.enabled || NightSchedule.previewing
    }

    Binding {
        target: NightLight
        property: "temperature"
        value: NightSchedule.temperature
    }

    IpcHandler {
        target: "nightlight"

        // Liga ou desliga a função.
        function enable(on: bool): void {
            Config.nightLightEnabled = on;
            Config.nightLightOverride = null;
        }

        // Liga ou desliga agora, até a próxima virada do horário.
        function toggle(): void {
            NightSchedule.setOn(!NightSchedule.on);
        }

        function temperature(kelvin: int): void {
            Config.nightLightTemp = Math.max(1500, Math.min(6500, kelvin));
        }

        function status(): string {
            return `${NightSchedule.status} (${NightSchedule.temperature || NightSchedule.dayTemp} K)`;
        }
    }
}
