pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.theme

Singleton {
    id: root

    readonly property int bands: 32
    readonly property bool wanted: Ui.panel === "dashboard" && Ui.dashboardTab === "media" && Media.playing && !Motion.reduced && !GameMode.muteVisualizer
    property var levels: []
    readonly property string config: ["[general]", "framerate=60", `bars=${bands}`, "autosens=1", "lower_cutoff_freq=40", "higher_cutoff_freq=14000", "[input]", "method=pipewire", "source=auto", "[output]", "method=raw", "raw_target=/dev/stdout", "data_format=ascii", "ascii_max_range=1000", "bar_delimiter=59", "frame_delimiter=10", "channels=mono", "mono_option=average", "[smoothing]", "noise_reduction=55", ""].join("\n")

    onWantedChanged: {
        if (!wanted)
            levels = [];
    }

    Process {
        running: root.wanted
        command: ["bash", "-c", "exec cava -p <(printf '%s' \"$1\")", "bash", root.config]
        stdout: SplitParser {
            onRead: line => {
                const parts = line.split(";");
                const next = [];
                for (let i = 0; i < root.bands; i++)
                    next.push(Math.min(1, (Number(parts[i]) || 0) / 1000));
                root.levels = next;
            }
        }
    }
}
