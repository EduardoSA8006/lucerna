pragma ComponentBehavior: Bound

import QtQuick
import qs.core.theme
import qs.core.widgets
import qs.features.central.state

// Som da central: saída e entrada (o ícone silencia; a setinha troca o card
// pela lista de dispositivos, com voltar) e, embaixo, um volume por app com
// áudio aberto. Sem streams, o segundo cartão some; sem áudio nenhum, o
// painel some.
CentralPanel {
    id: root

    // A coluna da esquerda divide a tela com a energia: passando daqui, rola.
    property real maxHeight: 600

    present: SoundState.any
    height: Math.min(column.implicitHeight + padding * 2, maxHeight)

    Flickable {
        width: parent.width
        height: parent.height
        contentHeight: column.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Column {
            id: column

            width: root.width - root.padding * 2
            spacing: ThemeManager.spacing.small

            Group {
                visible: SoundState.available || SoundState.hasMic

                Loader {
                    id: card

                    width: parent.width
                    sourceComponent: CentralState.soundPage === "outputs" ? outputs : CentralState.soundPage === "inputs" ? inputs : levels
                    onLoaded: pageIn.restart()

                    transform: Translate {
                        id: cardOffset
                    }

                    // A lista entra pela direita; a volta, pela esquerda.
                    ParallelAnimation {
                        id: pageIn

                        Anim { target: card; property: "opacity"; from: 0; to: 1; type: Anim.Effects }
                        Anim { target: cardOffset; property: "x"; from: CentralState.soundPage ? 16 : -16; to: 0; type: Anim.Spatial }
                    }
                }
            }

            Group {
                visible: SoundState.streams.length > 0

                // Uma linha por índice: a lista refeita com o mesmo tamanho não
                // recria as linhas, e o arrasto do volume não se perde. O
                // volume e o mudo vêm do nó.
                Repeater {
                    model: SoundState.streams.length

                    delegate: LevelRow {
                        id: app

                        required property int index
                        readonly property var stream: SoundState.streams[app.index] ?? null

                        icon: Icons.sound
                        image: app.stream?.image ?? ""
                        // O nome só na falta do ícone do app (a reserva).
                        label: app.stream?.image ? "" : app.stream?.name ?? ""
                        value: app.stream?.node?.audio?.volume ?? 0
                        muted: app.stream?.node?.audio?.muted ?? false
                        iconClickable: true
                        onMoved: v => SoundState.setStreamVolume(app.stream, v)
                        onIconClicked: SoundState.toggleStreamMute(app.stream)
                    }
                }
            }
        }
    }

    Component {
        id: levels

        Column {
            DeviceLevel {
                visible: SoundState.available
                icon: SoundState.volumeIcon
                name: SoundState.outputName
                value: SoundState.volume
                muted: SoundState.muted
                onMoved: v => SoundState.setVolume(v)
                onMuteClicked: SoundState.toggleMute()
                onListClicked: CentralState.setSoundPage("outputs")
            }

            DeviceLevel {
                visible: SoundState.hasMic
                icon: SoundState.micIcon
                name: SoundState.inputName
                value: SoundState.micVolume
                muted: SoundState.micMuted
                onMoved: v => SoundState.setMicVolume(v)
                onMuteClicked: SoundState.toggleMicMute()
                onListClicked: CentralState.setSoundPage("inputs")
            }
        }
    }

    Component {
        id: outputs

        Column {
            spacing: 2

            PageHeader {
                title: "Saída"
                onBack: CentralState.setSoundPage("")
            }

            Repeater {
                model: SoundState.outputs

                delegate: ListRow {
                    id: output

                    required property var modelData

                    icon: Icons.speaker
                    title: output.modelData.name
                    lit: output.modelData.current
                    onClicked: SoundState.selectOutput(output.modelData)
                }
            }
        }
    }

    Component {
        id: inputs

        Column {
            spacing: 2

            PageHeader {
                title: "Entrada"
                onBack: CentralState.setSoundPage("")
            }

            Repeater {
                model: SoundState.inputs

                delegate: ListRow {
                    id: input

                    required property var modelData

                    icon: Icons.mic
                    title: input.modelData.name
                    lit: input.modelData.current
                    onClicked: SoundState.selectInput(input.modelData)
                }
            }
        }
    }
}
