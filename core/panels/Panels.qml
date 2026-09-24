pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.core.config
import qs.core.theme

// Ponte entre features: diz quais painéis estão abertos.
//
// Três tipos:
// - modais (launcher, themes, power): ficam sozinhos, abrir um fecha os outros;
// - acompanhantes (dashboard, sidebar; quais, vem da config): ficam abertos
//   juntos, sem cobrir a barra;
// - base (settings): abrir fecha os outros, mas acompanhantes abertos depois
//   ficam por cima dela.
// Um clique fora de todos (numa janela) fecha os não modais; Esc fecha só o
// que está com o teclado.
Singleton {
    id: root

    readonly property var companions: (Config.panelsTogether ?? []).filter(n => ["dashboard", "sidebar"].includes(n))
    readonly property var bases: ["settings"]
    // Acompanhantes desviam uns dos outros (ver leftInset e rightInset).
    readonly property bool avoidOverlap: Config.panelsAvoidOverlap

    // Nomes abertos, na ordem em que abriram.
    property var opened: []
    // O último aberto.
    readonly property string current: opened.length ? opened[opened.length - 1] : ""
    readonly property bool anyOpen: opened.length > 0
    readonly property bool modalOpen: opened.some(n => isModal(n))

    // Espaço ocupado nas bordas por um acompanhante (a central lateral), para
    // os outros desviarem.
    property real leftInset: 0
    property real rightInset: 0

    // Um painel que deixou de ser acompanhante (mudança na config) não fica
    // aberto junto: sobra só ele.
    onCompanionsChanged: {
        const modals = opened.filter(n => isModal(n));
        if (modals.length && opened.length > 1)
            opened = [modals[modals.length - 1]];
    }

    function isCompanion(name: string): bool {
        return companions.includes(name);
    }

    function isModal(name: string): bool {
        return !isCompanion(name) && !bases.includes(name);
    }

    function open(name: string): void {
        if (!isCompanion(name))
            opened = [name];
        else if (!opened.includes(name))
            opened = opened.filter(n => !isModal(n)).concat([name]);
    }

    // Fecha todos.
    function close(): void {
        opened = [];
    }

    // Fecha só este.
    function dismiss(name: string): void {
        lastDismiss = Date.now();
        opened = opened.filter(n => n !== name);
    }

    function toggle(name: string): void {
        if (isOpen(name))
            dismiss(name);
        else
            open(name);
    }

    // Janelas que não fecham os acompanhantes ao receber um clique: as dos
    // painéis e as da barra. Cada uma se registra ao ser criada.
    property var surfaces: []

    function register(window: var): void {
        surfaces = surfaces.concat([window]);
    }

    function unregister(window: var): void {
        surfaces = surfaces.filter(w => w !== window);
    }

    // Fechar o acompanhante que estava com o teclado faz o Hyprland mandar o
    // teclado para fora e desfazer o grab. Se ele cai logo depois de um fechar
    // e ainda sobra algum aberto, não foi clique fora: arma de novo.
    property real lastDismiss: 0
    property bool rearming: false

    HyprlandFocusGrab {
        active: root.anyOpen && !root.modalOpen && !root.rearming
        windows: root.surfaces
        onCleared: {
            if (root.anyOpen && Date.now() - root.lastDismiss < 400) {
                root.rearming = true;
                Qt.callLater(() => root.rearming = false);
            } else {
                root.close();
            }
        }
    }

    // Distância do topo para os painéis que descem ou encostam no topo: colados
    // à borda com a barra escondida; abaixo dela quando ela está fixa.
    readonly property real topInset: {
        const gap = ThemeManager.spacing.small;
        if (Config.barAutoHide)
            return gap;
        return Config.barStyle === "strip" ? ThemeManager.barHeight + gap : ThemeManager.barHeight + gap * 2;
    }

    function isOpen(name: string): bool {
        return opened.includes(name);
    }

    // Central lateral numa seção (wifi, bluetooth, sound, notifications, battery, display).
    function openSidebar(section: string): void {
        Config.sidebarSection = section;
        open("sidebar");
    }

    // Fecha se já estiver aberta nessa seção; senão abre (ou troca) para ela.
    function toggleSidebar(section: string): void {
        if (isOpen("sidebar") && Config.sidebarSection === section)
            dismiss("sidebar");
        else
            openSidebar(section);
    }

    IpcHandler {
        target: "panels"

        function open(name: string): void {
            root.open(name);
        }

        function close(): void {
            root.close();
        }

        function dismiss(name: string): void {
            root.dismiss(name);
        }

        function toggle(name: string): void {
            root.toggle(name);
        }

        function get(): string {
            return root.opened.join(" ");
        }
    }
}
