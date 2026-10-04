pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.config

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool sinkSilent: !sink?.audio || sink.audio.muted || sink.audio.volume <= 0
    readonly property bool sourceSilent: !source?.audio || source.audio.muted || source.audio.volume <= 0

    readonly property string volumeSound: Quickshell.env("DOTSHELL_VOLUME_SOUND") ?? ""
    readonly property var sinks: devices(true)
    readonly property var sources: devices(false)

    function devices(output: bool): var {
        return (Pipewire.nodes?.values ?? []).filter(node => node.audio && !node.isStream && node.isSink === output && !(node.name ?? "").endsWith(".monitor")).sort((a, b) => label(a).localeCompare(label(b)));
    }

    function label(node: PwNode): string {
        return node?.description || node?.nickname || node?.name || "No device";
    }

    function bus(node: PwNode): string {
        const name = String(node?.name ?? "");
        const props = node?.properties ?? {};
        if (name.startsWith("bluez_") || props["device.bus"] === "bluetooth" || props["api.bluez5.address"])
            return "Bluetooth";
        if (/hdmi|displayport/i.test(name) || /hdmi|displayport/i.test(props["device.profile.name"] ?? ""))
            return "HDMI";
        if (props["device.bus"] === "usb" || /usb/i.test(name))
            return "USB";
        if (name.startsWith("alsa_"))
            return "Built-in";
        return "Virtual";
    }

    function glyph(node: PwNode): string {
        const formFactor = (node?.properties ?? {})["device.form-factor"] ?? "";
        if (formFactor === "headphone" || formFactor === "headset")
            return "phones";
        if (bus(node) === "Bluetooth")
            return node.isSink ? "buds" : "mic";
        return node?.isSink ? "vol" : "mic";
    }

    function setDefault(node: PwNode): void {
        if (node.isSink)
            Pipewire.preferredDefaultAudioSink = node;
        else
            Pipewire.preferredDefaultAudioSource = node;
    }

    function percentOf(node: PwNode): int {
        return node?.audio ? Math.round(node.audio.volume * 100) : 0;
    }

    function setPercent(node: PwNode, percent: real): void {
        if (!node?.audio)
            return;
        node.audio.volume = Math.max(0, Math.min(100, percent)) / 100;
        if (percent > 0 && node.audio.muted)
            node.audio.muted = false;
    }

    function changeVolume(step: int): void {
        setPercent(sink, percentOf(sink) + step);
        volumeFeedback();
    }

    function volumeFeedback(): void {
        if (!Config.sounds.volumeChange || volumeSound === "" || sinkSilent)
            return;
        if (feedback.running)
            feedback.replay = true;
        else
            feedback.running = true;
    }

    function toggleMute(node: PwNode): void {
        if (node?.audio)
            node.audio.muted = !node.audio.muted;
    }

    Process {
        id: feedback

        property bool replay: false

        command: ["pw-play", root.volumeSound]
        onExited: {
            if (!replay)
                return;
            replay = false;
            running = true;
        }
    }

    PwObjectTracker {
        objects: [root.sink, root.source]
    }
}
