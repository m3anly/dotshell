pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.config

Singleton {
    id: root

    readonly property var list: server.trackedNotifications.values.slice().reverse()
    property var popups: []
    property var received: ({})
    property var unreadIds: []
    readonly property int unread: list.filter(notification => unreadIds.includes(notification.id)).length
    property string screen: ""
    readonly property bool doNotDisturb: Store.notifications.doNotDisturb
    readonly property var shownPopups: popups.filter(notification => notification && list.includes(notification)).slice(0, Math.max(1, Config.notifications.maxPopups))

    onListChanged: {
        if (popups.some(notification => !notification || !list.includes(notification)))
            popups = popups.filter(notification => notification && list.includes(notification));
        const ids = new Set(list.map(notification => String(notification.id)));
        if (Object.keys(received).some(id => !ids.has(id))) {
            const kept = {};
            for (const id in received)
                if (ids.has(id))
                    kept[id] = received[id];
            received = kept;
        }
        if (unreadIds.some(id => !ids.has(String(id))))
            unreadIds = unreadIds.filter(id => ids.has(String(id)));
    }

    function toggleDoNotDisturb(): void {
        Store.notifications.doNotDisturb = !Store.notifications.doNotDisturb;
        if (Store.notifications.doNotDisturb)
            popups = popups.filter(notification => notification?.urgency === NotificationUrgency.Critical);
    }

    function receivedAt(notification: var): real {
        return received[notification?.id] ?? 0;
    }

    function age(notification: var, now: int): string {
        const at = receivedAt(notification);
        if (at === 0)
            return "";
        const minutes = Math.floor((now - at / 1000) / 60);
        if (minutes < 1)
            return "now";
        if (minutes < 60)
            return `${minutes} min`;
        const hours = Math.floor(minutes / 60);
        if (hours < 24)
            return `${hours} h`;
        return `${Math.floor(hours / 24)} d`;
    }

    function lead(notification: var): string {
        return Apps.monogram(notification?.appName || notification?.summary || "");
    }

    function dropPopup(notification: var): void {
        popups = popups.filter(other => other !== notification);
        if (notification?.transient)
            notification.expire();
    }

    function dismiss(notification: var): void {
        popups = popups.filter(other => other !== notification);
        notification?.dismiss();
    }

    function clear(): void {
        popups = [];
        list.slice().forEach(notification => notification.dismiss());
        unreadIds = [];
    }

    function activate(notification: var): void {
        const fallback = notification.actions.find(action => action.identifier === "default");
        if (fallback)
            fallback.invoke();
        else
            focusApp(notification);
        if (!notification.resident)
            dismiss(notification);
        Ui.closeAll();
    }

    function invoke(notification: var, action: var): void {
        action.invoke();
        if (!notification.resident)
            dismiss(notification);
    }

    function focusApp(notification: var): void {
        const entry = notification.desktopEntry ? DesktopEntries.heuristicLookup(notification.desktopEntry) : DesktopEntries.heuristicLookup(notification.appName);
        const windowId = entry ? Apps.windowByEntryId[entry.id] : undefined;
        if (windowId !== undefined)
            Niri.focusWindow(windowId);
    }

    function markRead(): void {
        unreadIds = [];
    }

    NotificationServer {
        id: server

        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        actionsSupported: true
        imageSupported: true
        onNotification: notification => {
            notification.tracked = true;
            const received = Object.assign({}, root.received);
            received[notification.id] = Date.now();
            root.received = received;
            const centerOpen = Ui.panel === "notifications";
            if (!centerOpen)
                root.unreadIds = [...root.unreadIds.filter(id => id !== notification.id), notification.id];
            if (centerOpen || (root.doNotDisturb && notification.urgency !== NotificationUrgency.Critical))
                return;
            if (root.shownPopups.length === 0)
                root.screen = Ui.resolveScreen("");
            root.popups = [notification, ...root.popups.filter(other => other !== notification)];
        }
    }
}
