pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// Players de mídia via MPRIS (Spotify, navegadores, mpv...). O ativo é o
// escolhido pelo usuário, senão o que está tocando, senão o primeiro.
Singleton {
    id: root

    readonly property var players: Mpris.players.values
    property var chosen: null
    readonly property MprisPlayer active: (chosen && players.includes(chosen)) ? chosen : players.find(p => p.isPlaying) ?? players[0] ?? null
    readonly property bool available: active !== null

    readonly property string title: active?.trackTitle || ""
    readonly property string artist: active?.trackArtist || ""
    readonly property string album: active?.trackAlbum || ""
    readonly property string artUrl: active?.trackArtUrl || ""
    readonly property string identity: active?.identity || ""
    readonly property bool playing: active?.isPlaying ?? false
    readonly property real length: active?.lengthSupported ? active.length : 0
    readonly property real position: active?.positionSupported ? active.position : 0

    // Liga a atualização da posição (o MPRIS não avisa; é preciso pedir).
    property bool trackPosition: false

    function select(player: var): void {
        chosen = player;
    }

    function togglePlaying(): void {
        if (active?.canTogglePlaying)
            active.togglePlaying();
    }

    function next(): void {
        if (active?.canGoNext)
            active.next();
    }

    function previous(): void {
        if (active?.canGoPrevious)
            active.previous();
    }

    function seek(fraction: real): void {
        if (active?.canSeek && length > 0)
            active.position = Math.max(0, Math.min(1, fraction)) * length;
    }

    Timer {
        running: root.trackPosition && root.playing
        repeat: true
        interval: 500
        onTriggered: root.active?.positionChanged()
    }
}
