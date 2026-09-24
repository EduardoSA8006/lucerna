import QtQuick
import qs.core.config
import qs.core.theme
import qs.core.widgets
import qs.features.settings.state

// Captura de tela: o que acontece com a foto, a gravação e as pastas. O painel
// abre com Print (Configurações → Atalhos).
Column {
    spacing: ThemeManager.spacing.large

    Txt {
        width: parent.width
        visible: !CaptureSettings.canShoot || !CaptureSettings.canRecord
        wrapMode: Text.Wrap
        text: !CaptureSettings.canShoot ? "Para capturar, instale o grim (e o wf-recorder para gravar): sudo pacman -S grim wf-recorder" : "Para gravar a tela, instale o wf-recorder: sudo pacman -S wf-recorder"
        color: ThemeManager.colors.warning
        font.pixelSize: ThemeManager.font.small + 1
    }

    SettingSection {
        title: "Foto"

        SettingRow {
            icon: "content_copy"
            title: "Copiar para a área de transferência"
            description: "Além de salvar o arquivo"

            Switch {
                checked: Config.captureCopy
                onToggled: on => Config.captureCopy = on
            }
        }

        SettingRow {
            icon: "arrow_selector_tool"
            title: "Mostrar o cursor"
            description: "Também dá para trocar no painel de captura"

            Switch {
                checked: Config.captureCursor
                onToggled: on => Config.captureCursor = on
            }
        }

        SettingRow {
            icon: "folder"
            title: "Pasta"
            description: CaptureSettings.shotFolder

            TonalButton {
                text: "Abrir"
                onClicked: CaptureSettings.openFolder(CaptureSettings.shotFolder)
            }
        }
    }

    SettingSection {
        title: "Gravação"
        opacity: CaptureSettings.canRecord ? 1 : 0.55

        SettingRow {
            wide: true
            icon: "speed"
            title: "Quadros por segundo"
            description: CaptureSettings.gpuEncode ? "Codifica pela GPU (VA-API)" : "Codifica pelo processador (x264); 60 fps pesa mais"

            SegmentedControl {
                width: parent.width
                options: CaptureSettings.fpsOptions
                value: Config.captureFps
                onSelected: v => Config.captureFps = v
            }
        }

        SettingRow {
            wide: true
            icon: Icons.volumeUp
            title: "Som"
            description: "Também dá para trocar no painel de captura"

            SegmentedControl {
                width: parent.width
                options: CaptureSettings.audioOptions
                value: Config.captureAudio
                onSelected: v => Config.captureAudio = v
            }
        }

        SettingRow {
            icon: "folder"
            title: "Pasta"
            description: CaptureSettings.recordFolder

            TonalButton {
                text: "Abrir"
                onClicked: CaptureSettings.openFolder(CaptureSettings.recordFolder)
            }
        }
    }
}
