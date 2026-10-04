pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs.services
import qs.theme

Scope {
    id: root

    property bool capturing: false
    property bool unlocking: false
    property bool busy: false
    property string password: ""
    property int failures: 0

    function captureList(): var {
        const list = [];
        for (let i = 0; i < captures.instances.length; i++)
            list.push(captures.instances[i]);
        return list;
    }

    function begin(): void {
        if (lock.locked || capturing)
            return;
        password = "";
        failures = 0;
        unlocking = false;
        capturing = true;
        captureLimit.restart();
        Qt.callLater(checkCaptures);
    }

    function checkCaptures(): void {
        if (capturing && captureList().every(capture => capture.hasContent))
            engage();
    }

    function engage(): void {
        if (!capturing)
            return;
        captureLimit.stop();
        lock.locked = true;
        capturing = false;
        if (!lock.locked)
            Lock.release();
    }

    function type(text: string): void {
        if (!busy && !unlocking)
            password += text;
    }

    function erase(): void {
        if (!busy && !unlocking)
            password = password.slice(0, -1);
    }

    function clear(): void {
        if (!busy && !unlocking)
            password = "";
    }

    function submit(): void {
        if (busy || unlocking)
            return;
        busy = true;
        if (!pam.start())
            busy = false;
    }

    function finish(): void {
        unlocking = true;
        password = "";
        release.interval = Motion.reduced ? 0 : 320;
        release.restart();
    }

    Connections {
        target: Lock

        function onRequestedChanged(): void {
            if (Lock.requested)
                root.begin();
        }
    }

    Timer {
        id: captureLimit

        interval: 400
        onTriggered: root.engage()
    }

    Timer {
        id: release

        onTriggered: lock.locked = false
    }

    Variants {
        id: captures

        model: Quickshell.screens

        ScreencopyView {
            required property ShellScreen modelData

            visible: false
            captureSource: root.capturing || lock.locked ? modelData : null
            onHasContentChanged: root.checkCaptures()
        }
    }

    PamContext {
        id: pam

        config: "password"
        configDirectory: "pam"
        onPamMessage: {
            if (responseRequired)
                respond(root.password);
        }
        onCompleted: result => {
            root.busy = false;
            if (result === PamResult.Success) {
                root.finish();
                return;
            }
            root.password = "";
            root.failures += 1;
        }
    }

    WlSessionLock {
        id: lock

        onLockStateChanged: {
            Lock.locked = locked;
            if (locked)
                return;
            Lock.release();
            root.unlocking = false;
            root.capturing = false;
            root.busy = false;
            root.password = "";
        }

        LockSurface {
            id: surface

            controller: root
            capture: root.captureList().find(capture => capture.modelData.name === surface.screen?.name) ?? null
        }
    }
}
