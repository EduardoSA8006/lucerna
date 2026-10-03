pragma Singleton

import QtQuick
import Quickshell
import qs.core.widgets
import qs.services

// View model do som da central (o slider de volume, os tiles de saída e de
// microfone e as páginas deles): saída e entrada (o dispositivo, o volume, o
// mudo e a lista para trocar) e o volume de cada app com áudio aberto.
Singleton {
    id: root

    readonly property bool available: Audio.available
    readonly property real volume: Audio.volume
    readonly property bool muted: Audio.muted
    readonly property string volumeIcon: Audio.muted || Audio.volume === 0 ? Icons.volumeOff : Audio.volume < 0.34 ? Icons.volumeLow : Audio.volume < 0.67 ? Icons.volumeMedium : Icons.volumeHigh
    readonly property string outputName: Audio.deviceName
    readonly property real micVolume: Audio.micVolume
    readonly property bool micMuted: Audio.micMuted
    readonly property bool hasMic: Audio.source !== null
    readonly property string micIcon: Audio.micMuted ? Icons.micOff : Icons.mic
    readonly property string inputName: Audio.nodeName(Audio.source)

    readonly property var outputs: Audio.sinks.map(n => ({ node: n, name: Audio.nodeName(n), current: n === Audio.sink }))
    readonly property var inputs: Audio.sources.map(n => ({ node: n, name: Audio.nodeName(n), current: n === Audio.source }))

    // Um por app com áudio aberto: { node, name, icon, image }; `image`
    // é o ícone do app no tema de ícones ("" se não houver). Sem nome, vale
    // o de reserva.
    readonly property var streams: AudioStreams.list.map(s => Object.assign({ image: s.icon ? Quickshell.iconPath(s.icon, true) : "" }, s, { name: s.name || "Aplicativo" }))

    function setVolume(v: real): void {
        Audio.setVolume(v);
    }

    function toggleMute(): void {
        Audio.toggleMute();
    }

    function setMicVolume(v: real): void {
        Audio.setMicVolume(v);
    }

    function toggleMicMute(): void {
        Audio.toggleMicMute();
    }

    function selectOutput(item: var): void {
        Audio.setDefaultSink(item.node);
    }

    function selectInput(item: var): void {
        Audio.setDefaultSource(item.node);
    }

    function setStreamVolume(item: var, v: real): void {
        AudioStreams.setVolume(item.node, v);
    }

    function toggleStreamMute(item: var): void {
        AudioStreams.toggleMute(item.node);
    }
}
