import QtQuick
import QtMultimedia

// Um vídeo em loop, sem som, decodificado pelo Qt Multimedia (FFmpeg, com
// VA-API quando a GPU tem). Pausado há mais de dois minutos, solta o
// decodificador e a memória dele; a capa, por baixo, fica à mostra.
Item {
    id: root

    property string source
    property bool playing: false
    property int fillMode: Image.PreserveAspectCrop
    // Há um quadro na tela (para a camada aparecer só então).
    readonly property bool showing: released ? false : player.mediaStatus === MediaPlayer.BufferedMedia || player.mediaStatus === MediaPlayer.BufferingMedia || player.mediaStatus === MediaPlayer.EndOfMedia
    property bool released: false

    onPlayingChanged: update()

    function update(): void {
        if (!player.source.toString())
            return;
        if (playing) {
            released = false;
            player.play();
        } else if (player.playbackState === MediaPlayer.PlayingState) {
            player.pause();
        }
    }

    MediaPlayer {
        id: player

        source: root.source ? `file://${root.source}` : ""
        loops: MediaPlayer.Infinite
        videoOutput: output
        onErrorOccurred: (error, message) => console.warn(`Lucerna: papel em vídeo: ${message}`)
        // Troca de arquivo para a reprodução: toca de novo quando o novo carrega.
        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.LoadedMedia)
                root.update();
        }
    }

    VideoOutput {
        id: output

        anchors.fill: parent
        fillMode: root.fillMode === Image.PreserveAspectFit ? VideoOutput.PreserveAspectFit : VideoOutput.PreserveAspectCrop
    }

    Timer {
        interval: 120000
        running: !root.playing && player.playbackState === MediaPlayer.PausedState
        onTriggered: {
            root.released = true;
            player.stop();
        }
    }
}
