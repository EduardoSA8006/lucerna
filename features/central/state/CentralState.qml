pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core.panels
import qs.services

// View model da central: os dois painéis flutuantes da direita (ações em
// cima, notificações embaixo) que abrem e fecham juntos. O painel de ações
// mostra os tiles e os sliders ou a página de um recurso (`page`). A entrada
// (Panels.centralEntry) escolhe a página que já vem aberta; sem o recurso, o
// estado inicial. A abertura volta tudo ao estado inicial (o fechamento não:
// o card fica na página até sumir).
Singleton {
    id: root

    readonly property bool open: Panels.isOpen("central")
    readonly property var screen: Hypr.focusedScreen
    // Distância do topo da tela: abaixo da barra, como o painel superior.
    readonly property real top: Panels.topInset

    // O que existe na máquina, para as páginas e os tiles.
    readonly property var has: ({
            wifi: WifiState.available,
            bluetooth: BluetoothState.available,
            output: SoundState.available,
            input: SoundState.hasMic,
            power: PowerState.any
        })

    // A página do painel de ações: "" (os tiles e os sliders), "wifi",
    // "bluetooth", "output", "input" ou "battery".
    property string page: ""

    // Zera só ao abrir: na saída, o card continua na página até sumir.
    onOpenChanged: {
        if (open)
            reset();
    }

    // O recurso da página aberta sumiu (o fone saiu, o adaptador some): volta
    // ao estado inicial.
    onHasChanged: page = pageIfPresent(page, has)

    Connections {
        target: Panels

        function onCentralOpened(entry) {
            root.page = root.pageFor(entry, root.has);
            root.clearWifi();
        }
    }

    // O Wi-Fi procura redes enquanto a página dele está à mostra.
    Binding {
        target: Network
        property: "scanning"
        value: root.open && root.page === "wifi"
    }

    // A página de cada entrada, se o recurso dela existir.
    function pageFor(entry: string, has: var): string {
        const i = ["rede", "bluetooth", "som", "energia", "microfone"].indexOf(entry);
        return pageIfPresent(i >= 0 ? ["wifi", "bluetooth", "output", "battery", "input"][i] : "", has);
    }

    // A página, se o recurso dela existir; senão, o estado inicial.
    function pageIfPresent(page: string, has: var): string {
        const i = ["wifi", "bluetooth", "output", "input", "battery"].indexOf(page);
        return i >= 0 && has[["wifi", "bluetooth", "output", "input", "power"][i]] ? page : "";
    }

    // Fecha o campo de senha e apaga o erro do Wi-Fi.
    function clearWifi(): void {
        WifiState.expanded = null;
        WifiState.error = "";
    }

    function reset(): void {
        page = "";
        clearWifi();
    }

    function setPage(value: string): void {
        page = value;
    }

    function close(): void {
        Panels.dismiss("central");
    }

    IpcHandler {
        target: "central"

        // Abre numa entrada: rede, bluetooth, som, energia, microfone, notificacoes ("" = o estado inicial).
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
