pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.core.config
import qs.core.panels
import qs.services

// View model das notificações: popups e central lateral.
Singleton {
    id: root

    readonly property bool centerOpen: Panels.isOpen("notifications")
    readonly property var screen: Hypr.focusedScreen
    readonly property var popups: Notifications.popups
    readonly property var list: Notifications.list
    readonly property bool doNotDisturb: Config.doNotDisturb

    // Abrir a central conta como ter visto os popups.
    onCenterOpenChanged: {
        if (centerOpen)
            Notifications.clearPopups();
    }

    // O "não perturbe" é salvo na config e repassado ao serviço.
    Binding {
        target: Notifications
        property: "doNotDisturb"
        value: Config.doNotDisturb
    }

    IpcHandler {
        target: "notifications"

        function clear(): void {
            root.clearAll();
        }

        function toggleDnd(): void {
            root.toggleDoNotDisturb();
        }

        function count(): int {
            return root.list.length;
        }
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    function close(): void {
        Panels.close();
    }

    function toggleDoNotDisturb(): void {
        Config.doNotDisturb = !Config.doNotDisturb;
    }

    function dismiss(notification: var): void {
        Notifications.dismiss(notification);
    }

    function clearAll(): void {
        Notifications.clearAll();
    }

    function hidePopup(notification: var): void {
        Notifications.hidePopup(notification);
    }

    function timeoutFor(notification: var): int {
        return Notifications.timeoutFor(notification);
    }

    function isCritical(notification: var): bool {
        return notification.urgency === NotificationUrgency.Critical;
    }

    function invoke(notification: var, action: var): void {
        action.invoke();
        if (!notification.resident)
            Notifications.dismiss(notification);
    }

    // "agora", "há 5 min", "14:03" ou "12/09"
    function timeLabel(notification: var): string {
        const at = Notifications.timeOf(notification);
        const minutes = Math.floor((clock.date - at) / 60000);
        if (minutes < 1)
            return "agora";
        if (minutes < 60)
            return `há ${minutes} min`;
        if (at.toDateString() === clock.date.toDateString())
            return Qt.formatTime(at, "HH:mm");
        return Qt.formatDate(at, "dd/MM");
    }

    // Imagem da notificação (foto, capa) ou ícone do app; "" se nenhum.
    function imageFor(notification: var): string {
        if (notification.image)
            return notification.image;
        const icon = notification.appIcon;
        if (!icon)
            return "";
        if (icon.startsWith("/"))
            return `file://${icon}`;
        if (icon.includes("://"))
            return icon;
        return Quickshell.iconPath(icon, true);
    }
}
