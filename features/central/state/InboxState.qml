pragma Singleton

import QtQuick
import Quickshell
import qs.services

// View model do painel de notificações da central.
Singleton {
    id: root

    readonly property var list: Notifications.list

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    function clearAll(): void {
        Notifications.clearAll();
    }

    function dismiss(n: var): void {
        Notifications.dismiss(n);
    }

    function invoke(n: var, action: var): void {
        action.invoke();
        if (!n.resident)
            Notifications.dismiss(n);
    }

    // "agora", "há 5 min", "14:03" ou "12/09"
    function timeLabel(n: var): string {
        const at = Notifications.timeOf(n);
        const minutes = Math.floor((clock.date - at) / 60000);
        if (minutes < 1)
            return "agora";
        if (minutes < 60)
            return `há ${minutes} min`;
        if (at.toDateString() === clock.date.toDateString())
            return Qt.formatTime(at, "HH:mm");
        return Qt.formatDate(at, "dd/MM");
    }
}
