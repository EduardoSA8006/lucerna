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

    implicitHeight: layout.visibleChildren.length ? layout.implicitHeight : 120

    Txt {
        anchors.centerIn: parent
        visible: !layout.visibleChildren.length
        text: "Todos os cartões estão escondidos (Configurações → Painel superior)"
        faint: true
    }

    RowLayout {
        id: layout

        width: parent.width
        spacing: ThemeManager.spacing.normal

        // Coluna 1: usuário + relógio (e clima)
        ColumnLayout {
            Layout.preferredWidth: 270
            Layout.fillWidth: !calendarCard.visible && !column3.visible
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop
            visible: OverviewState.shows("user") || OverviewState.shows("clock") || OverviewState.shows("weather")
            spacing: ThemeManager.spacing.normal

            Surface {
                Layout.fillWidth: true
                Layout.preferredHeight: 92
                visible: OverviewState.shows("user")

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

                // Configurações e energia, que saíram da barra.
                Column {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: ThemeManager.spacing.small
                    spacing: 2

                    IconButton {
                        icon: Icons.settings
                        iconSize: 18
                        onClicked: OverviewState.openSettings()
                    }

                    IconButton {
                        icon: Icons.power
                        iconSize: 18
                        foreground: ThemeManager.colors.danger
                        onClicked: OverviewState.openPower()
                    }
                }
            }

            Surface {
                Layout.fillWidth: true
                Layout.preferredHeight: 196
                Layout.fillHeight: true
                visible: OverviewState.shows("clock") || OverviewState.shows("weather")

                Column {
                    visible: OverviewState.shows("clock")
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
                    visible: OverviewState.shows("weather")
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
            id: calendarCard

            Layout.preferredWidth: 300
            Layout.preferredHeight: 300
            Layout.fillHeight: true
            Layout.fillWidth: !column3.visible
            visible: OverviewState.shows("calendar")

            Calendar {
                anchors.fill: parent
                anchors.margins: ThemeManager.spacing.normal
            }
        }

        // Coluna 3: recursos + mídia
        ColumnLayout {
            id: column3

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop
            visible: OverviewState.shows("resources") || OverviewState.shows("media")
            spacing: ThemeManager.spacing.normal

            Surface {
                Layout.fillWidth: true
                Layout.preferredHeight: 150
                Layout.fillHeight: !OverviewState.shows("media")
                visible: OverviewState.shows("resources")

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
                Layout.fillHeight: true
                visible: OverviewState.shows("media")

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
