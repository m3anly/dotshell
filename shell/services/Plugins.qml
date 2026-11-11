pragma Singleton

import QtQuick
import Quickshell
import qs.components

Singleton {
    id: root

    readonly property var names: (Quickshell.env("DOTSHELL_PLUGINS") ?? "").split(" ").filter(name => name !== "")
    property var loaded: []
    readonly property var panels: loaded.filter(plugin => plugin.panel !== null)
    readonly property var tiles: loaded.filter(plugin => plugin.tile?.shown ?? false)
    property bool started: false

    onTilesChanged: {
        if (Ui.quickSettingsSub.startsWith("plugin.") && !tiles.some(plugin => plugin.panelName === Ui.quickSettingsSub))
            Ui.quickSettingsSub = "";
    }

    function barItems(section: string): var {
        return loaded.filter(plugin => plugin.bar !== null && plugin.barSection === section);
    }

    function find(name: string): ShellPlugin {
        return loaded.find(plugin => plugin.name === name) ?? null;
    }

    function start(): void {
        if (started)
            return;
        started = true;
        for (const name of names)
            load(name, Qt.createComponent(Qt.resolvedUrl(`../plugins/${name}/Plugin.qml`), Component.Asynchronous));
    }

    function load(name: string, component: Component): void {
        if (component.status === Component.Loading) {
            component.statusChanged.connect(() => load(name, component));
            return;
        }
        if (component.status !== Component.Ready) {
            console.warn(`dotshell: plugin ${name} failed to load: ${component.errorString()}`);
            return;
        }
        const created = component.createObject(root, {
            name
        });
        const plugin = created as ShellPlugin;
        if (plugin === null) {
            console.warn(`dotshell: plugin ${name}: Plugin.qml must have a ShellPlugin root`);
            created?.destroy();
            return;
        }
        loaded = [...loaded, plugin].sort((a, b) => names.indexOf(a.name) - names.indexOf(b.name));
    }
}
