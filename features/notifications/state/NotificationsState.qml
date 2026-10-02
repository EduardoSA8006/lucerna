pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.core.config
import qs.core.format
import qs.core.panels
import qs.services

// View model das notificações: os popups (a lista fica na central).
Singleton {
    id: root

    // A central mostra a lista de notificações: com ela aberta, os popups
    // esperam (ficariam por cima dela); abrir e fechar contam como tê-los visto.
    readonly property bool centralOpen: Panels.isOpen("central")

    onCentralOpenChanged: Notifications.clearPopups()
    readonly property var screen: Hypr.focusedScreen
    readonly property real topOffset: Panels.topInset
    readonly property var popups: Notifications.popups
    readonly property var list: Notifications.list
    readonly property bool doNotDisturb: Config.doNotDisturb

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
