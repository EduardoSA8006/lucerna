pragma Singleton

import QtQuick
import Quickshell
import qs.core.panels
import qs.core.widgets
import qs.services

// View model da barra: junta o que os serviços informam no formato que a UI mostra.
Singleton {
    id: root

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
    readonly property int volumePercent: Math.round(Audio.volume * 100)
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
    readonly property string networkLabel: Network.kind === "offline" ? "Desconectado" : Network.name
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
}
