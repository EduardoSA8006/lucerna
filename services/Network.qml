pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

// Estado da conexão principal, via NetworkManager. O cabo tem preferência sobre o Wi-Fi.
Singleton {
    id: root

    readonly property bool available: Networking.backend !== NetworkBackendType.None
    readonly property var devices: Networking.devices.values
    readonly property var wiredDevice: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var wifiDevice: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiNetwork: wifiDevice?.networks.values.find(n => n.connected) ?? null

    // "wired", "wifi" ou "offline"
    readonly property string kind: wiredDevice ? "wired" : wifiNetwork ? "wifi" : "offline"
    readonly property string name: wiredDevice ? (wiredDevice.network?.name || wiredDevice.name) : (wifiNetwork?.name ?? "")
    readonly property real signal: wifiNetwork?.signalStrength ?? 0
    readonly property bool wifiEnabled: Networking.wifiEnabled
}
