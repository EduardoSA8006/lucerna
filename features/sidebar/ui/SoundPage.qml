import QtQuick
import qs.core.theme
import qs.core.widgets
import qs.features.sidebar.state

// Som: volume e dispositivo de saída; microfone e dispositivo de entrada.
Column {
    spacing: ThemeManager.spacing.large

    SectionHeader {
        title: "Som"
        subtitle: SoundState.available ? `Volume ${Math.round(SoundState.volume * 100)}%${SoundState.muted ? " · mudo" : ""}` : "Sem saída de áudio"
    }

    EmptyState {
        visible: !SoundState.available
        icon: Icons.volumeOff
        text: "Nenhum dispositivo de áudio encontrado"
    }

    SettingSection {
        visible: SoundState.available
        title: "Saída"

        SettingRow {
            wide: true
            title: "Volume"

            Row {
                width: parent.width
                spacing: ThemeManager.spacing.normal

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: SoundState.volumeIcon
                    active: SoundState.muted
                    onClicked: SoundState.toggleMute()
                }

                Slider {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 40 - parent.spacing
                    value: SoundState.volume
                    onMoved: v => SoundState.setVolume(v)
                }
            }
        }

        Repeater {
            model: SoundState.outputs

            delegate: ListRow {
                required property var modelData

                width: parent.width
                icon: Icons.speaker
                title: modelData.name
                detail: modelData.current ? "Em uso" : ""
                lit: modelData.current
                onClicked: SoundState.selectOutput(modelData)
            }
        }
    }

    SettingSection {
        visible: SoundState.hasMic
        title: "Entrada"

        SettingRow {
            wide: true
            title: "Microfone"

            Row {
                width: parent.width
                spacing: ThemeManager.spacing.normal

                IconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: SoundState.micMuted ? Icons.micOff : Icons.mic
                    active: SoundState.micMuted
                    onClicked: SoundState.toggleMicMute()
                }

                Slider {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 40 - parent.spacing
                    value: SoundState.micVolume
                    onMoved: v => SoundState.setMicVolume(v)
                }
            }
        }

        Repeater {
            model: SoundState.inputs

            delegate: ListRow {
                required property var modelData

                width: parent.width
                icon: Icons.mic
                title: modelData.name
                detail: modelData.current ? "Em uso" : ""
                lit: modelData.current
                onClicked: SoundState.selectInput(modelData)
            }
        }
    }
}
