pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Polkit
import qs.config

Singleton {
    id: root

    readonly property AuthFlow flow: (loader.item as PolkitAgent)?.flow ?? null
    readonly property bool registered: (loader.item as PolkitAgent)?.isRegistered ?? false
    readonly property bool active: flow !== null && !flow.isCompleted
    readonly property bool canSwitchIdentity: active && flow.identities.length > 1
    property string screen: ""
    property string message: ""
    property string actionId: ""
    property string identityName: ""
    property int failures: 0
    property bool checking: false

    signal started
    signal failed

    function submit(value: string): void {
        if (!active || checking || !flow.isResponseRequired)
            return;
        checking = true;
        flow.submit(value);
    }

    function cancel(): void {
        if (active)
            flow.cancelAuthenticationRequest();
    }

    function selectNextIdentity(): void {
        if (!canSwitchIdentity)
            return;
        const index = flow.identities.indexOf(flow.selectedIdentity);
        failures = 0;
        checking = false;
        flow.selectedIdentity = flow.identities[(index + 1) % flow.identities.length];
    }

    function describe(identity: var): string {
        if (!identity)
            return "";
        const name = identity.displayName || identity.string || String(identity.id);
        return identity.isGroup ? `${name} (group)` : name;
    }

    function begin(): void {
        if (!flow)
            return;
        Ui.closeAll();
        screen = Ui.resolveScreen("");
        message = flow.message;
        actionId = flow.actionId;
        identityName = describe(flow.selectedIdentity);
        failures = 0;
        checking = false;
        started();
    }

    LazyLoader {
        id: loader

        active: Config.polkitAgent

        PolkitAgent {
            onAuthenticationRequestStarted: root.begin()
        }
    }

    Connections {
        target: root.flow

        function onAuthenticationFailed(): void {
            root.checking = false;
            root.failures += 1;
            root.failed();
        }

        function onIsResponseRequiredChanged(): void {
            if (root.flow.isResponseRequired)
                root.checking = false;
        }

        function onSelectedIdentityChanged(): void {
            root.identityName = root.describe(root.flow.selectedIdentity);
        }
    }
}
