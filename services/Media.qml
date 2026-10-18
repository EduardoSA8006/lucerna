pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// Players de mídia via MPRIS (Spotify, navegadores, mpv...). O ativo é o
// escolhido pelo usuário, senão o que está tocando, senão o primeiro.
Singleton {
    id: root

    // Tipado como ObjectModel: pelo tipo do Mpris.players, o qmllint 6.12 não acha o `values`.
    // Interna: existe só para o tipo que o qmllint pede; os consumidores usam a lista abaixo.
    readonly property ObjectModel playerModel: Mpris.players
    readonly property var players: playerModel.values
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

    // O player depois de `current` na lista, dando a volta; null sem players.
    function nextPlayer(list: var, current: var): var {
        if (!list || list.length === 0)
            return null;
        return list[(list.indexOf(current) + 1) % list.length];
    }

    // Passa para o próximo player.
    function cycle(): void {
        if (players.length > 1)
            select(nextPlayer(players, active));
    }

    // O álbum só quando acrescenta algo: diferente do título e não contido
    // nele (o single "Música" do álbum "Música", "Música - Ao vivo").
    function albumShown(album: string, title: string): string {
        const a = String(album ?? "").trim();
        const t = String(title ?? "").trim().toLowerCase();
        return a && !t.includes(a.toLowerCase()) ? a : "";
    }

    readonly property bool canSeek: (active?.canSeek ?? false) && length > 0

    // Vai para o tempo, em segundos (a linha da letra clicada).
    function seekTo(seconds: real): void {
        if (canSeek)
            active.position = Math.max(0, Math.min(length, seconds));
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
