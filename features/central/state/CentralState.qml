pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core.panels
import qs.services

// View model da central: os quatro painéis flutuantes (som e energia à
// esquerda, controles e notificações à direita) que abrem e fecham juntos. A
// entrada (Panels.centralEntry) escolhe o que já vem aberto: "rede" abre o
// card de controles na lista de redes (sem placa Wi-Fi, no estado inicial);
// "bluetooth", nos dispositivos; as outras, o estado inicial. Abrir e fechar
// voltam tudo ao estado inicial.
Singleton {
    id: root

    readonly property bool open: Panels.isOpen("central")
    readonly property var screen: Hypr.focusedScreen
    readonly property string entry: Panels.centralEntry
    // Distância do topo da tela: abaixo da barra, como o painel superior.
    readonly property real top: Panels.topInset
    readonly property bool hasWifi: WifiState.available

    // O que o card de controles mostra ("" os controles; "wifi" ou
    // "bluetooth", a página do recurso) e o card de saída e entrada do som
    // ("" os volumes; "outputs" ou "inputs", a lista de dispositivos).
    property string controlsPage: ""
    property string soundPage: ""

    // Zera só ao abrir: na saída, o card continua na página até sumir.
    onOpenChanged: {
        if (open)
            reset();
    }

    Connections {
        target: Panels

        function onCentralOpened(entry) {
            root.controlsPage = root.pageFor(entry, root.hasWifi);
            root.soundPage = "";
        }
    }

    // O Wi-Fi procura redes enquanto a página dele está à mostra.
    Binding {
        target: Network
        property: "scanning"
        value: root.open && root.controlsPage === "wifi"
    }

    function pageFor(entry: string, hasWifi: bool): string {
        return entry === "rede" && hasWifi ? "wifi" : entry === "bluetooth" ? "bluetooth" : "";
    }

    // Também fecha o campo de senha e apaga o erro do Wi-Fi.
    function reset(): void {
        controlsPage = "";
        soundPage = "";
        WifiState.expanded = null;
        WifiState.error = "";
    }

    function setControlsPage(page: string): void {
        controlsPage = page;
    }

    function setSoundPage(page: string): void {
        soundPage = page;
    }

    function close(): void {
        Panels.dismiss("central");
    }

    IpcHandler {
        target: "central"

        // Abre numa entrada: rede, bluetooth, som, notificacoes, energia ("" = o estado inicial).
        function open(entry: string): void {
            Panels.openCentral(entry);
        }

        function toggle(entry: string): void {
            Panels.toggleCentral(entry);
        }

        function close(): void {
            root.close();
        }
    }
}
