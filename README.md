# Lucerna

Shell de desktop próprio para o Hyprland, escrito em Quickshell (QML). A proposta completa, com princípios e arquitetura, está em [`Lucerna — Proposta.md`](<Lucerna — Proposta.md>). Os wallpapers animados, ainda por implementar, estão em [`Lucerna — Proposta do Wallpaper.md`](<Lucerna — Proposta do Wallpaper.md>).

Tem barra, painel superior (visão geral, mídia com letra sincronizada, desempenho e clima), launcher, notificações com central lateral, tela de bloqueio, wallpaper, seletor de temas, OSD de volume e brilho e menu de energia. Os ícones são Material Symbols e as animações usam as curvas de movimento do Material 3. Tudo sai de um tema em JSON (`themes/`), trocável ao vivo, e o tema também ajusta as bordas do Hyprland.

## Requisitos

- Hyprland 0.56+ com configuração em Lua (`hyprland.lua`)
- Quickshell 0.3.1+
- Fonte de ícones: `ttf-material-symbols-variable` (repositório oficial)
- Opcionais: PipeWire (volume), UPower (bateria), NetworkManager (rede), `brightnessctl` (brilho), `nvidia-smi` (uso da GPU NVIDIA; vem com o driver)
- Serviços na internet, só enquanto a aba correspondente está aberta: [Open-Meteo](https://open-meteo.com) (clima) e [LRCLIB](https://lrclib.net) (letras)

## Instalação

```sh
ln -s "$PWD" ~/.config/quickshell/lucerna
```

No `hyprland.lua`:

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("qs -c lucerna")
end)

local ipc = "qs -c lucerna ipc call "
hl.bind("SUPER + Space",  hl.dsp.exec_cmd(ipc .. "panels toggle launcher"))
hl.bind("SUPER + D",      hl.dsp.exec_cmd(ipc .. "panels toggle dashboard"))
hl.bind("SUPER + N",      hl.dsp.exec_cmd(ipc .. "panels toggle notifications"))
hl.bind("SUPER + T",      hl.dsp.exec_cmd(ipc .. "panels toggle themes"))
hl.bind("SUPER + Escape", hl.dsp.exec_cmd(ipc .. "panels toggle power"))
hl.bind("SUPER + L",      hl.dsp.exec_cmd(ipc .. "session lock"))
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(ipc .. "brightness up"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(ipc .. "brightness down"), { locked = true, repeating = true })
```

O volume é controlado por `wpctl` direto nos atalhos; o shell percebe a mudança pelo PipeWire e mostra o OSD. `dev/hyprland.lua` tem um exemplo completo.

## Comandos IPC

| Alvo | Funções |
| --- | --- |
| `panels` | `open <nome>`, `close`, `toggle <nome>`, `get` (nomes: `launcher`, `dashboard`, `notifications`, `themes`, `power`) |
| `dashboard` | `open <aba>` (`overview`, `media`, `performance`, `weather`), `toggle` |
| `session` | `lock`, `isLocked` |
| `theme` | `set <id>`, `get`, `list` |
| `brightness` | `up`, `down`, `set <0-100>` |
| `notifications` | `clear`, `toggleDnd`, `count` |

## Temas

Cada arquivo em `themes/*.json` é um tema; o nome do arquivo é o id. Para criar um, copie `themes/lamparina.json`, mude as cores e o wallpaper, e ele aparece no seletor na hora. As preferências (tema ativo, não perturbe) ficam em `~/.local/state/quickshell/by-shell/<id>/config.json`.

## Testando sem Hyprland

O shell roda num Hyprland aninhado, num container Docker com Arch, que abre como uma janela na sessão Wayland do host. O repositório é montado em `~/.config/quickshell/lucerna` dentro do container, então o Quickshell recarrega sozinho quando um arquivo muda.

```sh
dev/run.sh            # constrói a imagem na primeira vez e abre a janela
dev/run.sh --build    # reconstrói a imagem (ex.: depois de mudar o Dockerfile)
dev/run.sh shell      # abre um bash no container em execução
dev/run.sh log        # segue o log do Quickshell
```

Requisitos no host: Docker, uma sessão Wayland e o usuário no grupo `docker`.

- Volume, bateria e rede mostram o estado real do host (o PipeWire e o D-Bus do sistema são repassados).
- Com `LUCERNA_DEV=1`, definido pelo `run.sh`, suspender, reiniciar e desligar são só simulados: sem isso, o comando chegaria ao host pelo D-Bus.
- O brilho é só leitura no container; os ajustes são simulados.
- A senha da tela de bloqueio no container é `lucerna` (usuário `dev`).
- O fuso horário vem do host (`/etc/localtime`). A rede na aba Desempenho é a do container, não a do host.
- Para testar a aba Mídia, a imagem tem `mpv` com `mpv-mpris`: `dev/run.sh shell` e `mpv --no-video arquivo.mp3`.

Atalhos no Hyprland aninhado (mod = `Alt`, para não brigar com o KDE):

| Atalho | Ação |
| --- | --- |
| `Alt+Space` | Launcher |
| `Alt+D` | Painel superior (também clicando no relógio); dentro dele, `Tab`/`Shift+Tab` ou `1`–`4` trocam de aba |
| `Alt+N` | Central de notificações |
| `Alt+T` | Seletor de temas |
| `Alt+Esc` | Menu de energia |
| `Alt+L` | Bloquear a tela |
| `Alt+↑` / `Alt+↓` / `Alt+M` | Volume / mudo |
| `Alt+→` / `Alt+←` | Brilho |
| `Alt+Enter` | Abrir o kitty |
| `Alt+Q` | Fechar a janela |
| `Alt+1..5` / `Alt+Shift+1..5` | Ir para o workspace / mover a janela |
| `Alt+Shift+R` | Reiniciar o Quickshell |
| `Alt+Shift+E` | Sair do Hyprland |
