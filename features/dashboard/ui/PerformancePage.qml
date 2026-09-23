import QtQuick
import QtQuick.Layouts
import qs.core.format
import qs.core.theme
import qs.core.widgets
import qs.features.dashboard.state

// Aba Desempenho: CPU, GPU, disco, rede e memória.
Item {
    id: root

    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        width: parent.width
        spacing: ThemeManager.spacing.normal

        RowLayout {
            Layout.fillWidth: true
            spacing: ThemeManager.spacing.normal

            // CPU: modelo, temperatura, histórico e o uso numa forma orgânica.
            Surface {
                Layout.fillWidth: true
                Layout.preferredHeight: 156
                clip: true

                Sparkline {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 70
                    values: PerformanceState.cpuHistory
                    maxValue: 1
                    color: ThemeManager.alpha(ThemeManager.colors.accent, 0.5)
                }

                Column {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: ThemeManager.spacing.normal + 2
                    spacing: ThemeManager.spacing.small

                    Row {
                        spacing: ThemeManager.spacing.normal

                        CircularGauge {
                            width: 44
                            height: 44
                            thickness: 4
                            value: PerformanceState.cpuUsage

                            Icon {
                                anchors.centerIn: parent
                                icon: Icons.cpu
                                size: 18
                                color: ThemeManager.colors.accent
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter

                            Txt {
                                text: "CPU"
                                color: ThemeManager.colors.accent
                                font.pixelSize: ThemeManager.font.large
                                font.weight: Font.DemiBold
                            }

                            Txt {
                                text: [PerformanceState.cpuModel, PerformanceState.cpuThreads].filter(x => x).join(" · ")
                                muted: true
                                font.pixelSize: ThemeManager.font.small + 1
                            }
                        }
                    }

                    Row {
                        spacing: ThemeManager.spacing.small

                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            icon: Icons.temperature
                            size: 18
                            color: PerformanceState.cpuHot ? ThemeManager.colors.danger : ThemeManager.colors.textMuted
                        }

                        Txt {
                            anchors.verticalCenter: parent.verticalCenter
                            text: PerformanceState.cpuTempText
                            mono: true
                        }
                    }

                    LinearGauge {
                        width: 220
                        value: PerformanceState.cpuTempFraction
                        color: PerformanceState.cpuHot ? ThemeManager.colors.danger : ThemeManager.colors.accent
                    }
                }

                Column {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: ThemeManager.spacing.large
                    spacing: 2

                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Uso"
                        muted: true
                        font.pixelSize: ThemeManager.font.small + 1
                    }

                    Item {
                        width: 96
                        height: 96

                        Blob {
                            anchors.fill: parent
                            lobes: 7
                            amplitude: 0.05
                            pulse: PerformanceState.cpuUsage
                            color: ThemeManager.colors.track
                            spinning: true
                            spinDuration: 30000
                        }

                        Txt {
                            anchors.centerIn: parent
                            text: PerformanceState.cpuUsageText
                            mono: true
                            color: ThemeManager.colors.accent
                            font.pixelSize: ThemeManager.font.large + 6
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }

            // GPUs
            Surface {
                Layout.preferredWidth: 300
                Layout.preferredHeight: 156

                Column {
                    anchors.fill: parent
                    anchors.margins: ThemeManager.spacing.normal + 2
                    spacing: ThemeManager.spacing.normal

                    CardHeader {
                        icon: Icons.gpu
                        text: "GPU"
                    }

                    Txt {
                        visible: PerformanceState.gpus.length === 0
                        text: "Nenhuma GPU encontrada"
                        faint: true
                    }

                    Repeater {
                        model: PerformanceState.gpus.slice(0, 2)

                        delegate: Column {
                            required property var modelData

                            width: parent.width
                            spacing: 4

                            Row {
                                width: parent.width

                                Txt {
                                    width: parent.width - value.width
                                    text: parent.parent.modelData.name
                                    font.pixelSize: ThemeManager.font.small + 1
                                }

                                Txt {
                                    id: value

                                    text: parent.parent.modelData.valueText
                                    mono: true
                                    faint: parent.parent.modelData.asleep
                                    font.pixelSize: ThemeManager.font.small + 1
                                }
                            }

                            LinearGauge {
                                width: parent.width
                                value: modelData.fraction
                                opacity: modelData.asleep ? 0.4 : 1
                            }

                            Txt {
                                width: parent.width
                                visible: text !== ""
                                text: modelData.detail
                                faint: true
                                font.pixelSize: ThemeManager.font.small
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: ThemeManager.spacing.normal

            // Disco
            Surface {
                Layout.preferredWidth: 290
                Layout.preferredHeight: 190

                Row {
                    anchors.fill: parent
                    anchors.margins: ThemeManager.spacing.normal + 2
                    spacing: ThemeManager.spacing.normal

                    CircularGauge {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 124
                        height: 124
                        thickness: 9
                        value: PerformanceState.disks[0]?.fraction ?? 0

                        Column {
                            anchors.centerIn: parent

                            Icon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                icon: Icons.storage
                                size: 18
                                color: ThemeManager.colors.textMuted
                            }

                            Txt {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Format.percent(PerformanceState.disks[0]?.fraction ?? 0)
                                mono: true
                                font.pixelSize: ThemeManager.font.large + 6
                                font.weight: Font.DemiBold
                            }

                            Txt {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "usado"
                                muted: true
                                font.pixelSize: ThemeManager.font.small
                            }
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 124 - parent.spacing
                        spacing: ThemeManager.spacing.small

                        Txt {
                            text: "Disco"
                            font.pixelSize: ThemeManager.font.large
                            font.weight: Font.DemiBold
                        }

                        Repeater {
                            model: PerformanceState.disks

                            delegate: Column {
                                required property var modelData

                                width: parent.width

                                Txt {
                                    text: modelData.mount
                                    mono: true
                                    font.pixelSize: ThemeManager.font.small + 1
                                }

                                Txt {
                                    width: parent.width
                                    text: modelData.text
                                    muted: true
                                    font.pixelSize: ThemeManager.font.small
                                }
                            }
                        }
                    }
                }
            }

            // Rede
            Surface {
                Layout.fillWidth: true
                Layout.preferredHeight: 190
                clip: true

                CardHeader {
                    id: netHeader

                    x: ThemeManager.spacing.normal + 2
                    y: ThemeManager.spacing.normal + 2
                    icon: Icons.network
                    text: "Rede"
                }

                Sparkline {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: netHeader.bottom
                    anchors.bottom: rates.top
                    anchors.margins: ThemeManager.spacing.small
                    values: PerformanceState.rxHistory
                    maxValue: PerformanceState.netScale
                }

                Sparkline {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: netHeader.bottom
                    anchors.bottom: rates.top
                    anchors.margins: ThemeManager.spacing.small
                    values: PerformanceState.txHistory
                    maxValue: PerformanceState.netScale
                    color: ThemeManager.colors.textMuted
                }

                Column {
                    id: rates

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: ThemeManager.spacing.normal + 2
                    spacing: 4

                    Repeater {
                        model: [
                            { icon: Icons.download, label: "Download", value: PerformanceState.download, accent: true },
                            { icon: Icons.upload, label: "Upload", value: PerformanceState.upload, accent: false }
                        ]

                        delegate: Row {
                            required property var modelData

                            width: parent.width
                            spacing: ThemeManager.spacing.small

                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                icon: parent.modelData.icon
                                size: 16
                                color: parent.modelData.accent ? ThemeManager.colors.accent : ThemeManager.colors.textMuted
                            }

                            Txt {
                                width: parent.width - 16 - rateText.width - parent.spacing * 2
                                text: parent.modelData.label
                                muted: true
                                font.pixelSize: ThemeManager.font.small + 1
                            }

                            Txt {
                                id: rateText

                                text: parent.modelData.value
                                mono: true
                                color: parent.modelData.accent ? ThemeManager.colors.accent : ThemeManager.colors.text
                                font.pixelSize: ThemeManager.font.small + 1
                            }
                        }
                    }

                    Txt {
                        width: parent.width
                        horizontalAlignment: Text.AlignRight
                        text: PerformanceState.totals
                        faint: true
                        mono: true
                        font.pixelSize: ThemeManager.font.small
                    }
                }
            }

            // Memória
            Surface {
                Layout.preferredWidth: 230
                Layout.preferredHeight: 190

                Column {
                    anchors.centerIn: parent
                    spacing: ThemeManager.spacing.small

                    CardHeader {
                        anchors.horizontalCenter: parent.horizontalCenter
                        icon: Icons.memory
                        text: "Memória"
                    }

                    CircularGauge {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 104
                        height: 104
                        thickness: 8
                        value: PerformanceState.memFraction

                        Txt {
                            anchors.centerIn: parent
                            text: Format.percent(PerformanceState.memFraction)
                            mono: true
                            font.pixelSize: ThemeManager.font.large + 4
                            font.weight: Font.DemiBold
                        }
                    }

                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: PerformanceState.memText
                        muted: true
                        font.pixelSize: ThemeManager.font.small
                    }
                }
            }
        }
    }
}
