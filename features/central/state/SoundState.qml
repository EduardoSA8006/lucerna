pragma Singleton

import QtQuick
import Quickshell
import qs.core.widgets
import qs.services

// View model da seção Som: saída e entrada.
Singleton {
    id: root

    readonly property bool available: Audio.available
    readonly property real volume: Audio.volume
    readonly property bool muted: Audio.muted
    readonly property string volumeIcon: Audio.muted || Audio.volume === 0 ? Icons.volumeOff : Audio.volume < 0.34 ? Icons.volumeLow : Audio.volume < 0.67 ? Icons.volumeMedium : Icons.volumeHigh
    readonly property real micVolume: Audio.micVolume
    readonly property bool micMuted: Audio.micMuted
    readonly property bool hasMic: Audio.source !== null

    readonly property var outputs: Audio.sinks.map(n => ({ node: n, name: Audio.nodeName(n), current: n === Audio.sink }))
    readonly property var inputs: Audio.sources.map(n => ({ node: n, name: Audio.nodeName(n), current: n === Audio.source }))

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
}
