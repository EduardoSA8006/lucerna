pragma Singleton

import QtQuick
import Quickshell
import qs.core.format
import qs.services

// View model da aba Mídia: faixa, controles, letra e pulso do áudio.
Singleton {
    id: root

    readonly property bool available: Media.available
    readonly property string title: Media.title || "Sem título"
    readonly property string artist: Media.artist
    readonly property string album: Media.album
    readonly property string art: Media.artUrl
    readonly property string player: Media.identity
    readonly property bool playing: Media.playing
    readonly property real progress: Media.length > 0 ? Media.position / Media.length : 0
    readonly property string positionText: Format.clock(Media.position)
    readonly property string lengthText: Format.clock(Media.length)
    readonly property var players: Media.players.map(p => ({ player: p, name: p.identity, active: p === Media.active }))

    readonly property real pulse: Math.min(1, Audio.peak * 1.6)

    // Letra
    readonly property var lyrics: Lyrics.lines
    readonly property bool lyricsLoading: Lyrics.loading
    readonly property bool lyricsSynced: Lyrics.synced
    readonly property int currentLine: Lyrics.lineAt(Media.position + 0.3)

    // Busca a letra quando a faixa muda e a aba está visível.
    readonly property string trackKey: DashboardState.isShowing("media") ? `${Media.artist}|${Media.title}` : ""
    onTrackKeyChanged: {
        if (trackKey)
            Lyrics.request(Media.title, Media.artist, Media.album, Media.length);
    }

    function togglePlaying(): void {
        Media.togglePlaying();
    }

    function next(): void {
        Media.next();
    }

    function previous(): void {
        Media.previous();
    }

    function seek(fraction: real): void {
        Media.seek(fraction);
    }

    function select(player: var): void {
        Media.select(player);
    }
}
