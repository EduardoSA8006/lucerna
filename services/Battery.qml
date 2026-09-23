pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Bateria do notebook, via UPower. `available` é falso em desktops.
Singleton {
    id: root

    readonly property UPowerDevice device: UPower.displayDevice
    readonly property bool available: (device?.ready ?? false) && device.isLaptopBattery && device.isPresent
    readonly property real percentage: device?.percentage ?? 0
    readonly property bool charging: device?.state === UPowerDeviceState.Charging || device?.state === UPowerDeviceState.PendingCharge
    readonly property bool full: device?.state === UPowerDeviceState.FullyCharged
    readonly property bool onBattery: UPower.onBattery
    // Segundos até esvaziar (descarregando) ou encher (carregando); 0 se desconhecido.
    readonly property real timeRemaining: charging ? (device?.timeToFull ?? 0) : (device?.timeToEmpty ?? 0)
    readonly property real health: device?.healthSupported ? device.healthPercentage / 100 : NaN
    readonly property real changeRate: device?.changeRate ?? 0

    // Perfil de energia (power-profiles-daemon): 0 economia, 1 equilibrado, 2 desempenho.
    readonly property int profile: PowerProfiles.profile
    readonly property bool hasPerformance: PowerProfiles.hasPerformanceProfile

    function setProfile(value: int): void {
        const names = ["Modo economia", "Modo equilibrado", "Modo desempenho"];
        if (!DevMode.simulate(names[value] ?? "Perfil de energia"))
            PowerProfiles.profile = value;
    }
}
