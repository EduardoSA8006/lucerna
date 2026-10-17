pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.core.format
import qs.core.theme
import qs.core.widgets
import qs.features.dashboard.state

// Aba Desempenho: CPU, GPU, disco, rede e memória.
Item {
    id: root

    // Só com o painel aberto nesta aba as bolhas se mexem: o painel carrega
    // todas as abas, e o `visible` delas não muda.
    readonly property bool onScreen: DashboardState.isShowing("performance")

    implicitHeight: layout.implicitHeight

    // Um relógio só para as bolhas da CPU e da GPU: mudam para a mesma figura
    // e giram juntas. Roda com a aba na tela; a bolha parada (GPU sem dados)
    // congela, e o relógio segue para a outra.
    BlobMorph {
        id: blobClock

        morphing: root.onScreen
        spinning: root.onScreen
        spinDuration: 30000
    }

    AnimatedNumber {
        id: cpuNumber

        value: PerformanceState.cpuUsage
    }

    // O uso da GPU na tela, quando ela tem uso (com clock, os MHz vão direto).
    AnimatedNumber {
        id: gpuNumber

        value: PerformanceState.gpu?.unit === "%" ? PerformanceState.gpu.fraction : 0
    }

    AnimatedNumber {
        id: diskNumber

        value: PerformanceState.disks[0]?.fraction ?? 0
    }

    AnimatedNumber {
        id: memNumber

        value: PerformanceState.memFraction
    }

    ColumnLayout {
        id: layout

        width: parent.width
        spacing: ThemeManager.spacing.normal

        // CPU e GPU lado a lado, metade cada; sem a GPU, a CPU ocupa a linha.
        RowLayout {
            Layout.fillWidth: true
            spacing: ThemeManager.spacing.normal

            StatCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                icon: Icons.cpu
                title: `CPU - ${PerformanceState.cpuModel}`
                fraction: PerformanceState.cpuUsage
                label: "Uso"
                value: `${Math.round(cpuNumber.shown * 100)}`
                unit: "%"
                hasTemp: PerformanceState.hasTemp
                tempText: PerformanceState.cpuTempText
                tempFraction: PerformanceState.cpuTempFraction
                hot: PerformanceState.cpuHot
                pulse: PerformanceState.cpuUsage
                blobActive: root.onScreen
                blobDriver: blobClock
            }

            // Uma GPU por vez (a dedicada primeiro); o clique passa para a
            // próxima.
            StatCard {
                readonly property var gpu: PerformanceState.gpu

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                visible: PerformanceState.showGpu
                icon: Icons.gpu
                title: `GPU - ${gpu?.name ?? "nenhuma encontrada"}`
                fraction: gpu?.fraction ?? 0
                label: gpu?.label ?? ""
                value: gpu?.unit === "%" ? `${Math.round(gpuNumber.shown * 100)}` : gpu?.value ?? "—"
                unit: gpu?.unit ?? ""
                hasTemp: gpu?.hasTemp ?? false
                tempText: gpu?.tempText ?? ""
                tempFraction: gpu?.tempFraction ?? 0
                hot: gpu?.hot ?? false
                pulse: fraction
                // Parada em repouso ou sem dados (não há o que mostrar).
                blobActive: root.onScreen && (gpu?.hasData ?? false)
                blobDriver: blobClock
                clickable: PerformanceState.gpus.length > 1
                dots: PerformanceState.gpus.length
                dot: PerformanceState.gpuIndex
                onSwapped: PerformanceState.cycleGpu()
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
                                text: Format.percent(diskNumber.shown)
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
                                id: disk

                                required property var modelData

                                width: parent.width

                                Txt {
                                    text: disk.modelData.mount
                                    mono: true
                                    font.pixelSize: ThemeManager.font.small + 1
                                }

                                Txt {
                                    width: parent.width
                                    text: disk.modelData.text
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
                            text: Format.percent(memNumber.shown)
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
