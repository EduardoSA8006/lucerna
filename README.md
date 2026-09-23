# Lucerna

Shell de desktop próprio para o Hyprland, escrito em Quickshell (QML). A proposta completa está em [`Lucerna — Proposta.md`](<Lucerna — Proposta.md>).

## Testando

O shell roda dentro de um Hyprland aninhado, num container Docker com Arch, que abre como uma janela na sessão Wayland do host. O repositório é montado em `~/.config/quickshell/lucerna` dentro do container, então o Quickshell recarrega sozinho quando um arquivo muda.

```sh
dev/run.sh            # constrói a imagem na primeira vez e abre a janela
dev/run.sh --build    # reconstrói a imagem (ex.: para atualizar Hyprland/Quickshell)
dev/run.sh shell      # abre um bash no container em execução
```

Requisitos no host: Docker, uma sessão Wayland e o usuário no grupo `docker`.

Atalhos no Hyprland aninhado (mod = `Alt`):

| Atalho | Ação |
| --- | --- |
| `Alt+Enter` | Abrir o kitty |
| `Alt+Q` | Fechar a janela |
| `Alt+1..4` | Ir para o workspace |
| `Alt+Shift+1..4` | Mover a janela para o workspace |
| `Alt+Shift+R` | Reiniciar o Quickshell |
| `Alt+Shift+E` | Sair do Hyprland |
