pragma Singleton

import QtQuick
import Quickshell
import qs.core.config
import qs.core.panels
import qs.core.widgets
import qs.services

// View model da barra: o que ela mostra e quando ela aparece.
//
// Com auto-ocultar ligado, a barra fica escondida e aparece na tela onde o
// mouse encostou no topo (ou, por um instante, ao trocar de workspace). Some
// quando o mouse sai e quando um painel abre. Na área de trabalho vazia (sem
// janelas no workspace daquela tela), fica à mostra: não cobre nada.
Singleton {
    id: root

    // Visibilidade
    readonly property bool autoHide: Config.barAutoHide
    readonly property string style: Config.barStyle
    readonly property bool showDate: Config.barShowDate
    readonly property bool panelOpen: Panels.current !== ""
    property var revealedScreen: null
    property bool hovering: false
    property bool peeking: false
    // A ilha se expande (workspaces, data e ações) com o mouse em cima e ao
    // aparecer por troca de workspace; no resto do tempo mostra só a hora.
    readonly property bool expanded: hovering || peeking

    function shownOn(screen: var): bool {
        if (!autoHide)
            return true;
        if (panelOpen)
            return false;
        return revealedScreen === screen || (Config.barOnEmpty && Hypr.isScreenEmpty(screen));
    }

    // Mouse encostou no topo da tela.
    function reveal(screen: var): void {
        revealedScreen = screen;
        hideDelay.stop();
    }

    function setHovering(on: bool): void {
        hovering = on;
        if (on)
            hideDelay.stop();
        else
            hideDelay.restart();
    }

    // Aparece por um instante (troca de workspace).
    function peek(screen: var): void {
        if (panelOpen)
            return;
        // Barra fixa: não precisa aparecer, só expandir por um instante.
        if (!autoHide) {
            peeking = true;
            peekDelay.restart();
            return;
        }
        revealedScreen = screen;
        peeking = true;
        peekDelay.restart();
    }

    Timer {
        id: hideDelay

        interval: 450
        onTriggered: {
            if (!root.hovering)
                root.revealedScreen = null;
        }
    }

    Timer {
        id: peekDelay

        interval: 1400
        onTriggered: {
            root.peeking = false;
            if (!root.hovering)
                root.revealedScreen = null;
        }
    }

    Connections {
        target: Hypr

        function onFocusedWorkspaceIdChanged() {
            if (Config.barPeek)
                root.peek(Hypr.focusedScreen);
        }
    }

    // Workspaces: sempre mostra pelo menos `minWorkspaces`, mais os que existirem além disso.
    readonly property int minWorkspaces: 5
    readonly property var workspaceIds: {
        const highest = Math.max(minWorkspaces, Hypr.focusedWorkspaceId, ...Hypr.workspaces.map(w => w.id));
        return Array.from({ length: highest }, (_, i) => i + 1);
    }

    // "focused", "occupied" ou "empty"
    function workspaceState(id: int): string {
        if (Hypr.focusedWorkspaceId === id)
            return "focused";
        const ws = Hypr.workspace(id);
        return ws && ws.toplevels.values.length > 0 ? "occupied" : "empty";
    }

    function focusWorkspace(id: int): void {
        Hypr.focusWorkspace(id);
    }

    function cycleWorkspace(step: int): void {
        Hypr.cycleWorkspace(step);
    }

    // Relógio
    readonly property string time: Qt.formatTime(clock.date, "HH:mm")
    readonly property string date: clock.date.toLocaleDateString(Qt.locale("pt_BR"), "ddd, d 'de' MMM").replace(/\./g, "")

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    // Áudio
    readonly property bool audioAvailable: Audio.available
    readonly property bool muted: Audio.muted
    readonly property string volumeIcon: Audio.muted || Audio.volume === 0 ? Icons.volumeOff : Audio.volume < 0.34 ? Icons.volumeLow : Audio.volume < 0.67 ? Icons.volumeMedium : Icons.volumeHigh

    function scrollVolume(steps: real): void {
        Audio.changeVolume(steps * 0.05);
    }

    function toggleMute(): void {
        Audio.toggleMute();
    }

    // Rede
    readonly property bool networkAvailable: Network.available
    readonly property bool online: Network.kind !== "offline"
    readonly property string networkIcon: Network.kind === "wired" ? Icons.ethernet : Network.kind === "wifi" ? Icons.level(Icons.wifi, Network.signal) : Network.wifiEnabled ? Icons.offline : Icons.wifiOff

    // Bateria
    readonly property bool batteryAvailable: Battery.available
    readonly property int batteryPercent: Math.round(Battery.percentage * 100)
    readonly property bool batteryLow: Battery.percentage < 0.15 && !Battery.charging
    readonly property string batteryIcon: Battery.charging ? Icons.batteryCharging : batteryLow ? Icons.batteryAlert : Icons.level(Icons.battery, Battery.percentage)

    // Notificações
    readonly property int notificationCount: Notifications.count
    readonly property bool doNotDisturb: Notifications.doNotDisturb
    readonly property string bellIcon: doNotDisturb ? Icons.bellSleep : notificationCount > 0 ? Icons.bellBadge : Icons.bellOutline

    // Painéis
    readonly property string openPanel: Panels.current

    function togglePanel(name: string): void {
        Panels.toggle(name);
    }

    // Abre a central lateral na seção (ou fecha, se já estiver nela).
    function toggleSection(section: string): void {
        Panels.toggleSidebar(section);
    }

    function sectionOpen(section: string): bool {
        return Panels.isOpen("sidebar") && Config.sidebarSection === section;
    }
}
