# Segurança

O Lucerna roda na sessão do usuário e mexe em partes sensíveis: a tela de
bloqueio, a área de transferência, arquivos de configuração e o próprio
Hyprland. Um problema nelas é de segurança, não só um bug.

## Como relatar

Use o **relato privado de vulnerabilidade** do GitHub, em
[Security → Report a vulnerability](https://github.com/EduardoSA8006/lucerna/security/advisories/new).
Não abra issue pública para vulnerabilidade.

Inclua, se puder, os passos para reproduzir, o commit do Lucerna
(`git rev-parse HEAD`) e as versões do Hyprland e do Quickshell
(`hyprctl version`, `qs --version`).

## O que conta como segurança

- **Burlar a tela de bloqueio**: desbloquear sem a senha (PAM), ver o conteúdo
  da sessão com a tela bloqueada ou derrubar o bloqueio.
- **Injeção de comando** nos scripts de `services/scripts/` e nos IPCs:
  argumentos que vêm de fora (nomes de arquivo, títulos de janela, texto
  copiado, nomes de rede ou de dispositivo) virando comando de shell ou código
  Lua.
- **Vazamento do histórico da área de transferência**: senhas marcadas pelos
  gerenciadores indo para o histórico, ou os arquivos do histórico (em
  `statePath`) legíveis por outros usuários.
- **Arquivos que o shell grava e o Hyprland executa**:
  `~/.config/hypr/lucerna-monitors.lua` e o keymap gerado (`keymap.xkb`), se um
  valor vindo de fora puder injetar código neles.

## Versões suportadas

Ainda não há releases: só o `main` recebe correções.
