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
}
