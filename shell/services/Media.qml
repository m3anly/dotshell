pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var players: Mpris.players.values.filter(candidate => !candidate.dbusName.includes("playerctld"))
    property MprisPlayer latched: null
    property MprisPlayer chosen: null
    readonly property MprisPlayer audible: players.find(candidate => candidate.isPlaying) ?? null
    readonly property MprisPlayer player: players.includes(chosen) ? chosen : audible ?? (players.includes(latched) ? latched : players[0] ?? null)
    readonly property bool playing: player?.isPlaying ?? false
    readonly property string title: player?.trackTitle || player?.identity || ""
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string album: player?.trackAlbum ?? ""
    readonly property string artUrl: player?.trackArtUrl ?? ""
    readonly property real length: player?.lengthSupported ? player.length : 0
    readonly property bool shuffle: player?.shuffleSupported ? player.shuffle : false
    readonly property int loopState: player?.loopSupported ? player.loopState : MprisLoopState.None
    property real position: 0

    onAudibleChanged: Qt.callLater(releaseChoice)

    onPlayerChanged: {
        Qt.callLater(latchPlaying);
        syncPosition();
    }
    onPlayingChanged: latchPlaying()

    function latchPlaying(): void {
        if (player?.isPlaying)
            latched = player;
    }

    function syncPosition(): void {
        position = player?.positionSupported ? player.position : 0;
    }

    function playPause(): void {
        if (player?.canTogglePlaying)
            player.togglePlaying();
    }

    function next(): void {
        if (player?.canGoNext)
            player.next();
    }

    function previous(): void {
        if (player?.canGoPrevious)
            player.previous();
    }

    function releaseChoice(): void {
        if (audible !== null && audible !== chosen)
            chosen = null;
    }

    function choose(candidate: MprisPlayer): void {
        chosen = candidate;
        latched = candidate;
    }

    function toggleShuffle(): void {
        if (player?.shuffleSupported)
            player.shuffle = !player.shuffle;
    }

    function cycleLoop(): void {
        if (!player?.loopSupported)
            return;
        if (player.loopState === MprisLoopState.None)
            player.loopState = MprisLoopState.Playlist;
        else if (player.loopState === MprisLoopState.Playlist)
            player.loopState = MprisLoopState.Track;
        else
            player.loopState = MprisLoopState.None;
    }

    function raise(): void {
        if (player?.canRaise)
            player.raise();
    }

    function changeVolume(step: int): void {
        if (player?.volumeSupported)
            player.volume = Math.max(0, Math.min(1, player.volume + step / 100));
    }

    function seekTo(fraction: real): void {
        if (player?.canSeek && length > 0) {
            player.position = Math.max(0, Math.min(1, fraction)) * length;
            syncPosition();
        }
    }

    function formatTime(seconds: real): string {
        const total = Math.max(0, Math.floor(seconds));
        return `${Math.floor(total / 60)}:${String(total % 60).padStart(2, "0")}`;
    }

    Connections {
        target: root.player

        function onPostTrackChanged(): void {
            root.syncPosition();
        }

        function onPositionChanged(): void {
            root.syncPosition();
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.playing
        onTriggered: root.player.positionChanged()
    }
}
