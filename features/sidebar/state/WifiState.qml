pragma Singleton

import QtQuick
import Quickshell
import qs.core.widgets
import qs.services

// View model da seção Wi-Fi.
Singleton {
    id: root

    readonly property bool available: Network.available && Network.wifiDevice !== null
    readonly property bool enabled: Network.wifiEnabled
    readonly property bool hardwareBlocked: !Network.wifiHardwareEnabled
    readonly property bool wired: Network.kind === "wired"
    readonly property string status: !available ? "Sem placa Wi-Fi" : hardwareBlocked ? "Bloqueado pelo botão do aparelho" : !enabled ? "Desligado" : Network.wifiNetwork ? `Conectado a ${Network.wifiNetwork.name}` : "Não conectado"

    readonly property var networks: Network.wifiNetworks.map(n => ({
        network: n,
        name: n.name,
        connected: n.connected,
        known: n.known,
        busy: n.stateChanging,
        secure: Network.isSecure(n),
        needsPassword: Network.needsPassword(n),
        icon: Icons.level(Icons.wifi, n.signalStrength),
        signal: Math.round(n.signalStrength * 100)
    }))

    // Rede com o campo de senha aberto.
    property var expanded: null
    property string error: ""

    Connections {
        target: Network

        function onConnectionFailed(network, reason) {
            root.error = `Não foi possível conectar a ${network}${reason ? ` (${reason})` : ""}`;
        }
    }

    function setEnabled(on: bool): void {
        Network.setWifiEnabled(on);
    }

    // Clique numa rede: desconecta a atual, pede senha ou conecta direto.
    function activate(item: var): void {
        error = "";
        if (item.connected) {
            Network.disconnect(item.network);
        } else if (item.needsPassword) {
            expanded = expanded === item.network ? null : item.network;
        } else {
            Network.connect(item.network, "");
        }
    }

    function submitPassword(item: var, password: string): void {
        if (!password)
            return;
        Network.connect(item.network, password);
        expanded = null;
    }

    function forget(item: var): void {
        Network.forget(item.network);
    }
}
