pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.core.config
import qs.core.format
import qs.core.panels
import qs.core.theme
import qs.services

// View model das notificações: popups e central lateral.
Singleton {
    id: root

    // Com a central lateral aberta os popups esperam: ficariam por cima dela.
    readonly property bool sidebarOpen: Panels.isOpen("sidebar")

    // A lista de notificações fica na central lateral, na seção "notifications".
    readonly property bool centerOpen: Panels.isOpen("sidebar") && Config.sidebarSection === "notifications"
    readonly property var screen: Hypr.focusedScreen
    readonly property real topOffset: Panels.topInset
    readonly property var popups: Notifications.popups
    readonly property var list: Notifications.list
    readonly property bool doNotDisturb: Config.doNotDisturb

    // Abrir a central conta como ter visto os popups.
    onCenterOpenChanged: {
        if (centerOpen)
            Notifications.clearPopups();
    }

    // O "não perturbe" e o tempo dos popups são salvos na config e repassados ao serviço.
    Binding {
        target: Notifications
        property: "doNotDisturb"
        value: Config.doNotDisturb
    }

    Binding {
        target: Notifications
        property: "defaultTimeout"
        value: Config.notificationTimeout
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
        return Format.since(Notifications.timeOf(notification), clock.date);
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
