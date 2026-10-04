pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property string panel: ""
    property string screen: ""
    property bool powerExpanded: false
    property bool launcherOpen: false
    property string launcherMode: "search"
    property bool cheatsheetOpen: false
    property bool settingsOpen: false
    property string settingsSection: "appearance"
    readonly property var dashboardTabs: ["media", "calendar", "weather"]
    property string dashboardTab: "media"
    property int dashboardDirection: 1
    readonly property var systemTabs: ["monitor", "shell"]
    property string systemTab: "monitor"
    property int systemDirection: 1
    property var trayMenu: null

    function resolveScreen(screenName: string): string {
        return screenName || Niri.focusedWorkspace?.output || Quickshell.screens[0]?.name || "";
    }

    function togglePanel(name: string, screenName: string): void {
        const target = resolveScreen(screenName);
        trayMenu = null;
        launcherOpen = false;
        cheatsheetOpen = false;
        powerExpanded = false;
        if (panel === name && screen === target) {
            panel = "";
            return;
        }
        screen = target;
        panel = name;
    }

    function toggleDashboard(tab: string, screenName: string): void {
        const target = resolveScreen(screenName);
        const next = dashboardTabs.includes(tab) ? tab : dashboardTab;
        if (panel === "dashboard" && screen === target && dashboardTab === next) {
            panel = "";
            return;
        }
        openDashboard(next, target);
    }

    function openDashboard(tab: string, screenName: string): void {
        trayMenu = null;
        launcherOpen = false;
        cheatsheetOpen = false;
        powerExpanded = false;
        setTab("dashboard", tab);
        screen = resolveScreen(screenName);
        panel = "dashboard";
    }

    function setTab(group: string, tab: string): void {
        const tabs = root[`${group}Tabs`];
        const from = tabs.indexOf(root[`${group}Tab`]);
        const to = tabs.indexOf(tab);
        if (to < 0 || to === from)
            return;
        root[`${group}Direction`] = to > from ? 1 : -1;
        root[`${group}Tab`] = tab;
    }

    function stepTab(group: string, step: int): void {
        const tabs = root[`${group}Tabs`];
        const index = tabs.indexOf(root[`${group}Tab`]);
        setTab(group, tabs[(index + step + tabs.length) % tabs.length]);
    }

    function openPowerMenu(): void {
        trayMenu = null;
        launcherOpen = false;
        cheatsheetOpen = false;
        screen = resolveScreen("");
        panel = "quickSettings";
        powerExpanded = true;
    }

    function closeAll(): void {
        trayMenu = null;
        panel = "";
        powerExpanded = false;
        launcherOpen = false;
        cheatsheetOpen = false;
    }

    function openLauncher(mode: string): void {
        trayMenu = null;
        panel = "";
        powerExpanded = false;
        cheatsheetOpen = false;
        if (launcherOpen && launcherMode === mode) {
            launcherOpen = false;
            return;
        }
        if (!launcherOpen)
            screen = resolveScreen("");
        launcherMode = mode;
        launcherOpen = true;
    }

    function toggleCheatsheet(): void {
        trayMenu = null;
        panel = "";
        powerExpanded = false;
        launcherOpen = false;
        if (cheatsheetOpen) {
            cheatsheetOpen = false;
            return;
        }
        screen = resolveScreen("");
        cheatsheetOpen = true;
    }

    function toggleSettings(): void {
        if (settingsOpen) {
            settingsOpen = false;
            return;
        }
        openSettings("");
    }

    function openSettings(section: string): void {
        closeAll();
        if (section !== "")
            settingsSection = section;
        settingsOpen = true;
    }

    function setLauncherMode(mode: string): void {
        launcherMode = mode;
    }
}
