pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// Bateria do notebook, via UPower. `available` é falso em desktops.
//
// No modo de desenvolvimento dá para simular a bateria por IPC, para testar
// avisos e automações sem tirar o notebook da tomada:
//   qs -c lucerna ipc call battery simulate 12 true   (12%, na bateria)
//   qs -c lucerna ipc call battery real
Singleton {
    id: root

    // { percentage (0-1), onBattery } ou null (valores reais)
    property var simulated: null

    readonly property UPowerDevice device: UPower.displayDevice
    readonly property bool available: simulated !== null || ((device?.ready ?? false) && device.isLaptopBattery && device.isPresent)
    readonly property real percentage: simulated ? simulated.percentage : (device?.percentage ?? 0)
    readonly property bool onBattery: simulated ? simulated.onBattery : UPower.onBattery
    readonly property bool charging: simulated ? !simulated.onBattery && simulated.percentage < 1 : (device?.state === UPowerDeviceState.Charging || device?.state === UPowerDeviceState.PendingCharge)
    readonly property bool full: simulated ? !simulated.onBattery && simulated.percentage >= 1 : device?.state === UPowerDeviceState.FullyCharged
    // Segundos até esvaziar (descarregando) ou encher (carregando); 0 se desconhecido.
    readonly property real timeRemaining: simulated ? 0 : charging ? (device?.timeToFull ?? 0) : (device?.timeToEmpty ?? 0)
    readonly property real health: device?.healthSupported ? device.healthPercentage / 100 : NaN
    readonly property real changeRate: simulated ? 0 : device?.changeRate ?? 0

    // Perfil de energia (power-profiles-daemon): 0 economia, 1 equilibrado, 2 desempenho.
    // No modo de desenvolvimento a troca é simulada, e o perfil simulado fica aqui.
    property int simulatedProfile: -1
    readonly property int profile: simulatedProfile >= 0 ? simulatedProfile : PowerProfiles.profile
    readonly property bool hasPerformance: PowerProfiles.hasPerformanceProfile
    readonly property var profileNames: ["Economia", "Equilibrado", "Desempenho"]

    function setProfile(value: int): void {
        if (value === profile)
            return;
        if (DevMode.simulate(`Perfil ${profileNames[value] ?? value}`))
            simulatedProfile = value;
        else
            PowerProfiles.profile = value;
    }

    IpcHandler {
        target: "battery"
        enabled: DevMode.active

        // Simula a bateria (percentual de 0 a 100; na bateria ou na tomada).
        function simulate(percent: int, onBattery: bool): void {
            root.simulated = { percentage: Math.max(0, Math.min(100, percent)) / 100, onBattery: onBattery };
        }

        // Volta aos valores reais.
        function real(): void {
            root.simulated = null;
        }
    }
}
