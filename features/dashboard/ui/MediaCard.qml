pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.core.theme
import qs.core.widgets
import qs.features.dashboard.state

// Card de mídia da aba Painel: a capa num círculo, com o espectro em volta
// (barrinhas radiais, uma por faixa de frequência, pelo cava) ou, sem o cava,
// ondas que saem do círculo no ritmo do som; ao lado, o título, o artista e os
// controles. Só anima com a aba à mostra e tocando; pausado, o espectro
// recolhe e a capa para. Sem player: o ícone e "Nada tocando".
Item {
    id: root

    // A aba Painel à mostra.
    required property bool onScreen

    readonly property bool hasMedia: OverviewState.hasMedia
    readonly property bool live: onScreen && OverviewState.mediaPlaying
    // Lado do visualizador: a capa e o espaço das barras em volta.
    readonly property real visualSize: 88
    readonly property real coverSize: 52
    // As barras começam um pouco fora da capa e crescem até a borda.
    readonly property real barStart: coverSize / 2 + 3
    readonly property real barReach: visualSize / 2 - barStart

    // 1 tocando, 0 pausado: o espectro e as ondas sobem e recolhem suave.
    property real gain: live ? 1 : 0

    Behavior on gain { Anim { type: Anim.Standard } }

    Item {
        id: visual

        anchors.verticalCenter: parent.verticalCenter
        width: root.visualSize
        height: root.visualSize

        // O espectro: uma barrinha por faixa, girando em volta da capa.
        Repeater {
            model: root.hasMedia && OverviewState.hasSpectrum ? OverviewState.spectrumBars : 0

            delegate: Item {
                id: bar

                required property int index
                readonly property real level: OverviewState.spectrum[bar.index] ?? 0

                anchors.fill: parent
                rotation: bar.index * 360 / OverviewState.spectrumBars

                Rectangle {
                    x: (root.visualSize - width) / 2
                    y: root.visualSize / 2 - root.barStart - height
                    width: 3
                    // A raiz realça as faixas fracas (o cava entrega quase tudo baixo).
                    height: 2 + root.gain * Math.sqrt(bar.level) * (root.barReach - 2)
                    radius: 1.5
                    color: ThemeManager.colors.accent
                    opacity: 0.85
                }
            }
        }

        // Sem o cava: anéis que saem do círculo, mais fortes com o som mais alto.
        Item {
            id: waves

            property real phase: 0

            anchors.fill: parent
            visible: root.hasMedia && !OverviewState.hasSpectrum

            NumberAnimation on phase {
                running: waves.visible && root.live
                from: 0
                to: 1
                duration: 1800
                loops: Animation.Infinite
            }

            Repeater {
                model: 3

                delegate: Rectangle {
                    id: ring

                    required property int index
                    readonly property real t: (waves.phase + ring.index / 3) % 1

                    anchors.centerIn: parent
                    width: root.coverSize + ring.t * (root.visualSize - root.coverSize)
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.width: 2
                    border.color: ThemeManager.colors.accent
                    opacity: (1 - ring.t) * root.gain * (0.25 + 0.75 * OverviewState.mediaPeak)
                }
            }
        }

        // A capa, girando devagar enquanto toca.
        ClippingRectangle {
            id: cover

            anchors.centerIn: parent
            width: root.coverSize
            height: root.coverSize
            radius: root.coverSize / 2
            color: ThemeManager.colors.raised

            Icon {
                anchors.centerIn: parent
                visible: !root.hasMedia
                icon: Icons.musicOff
                size: 26
                color: ThemeManager.colors.textFaint
            }

            Item {
                id: spinner

                anchors.fill: parent
                visible: root.hasMedia

                NumberAnimation on rotation {
                    running: root.hasMedia
                    paused: running && !root.live
                    from: 0
                    to: 360
                    duration: 24000
                    loops: Animation.Infinite
                }

                Icon {
                    anchors.centerIn: parent
                    visible: art.status !== Image.Ready
                    icon: Icons.album
                    size: 26
                    color: ThemeManager.colors.textFaint
                }

                Image {
                    id: art

                    anchors.fill: parent
                    source: OverviewState.mediaArt
                    sourceSize: Qt.size(104, 104)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }
        }
    }

    Column {
        anchors.left: visual.right
        anchors.leftMargin: ThemeManager.spacing.normal
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Txt {
            width: parent.width
            text: OverviewState.mediaTitle
            font.weight: Font.DemiBold
            muted: !root.hasMedia
        }

        Txt {
            width: parent.width
            visible: text !== ""
            text: OverviewState.mediaArtist
            color: ThemeManager.colors.accent
            font.pixelSize: ThemeManager.font.small + 1
        }

        Row {
            visible: root.hasMedia
            topPadding: ThemeManager.spacing.tiny
            spacing: ThemeManager.spacing.tiny

            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                icon: Icons.previous
                iconSize: 20
                onClicked: OverviewState.previousTrack()
            }

            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 36
                implicitHeight: 36
                radius: 18
                active: true
                icon: OverviewState.mediaPlaying ? Icons.pause : Icons.play
                iconSize: 22
                onClicked: OverviewState.togglePlaying()
            }

            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                icon: Icons.next
                iconSize: 20
                onClicked: OverviewState.nextTrack()
            }
        }
    }
}
