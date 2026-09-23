import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.core.theme
import qs.core.widgets
import qs.features.dashboard.state

// Aba Mídia: capa com o pulso do áudio, controles, progresso e letra sincronizada.
Item {
    id: root

    implicitHeight: 300

    // Sem player
    Column {
        anchors.centerIn: parent
        visible: !MediaState.available
        spacing: ThemeManager.spacing.small

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            icon: Icons.musicOff
            size: 48
            color: ThemeManager.colors.textFaint
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Nada tocando"
            font.pixelSize: ThemeManager.font.large
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Abra um player com suporte a MPRIS (Spotify, navegador, mpv…)"
            faint: true
            font.pixelSize: ThemeManager.font.small
        }
    }

    RowLayout {
        anchors.fill: parent
        visible: MediaState.available
        spacing: ThemeManager.spacing.large

        // Capa: a forma atrás pulsa com o áudio e gira enquanto toca.
        Item {
            Layout.preferredWidth: 280
            Layout.fillHeight: true

            Blob {
                anchors.centerIn: parent
                width: 272
                height: 272
                lobes: 9
                amplitude: 0.045
                pulse: MediaState.pulse
                color: ThemeManager.alpha(ThemeManager.colors.accent, 0.16)
                spinning: MediaState.playing
                spinDuration: 20000
            }

            ClippingRectangle {
                anchors.centerIn: parent
                width: 196
                height: 196
                radius: ThemeManager.radius.large
                color: ThemeManager.colors.raised

                Icon {
                    anchors.centerIn: parent
                    visible: cover.status !== Image.Ready
                    icon: Icons.album
                    size: 72
                    color: ThemeManager.colors.textFaint
                }

                Image {
                    id: cover

                    anchors.fill: parent
                    source: MediaState.art
                    sourceSize: Qt.size(392, 392)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }
        }

        // Faixa e controles
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: ThemeManager.spacing.small

            Txt {
                text: MediaState.player
                faint: true
                font.pixelSize: ThemeManager.font.small
            }

            Txt {
                Layout.fillWidth: true
                text: MediaState.title
                font.pixelSize: ThemeManager.font.large + 6
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
                maximumLineCount: 2
            }

            Txt {
                Layout.fillWidth: true
                visible: text !== ""
                text: MediaState.artist
                color: ThemeManager.colors.accent
            }

            Txt {
                Layout.fillWidth: true
                visible: text !== ""
                text: MediaState.album
                muted: true
                font.pixelSize: ThemeManager.font.small + 1
            }

            // Progresso: clicar ou arrastar pula para o ponto.
            Item {
                Layout.fillWidth: true
                Layout.topMargin: ThemeManager.spacing.normal
                Layout.preferredHeight: 20

                LinearGauge {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 6
                    value: MediaState.progress
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPressed: event => MediaState.seek(event.x / width)
                    onPositionChanged: event => {
                        if (pressed)
                            MediaState.seek(event.x / width);
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Txt {
                    text: MediaState.positionText
                    mono: true
                    faint: true
                    font.pixelSize: ThemeManager.font.small
                }

                Item {
                    Layout.fillWidth: true
                }

                Txt {
                    text: MediaState.lengthText
                    mono: true
                    faint: true
                    font.pixelSize: ThemeManager.font.small
                }
            }

            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: ThemeManager.spacing.normal

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: Icons.previous
                    iconSize: 28
                    onClicked: MediaState.previous()
                }

                Clickable {
                    width: 60
                    height: 60
                    radius: MediaState.playing ? ThemeManager.radius.large : 30
                    active: true
                    onClicked: MediaState.togglePlaying()

                    Behavior on radius { Anim { type: Anim.FastSpatial } }

                    Icon {
                        anchors.centerIn: parent
                        icon: MediaState.playing ? Icons.pause : Icons.play
                        filled: true
                        size: 32
                        color: ThemeManager.colors.accentText
                    }
                }

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: Icons.next
                    iconSize: 28
                    onClicked: MediaState.next()
                }
            }

            // Escolha do player, quando há mais de um.
            Flow {
                Layout.fillWidth: true
                visible: MediaState.players.length > 1
                spacing: ThemeManager.spacing.tiny

                Repeater {
                    model: MediaState.players

                    delegate: Clickable {
                        required property var modelData

                        implicitWidth: chip.implicitWidth + ThemeManager.spacing.normal * 2
                        implicitHeight: 26
                        radius: 13
                        active: modelData.active
                        onClicked: MediaState.select(modelData.player)

                        Txt {
                            id: chip

                            anchors.centerIn: parent
                            text: modelData.name
                            color: parent.active ? ThemeManager.colors.accentText : ThemeManager.colors.text
                            font.pixelSize: ThemeManager.font.small
                        }
                    }
                }
            }
        }

        // Letra
        Surface {
            Layout.preferredWidth: 300
            Layout.fillHeight: true
            clip: true

            CardHeader {
                id: lyricsHeader

                x: ThemeManager.spacing.normal + 2
                y: ThemeManager.spacing.normal + 2
                icon: Icons.lyrics
                text: "Letra"
            }

            Txt {
                anchors.centerIn: parent
                visible: MediaState.lyrics.length === 0
                width: parent.width - ThemeManager.spacing.large * 2
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: MediaState.lyricsLoading ? "Procurando a letra…" : "Sem letra para esta faixa"
                faint: true
            }

            ListView {
                id: lyricsView

                anchors {
                    top: lyricsHeader.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: ThemeManager.spacing.normal
                }
                clip: true
                spacing: ThemeManager.spacing.small
                model: MediaState.lyrics
                currentIndex: MediaState.currentLine
                interactive: !MediaState.lyricsSynced
                highlightRangeMode: MediaState.lyricsSynced ? ListView.StrictlyEnforceRange : ListView.NoHighlightRange
                preferredHighlightBegin: height / 2 - 16
                preferredHighlightEnd: height / 2 + 16
                highlightMoveDuration: ThemeManager.anim.normal
                boundsBehavior: Flickable.StopAtBounds

                delegate: Txt {
                    required property var modelData
                    required property int index
                    readonly property bool current: index === MediaState.currentLine

                    width: ListView.view.width
                    text: modelData.text || "♪"
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    color: current ? ThemeManager.colors.accent : MediaState.lyricsSynced ? ThemeManager.colors.textFaint : ThemeManager.colors.textMuted
                    font.pixelSize: current ? ThemeManager.font.large : ThemeManager.font.normal
                    font.weight: current ? Font.DemiBold : Font.Normal

                    Behavior on color { ColorAnim {} }
                }
            }
        }
    }
}
