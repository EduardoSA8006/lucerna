pragma Singleton

import QtQuick
import Quickshell
import qs.core.config
import qs.core.format
import qs.services

// View model da aba Mídia: faixa, controles e letra.
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

    // O espectro em volta da capa (lido do DashboardState, o mesmo do card da
    // aba Painel), ou as ondas sem ele; desligável nas configurações.
    readonly property bool visualizer: Config.audioPulse
    // Anima só com a aba à mostra e tocando.
    readonly property bool live: DashboardState.isShowing("media") && Media.playing

    // Letra
    readonly property bool lyricsEnabled: Config.lyricsEnabled
    readonly property bool offline: Config.offline
    readonly property var lyrics: Lyrics.lines
    readonly property bool lyricsLoading: Lyrics.loading
    readonly property bool lyricsSynced: Lyrics.synced
    readonly property int currentLine: Lyrics.lineAt(Media.position + 0.3)

    // Busca a letra quando a faixa muda e a aba está visível.
    readonly property string trackKey: DashboardState.isShowing("media") && Lyrics.enabled ? `${Media.artist}|${Media.title}` : ""
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
