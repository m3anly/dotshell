import QtQuick
import Quickshell.Networking
import qs.components
import qs.services
import qs.theme

ListRow {
    id: root

    required property var modelData
    property bool askPassword: false
    property bool wrongPassword: false
    property bool sentPassword: false
    property bool freshProfile: false
    property bool failed: false
    property var passwordOwner: null
    readonly property int percent: Math.round((modelData?.signalStrength ?? 0) * 100)
    readonly property bool takesPassword: [WifiSecurityType.WpaPsk, WifiSecurityType.Wpa2Psk, WifiSecurityType.Sae].includes(modelData?.security)
    readonly property int minimumPassword: modelData?.security === WifiSecurityType.Sae ? 1 : 8
    readonly property bool passwordReady: password.text.length >= minimumPassword

    signal passwordOpened

    function submit(): void {
        if (!passwordReady)
            return;
        freshProfile = !modelData.known;
        sentPassword = true;
        wrongPassword = false;
        failed = false;
        modelData.connectWithPsk(password.text);
        askPassword = false;
    }

    function cancel(): void {
        askPassword = false;
        wrongPassword = false;
    }

    width: parent?.width ?? 0
    onAskPasswordChanged: {
        if (askPassword)
            passwordOpened();
    }
    onPasswordOwnerChanged: {
        if (askPassword && passwordOwner !== modelData)
            cancel();
    }
    current: modelData?.connected ?? false
    name: modelData?.name ?? ""
    busy: modelData?.stateChanging ?? false
    showExtra: askPassword
    statusColor: askPassword && wrongPassword ? Theme.red : current ? Theme.fg : Theme.fg2
    status: {
        if (!modelData)
            return "";
        if (modelData.state === ConnectionState.Connecting)
            return "Connecting";
        if (modelData.state === ConnectionState.Disconnecting)
            return "Disconnecting";
        if (askPassword)
            return wrongPassword ? "Wrong password" : "Enter the password";
        if (failed)
            return "Failed";
        if (modelData.connected)
            return `Connected · ${percent}%`;
        if (modelData.known)
            return `Saved · ${percent}%`;
        return `${modelData.security === WifiSecurityType.Open ? "Open" : "Secured"} · ${percent}%`;
    }
    onClicked: {
        if (modelData.connected || modelData.stateChanging)
            return;
        if (askPassword) {
            password.forceActiveFocus();
            return;
        }
        failed = false;
        if (takesPassword && !modelData.known) {
            askPassword = true;
            return;
        }
        sentPassword = false;
        modelData.connect();
    }

    lead: SignalBars {
        bars: Radios.signalBars(root.modelData?.signalStrength ?? 0)
    }

    extra: Column {
        width: parent?.width ?? 0
        spacing: 8

        Rectangle {
            width: parent.width
            height: 36
            radius: 12
            color: Theme.fill
            border.width: 1
            border.color: root.wrongPassword ? Theme.red : password.activeFocus ? Theme.fg2 : Theme.line

            Behavior on border.color {
                EffectsColor {}
            }

            TextInput {
                id: password

                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                passwordCharacter: "●"
                font.letterSpacing: 3
                font.family: Theme.uiFont
                font.pixelSize: 13
                color: Theme.fg
                selectionColor: Theme.fg2
                clip: true
                onVisibleChanged: {
                    if (visible)
                        forceActiveFocus();
                    else
                        text = "";
                }
                onAccepted: root.submit()
                Keys.onEscapePressed: event => {
                    root.cancel();
                    event.accepted = true;
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: password.text === ""
                    text: "Password"
                    color: Theme.fg3
                    font.capitalization: Font.MixedCase
                }
            }
        }

        Row {
            anchors.right: parent.right
            spacing: 6

            PillButton {
                text: "Cancel"
                onClicked: root.cancel()
            }

            PillButton {
                text: "Connect"
                primary: true
                enabled: root.passwordReady
                onClicked: root.submit()
            }
        }
    }

    component PillButton: MorphButton {
        id: pill

        property string text
        property bool primary: false

        implicitWidth: pillLabel.implicitWidth + 28
        implicitHeight: 30
        restRadius: 15
        pressRadius: 6
        pressScale: 0.92
        opacity: enabled ? 1 : 0.4
        restColor: primary ? Theme.fg : "transparent"
        hoverColor: primary ? Theme.fg : Theme.hover
        outline: primary ? "transparent" : Theme.line

        Behavior on opacity {
            Effects {}
        }

        Label {
            id: pillLabel

            anchors.centerIn: parent
            text: pill.text
            color: pill.primary ? Theme.glassBase : Theme.fg
        }
    }

    Connections {
        target: root.modelData

        function onConnectedChanged(): void {
            if (!root.modelData.connected)
                return;
            root.sentPassword = false;
            root.freshProfile = false;
            root.wrongPassword = false;
            root.failed = false;
        }

        function onConnectionFailed(reason: int): void {
            const rejected = root.sentPassword;
            root.sentPassword = false;
            if (reason !== ConnectionFailReason.NoSecrets && !(rejected && root.takesPassword)) {
                root.failed = true;
                failedReset.restart();
                return;
            }
            if (root.freshProfile)
                root.modelData.forget();
            root.freshProfile = false;
            root.wrongPassword = rejected;
            root.askPassword = true;
        }
    }

    Timer {
        id: failedReset

        interval: 4000
        onTriggered: root.failed = false
    }
}
