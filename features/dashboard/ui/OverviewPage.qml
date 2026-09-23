import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.core.format
import qs.core.theme
import qs.core.widgets
import qs.features.dashboard.state

// Aba Painel: usuário, relógio e clima, calendário, recursos e mídia.
Item {
    id: root

    implicitHeight: layout.implicitHeight

    RowLayout {
        id: layout

        width: parent.width
        spacing: ThemeManager.spacing.normal

        // Coluna 1: usuário + relógio
        ColumnLayout {
            Layout.preferredWidth: 270
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignTop
            spacing: ThemeManager.spacing.normal

            Surface {
                Layout.fillWidth: true
                Layout.preferredHeight: 92

                Row {
                    anchors.fill: parent
                    anchors.margins: ThemeManager.spacing.normal
                    spacing: ThemeManager.spacing.normal

                    Item {
                        width: 64
                        height: 64
                        anchors.verticalCenter: parent.verticalCenter

                        Blob {
                            anchors.fill: parent
                            lobes: 9
                            amplitude: 0.07
                            color: ThemeManager.alpha(ThemeManager.colors.accent, 0.22)
                            spinning: true
                        }

                        Icon {
                            anchors.centerIn: parent
                            visible: face.status !== Image.Ready
                            icon: Icons.person
                            filled: true
                            size: 30
                            color: ThemeManager.colors.accent
                        }

                        ClippingRectangle {
                            anchors.centerIn: parent
                            width: 52
                            height: 52
                            radius: 26
                            color: "transparent"
                            visible: face.status === Image.Ready

                            Image {
                                id: face

                                anchors.fill: parent
                                source: OverviewState.face
                                sourceSize: Qt.size(104, 104)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: false
                            }
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Txt {
                            text: OverviewState.user
                            font.pixelSize: ThemeManager.font.large
                            font.weight: Font.DemiBold
                        }

                        Txt {
                            text: OverviewState.hostname
                            muted: true
                            font.pixelSize: ThemeManager.font.small
                        }

                        Row {
                            spacing: 4
                            visible: OverviewState.uptime !== ""

                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                icon: Icons.uptime
                                size: 14
                                color: ThemeManager.colors.textFaint
                            }

                            Txt {
                                text: OverviewState.uptime
                                faint: true
                                font.pixelSize: ThemeManager.font.small
                            }
                        }
                    }
                }
            }

            Surface {
                Layout.fillWidth: true
                Layout.preferredHeight: 196

                Column {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: ThemeManager.spacing.large - 4
                    spacing: 0

                    Txt {
                        text: OverviewState.time
                        mono: true
                        font.pixelSize: ThemeManager.font.huge + 12
                        font.weight: Font.Medium
                    }

                    Txt {
                        text: `${OverviewState.weekday}, ${OverviewState.date}`
                        muted: true
                    }
                }

                Row {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.margins: ThemeManager.spacing.large - 4
                    spacing: ThemeManager.spacing.small

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: OverviewState.weatherIcon
                        filled: true
                        size: 30
                        color: ThemeManager.colors.accent
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter

                        Txt {
                            text: OverviewState.hasWeather ? `${OverviewState.weatherTemp}  ${OverviewState.weatherText}` : OverviewState.weatherText
                            font.weight: OverviewState.hasWeather ? Font.DemiBold : Font.Normal
                            muted: !OverviewState.hasWeather
                            font.pixelSize: OverviewState.hasWeather ? ThemeManager.font.normal : ThemeManager.font.small
                        }

                        Txt {
                            visible: text !== ""
                            text: OverviewState.weatherPlace
                            faint: true
                            font.pixelSize: ThemeManager.font.small
                        }
                    }
                }
            }
        }

        // Coluna 2: calendário
        Surface {
            Layout.preferredWidth: 300
            Layout.fillHeight: true

            Calendar {
                anchors.fill: parent
                anchors.margins: ThemeManager.spacing.normal
            }
        }

        // Coluna 3: recursos + mídia
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: ThemeManager.spacing.normal

            Surface {
                Layout.fillWidth: true
                Layout.preferredHeight: 150

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: ThemeManager.spacing.normal + 2
                    spacing: ThemeManager.spacing.normal + 4

                    Repeater {
                        model: [
                            { icon: Icons.cpu, label: "CPU", value: OverviewState.cpu },
                            { icon: Icons.memory, label: "Memória", value: OverviewState.memory },
                            { icon: Icons.storage, label: "Disco", value: OverviewState.disk }
                        ]

                        delegate: Row {
                            required property var modelData

                            width: parent.width
                            spacing: ThemeManager.spacing.small

                            AnimatedNumber {
                                id: number

                                value: modelData.value
                            }

                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                icon: parent.modelData.icon
                                size: 18
                                color: ThemeManager.colors.accent
                            }

                            Txt {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 64
                                text: parent.modelData.label
                                muted: true
                                font.pixelSize: ThemeManager.font.small + 1
                            }

                            LinearGauge {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 18 - 64 - 44 - parent.spacing * 3
                                value: parent.modelData.value
                            }

                            Txt {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 44
                                horizontalAlignment: Text.AlignRight
                                text: Format.percent(number.shown)
                                mono: true
                                font.pixelSize: ThemeManager.font.small + 1
                            }
                        }
                    }
                }
            }

            Surface {
                Layout.fillWidth: true
                Layout.preferredHeight: 138

                Row {
                    anchors.fill: parent
                    anchors.margins: ThemeManager.spacing.normal
                    spacing: ThemeManager.spacing.normal

                    ClippingRectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 88
                        height: 88
                        radius: ThemeManager.radius.normal
                        color: ThemeManager.colors.raised

                        Icon {
                            anchors.centerIn: parent
                            visible: art.status !== Image.Ready
                            icon: OverviewState.hasMedia ? Icons.album : Icons.musicOff
                            size: 36
                            color: ThemeManager.colors.textFaint
                        }

                        Image {
                            id: art

                            anchors.fill: parent
                            source: OverviewState.mediaArt
                            sourceSize: Qt.size(176, 176)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 88 - 48 - parent.spacing * 2
                        spacing: 2

                        Txt {
                            width: parent.width
                            text: OverviewState.mediaTitle
                            font.weight: Font.DemiBold
                            muted: !OverviewState.hasMedia
                        }

                        Txt {
                            width: parent.width
                            visible: text !== ""
                            text: OverviewState.mediaArtist
                            color: ThemeManager.colors.accent
                            font.pixelSize: ThemeManager.font.small + 1
                        }
                    }

                    Clickable {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: OverviewState.hasMedia
                        width: 48
                        height: 48
                        radius: 24
                        active: true
                        onClicked: OverviewState.togglePlaying()

                        Icon {
                            anchors.centerIn: parent
                            icon: OverviewState.mediaPlaying ? Icons.pause : Icons.play
                            filled: true
                            color: ThemeManager.colors.accentText
                        }
                    }
                }
            }
        }
    }
}
