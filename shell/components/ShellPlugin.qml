import QtQuick
import Quickshell
import qs.config
import qs.services

Scope {
    id: root

    property string name
    property var defaults: ({})
    property Component bar: null
    property string barSection: "right"
    property bool barShown: true
    property point barShift: Qt.point(0, 0)
    property real barOpacity: 1
    property real barLineOpacity: 1
    property var hiddenBarBlocks: []
    property Component panel: null
    property string panelAnchor: "right"
    property QuickSettingsTile tile: null
    readonly property bool tileExpandable: tile !== null && tile.shown && tile.content !== null
    readonly property bool ready: settings.ready
    readonly property string panelName: `plugin.${name}`
    readonly property string directory: `${Config.directory}/plugins/${name}`
    readonly property string shellDirectory: `${Quickshell.shellDir}/plugins/${name}`

    function value(key: string): var {
        return settings.value(key);
    }

    function set(key: string, item: var): void {
        settings.set(key, item);
    }

    function reset(key: string): void {
        settings.reset(key);
    }

    function isPinned(key: string): bool {
        return settings.isPinned(key);
    }

    function panelOpen(screenName: string): bool {
        if (panel !== null)
            return Ui.panel === panelName && Ui.screen === screenName;
        if (tile !== null)
            return Ui.panel === "quickSettings" && Ui.screen === screenName && (!tileExpandable || Ui.quickSettingsSub === panelName);
        return false;
    }

    function togglePanel(screenName: string): void {
        if (panel !== null)
            Ui.togglePanel(panelName, screenName);
        else if (tileExpandable)
            Ui.toggleQuickSettings(panelName, screenName);
        else if (tile !== null)
            Ui.togglePanel("quickSettings", screenName);
    }

    SettingsFile {
        id: settings

        directory: root.directory
        defaults: root.defaults
    }
}
