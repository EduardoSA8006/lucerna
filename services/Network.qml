pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

// Rede via NetworkManager: a conexão principal (o cabo tem preferência sobre o
// Wi-Fi) e as redes Wi-Fi disponíveis. Ações que mudam a rede passam pelo
// DevMode, para não mexer na rede do host no ambiente de desenvolvimento.
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
    readonly property bool wifiHardwareEnabled: Networking.wifiHardwareEnabled
    readonly property string address: (wiredDevice ?? wifiDevice)?.address ?? ""

    // Redes Wi-Fi: a conectada primeiro, depois as conhecidas, depois por sinal.
    // Redes sem nome (ocultas) ficam de fora.
    readonly property var wifiNetworks: (wifiDevice?.networks.values ?? []).filter(n => n.name).slice().sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength))

    // Procura redes enquanto alguém mostra a lista.
    property bool scanning: false

    Binding {
        target: root.wifiDevice
        property: "scannerEnabled"
        value: root.wifiEnabled
        when: root.wifiDevice !== null && root.scanning
    }

    signal connectionFailed(string network, string reason)

    // Redes que já avisam falha de conexão (para não ligar o aviso duas vezes).
    property var watched: []

    function isSecure(network: var): bool {
        return network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Owe;
    }

    function needsPassword(network: var): bool {
        return !network.known && network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Owe;
    }

    function setWifiEnabled(on: bool): void {
        if (!DevMode.simulate(on ? "Ligar o Wi-Fi" : "Desligar o Wi-Fi"))
            Networking.wifiEnabled = on;
    }

    function connect(network: var, password: string): void {
        if (DevMode.simulate(`Conectar a "${network.name}"`))
            return;
        if (!watched.includes(network)) {
            watched = [...watched, network];
            network.connectionFailed.connect(reason => root.connectionFailed(network.name, ConnectionFailReason.toString(reason)));
        }
        if (password)
            network.connectWithPsk(password);
        else
            network.connect();
    }

    function disconnect(network: var): void {
        if (!DevMode.simulate(`Desconectar de "${network.name}"`))
            network.disconnect();
    }

    function forget(network: var): void {
        if (!DevMode.simulate(`Esquecer "${network.name}"`))
            network.forget();
    }
}
