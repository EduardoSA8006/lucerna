pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Servidor de notificações do shell (org.freedesktop.Notifications).
// `list` guarda tudo o que ainda não foi dispensado; `popups` é o que está
// aparecendo na tela agora.
Singleton {
    id: root

    readonly property var list: server.trackedNotifications.values.slice().reverse()
    readonly property int count: list.length
    property var popups: []
    property bool doNotDisturb: false
    property var receivedAt: ({})

    readonly property int defaultTimeout: 5000

    function hidePopup(notification: var): void {
        popups = popups.filter(n => n !== notification);
    }

    function clearPopups(): void {
        popups = [];
    }

    function dismiss(notification: var): void {
        notification.dismiss();
    }

    function clearAll(): void {
        for (const n of server.trackedNotifications.values.slice())
            n.dismiss();
    }

    // Milissegundos que o popup fica na tela; 0 = até o usuário fechar.
    function timeoutFor(notification: var): int {
        if (notification.urgency === NotificationUrgency.Critical)
            return 0;
        return notification.expireTimeout > 0 ? notification.expireTimeout : defaultTimeout;
    }

    function timeOf(notification: var): var {
        return receivedAt[notification.id] ?? new Date();
    }

    NotificationServer {
        id: server

        keepOnReload: true
        persistenceSupported: true
        actionsSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        imageSupported: true

        onNotification: notification => {
            notification.tracked = true;
            root.receivedAt[notification.id] = new Date();
            notification.closed.connect(() => root.hidePopup(notification));
            if (!root.doNotDisturb || notification.urgency === NotificationUrgency.Critical)
                root.popups = [notification, ...root.popups.filter(n => n.id !== notification.id)];
        }
    }
}
