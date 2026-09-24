import QtQuick
import qs.core.config
import qs.core.theme
import qs.core.widgets
import qs.features.settings.state

// Área de transferência: guardar o histórico, quanto, manter ao reiniciar e
// colar direto. O painel abre com Super+V (Configurações → Atalhos).
Column {
    spacing: ThemeManager.spacing.large

    SettingSection {
        title: "Histórico"

        SettingRow {
            icon: "content_paste"
            title: "Guardar o que for copiado"
            description: ClipboardSettings.available ? "Textos e imagens, num painel próprio (Super+V). Senhas marcadas pelos gerenciadores ficam de fora" : "Precisa do wl-clipboard (wl-paste e wl-copy)"
            dimmed: !ClipboardSettings.available

            Switch {
                checked: Config.clipboardEnabled
                onToggled: on => Config.clipboardEnabled = on
            }
        }

        SettingRow {
            wide: true
            icon: "format_list_numbered"
            title: "Quantos guardar"
            description: "Os fixados não contam e nunca saem sozinhos"
            dimmed: !Config.clipboardEnabled

            Select {
                width: parent.width
                options: ClipboardSettings.limitOptions
                value: Config.clipboardLimit
                onSelected: v => Config.clipboardLimit = v
            }
        }

        SettingRow {
            icon: "history"
            title: "Manter ao reiniciar"
            description: "Guarda o histórico no disco. Desligado, some ao sair da sessão"
            dimmed: !Config.clipboardEnabled

            Switch {
                checked: Config.clipboardPersist
                onToggled: on => Config.clipboardPersist = on
            }
        }

        SettingRow {
            icon: "content_paste_go"
            title: "Colar ao escolher"
            description: "Além de copiar, cola na janela em foco (Ctrl+Shift+V nos terminais)"
            dimmed: !Config.clipboardEnabled

            Switch {
                checked: Config.clipboardPaste
                onToggled: on => Config.clipboardPaste = on
            }
        }
    }

    SettingSection {
        title: "Limpar"

        SettingRow {
            icon: "delete_sweep"
            title: `${ClipboardSettings.count} ${ClipboardSettings.count === 1 ? "item" : "itens"}`
            description: ClipboardSettings.pinned ? `${ClipboardSettings.pinned} fixado${ClipboardSettings.pinned === 1 ? "" : "s"}` : "Nenhum fixado"

            Row {
                spacing: ThemeManager.spacing.small

                TonalButton {
                    enabled: ClipboardSettings.count > ClipboardSettings.pinned
                    text: "Menos os fixados"
                    onClicked: ClipboardSettings.clear(false)
                }

                TonalButton {
                    enabled: ClipboardSettings.count > 0
                    icon: Icons.trash
                    text: "Tudo"
                    onClicked: ClipboardSettings.clear(true)
                }
            }
        }
    }
}
