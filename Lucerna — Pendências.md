# Lucerna — Pendências

O que falta fazer, na ordem em que vamos seguir. Cada item vira um PR; ao terminar, ele é marcado aqui.

## Em ordem

1. [x] **Proposta atualizada.** A tabela "Escopo" de `Lucerna — Proposta.md` ainda diz que barra, painel e energia estão por fazer e descreve o launcher como só "abrir aplicativos". Faltam monitores, mouse, teclado, papel de parede animado e vídeo.
2. [x] **Launcher: o que hoje só o estilo completo tem.** Fixar nos favoritos e ocultar um app (por clique direito ou atalho) no compacto e na tela cheia. Busca em arquivos e na web também fora do estilo completo (por prefixo ou atalho).
3. [x] **Ociosidade e tela.** Desligar a tela e bloquear depois de X minutos, suspender depois de Y, sem depender do `hypridle` (o Quickshell tem `IdleMonitor`). Com exceções: mídia tocando, app em tela cheia e, no modo apresentação, não apagar.
4. [x] **Luz noturna.** Temperatura de cor por horário (fixo ou pôr e nascer do sol), nos tiles da central e nas configurações.
5. [x] **Temas claros.** Catppuccin Latte e Rosé Pine Dawn, as versões claras oficiais.
6. [x] **Atalhos editáveis.** A página Atalhos das configurações só informa; os atalhos do shell continuam no `hyprland.lua`. Passar a editar ali, reaproveitando os binds da aba Teclado.
7. [x] **Monitores no login.** O arranjo salvo só vale quando o Lucerna inicia, e no login o `hyprland.lua` aparece antes. Opção de gravar o arranjo num arquivo que o `hyprland.lua` inclui.
8. [x] **Histórico da área de transferência**, num painel próprio (`Super+V`).
9. [x] **Captura de tela e gravação:** área, janela ou tela, com notificação e atalho.
10. [x] **Visão geral dos workspaces**, com as janelas em miniatura.
11. [x] **Brilho de monitores externos** por DDC/CI.
12. [x] **Central.** Dois painéis flutuantes na direita, no lugar da barra lateral: ações (tiles com uma página por recurso, inclusive o volume de cada app, e os sliders de volume e brilho) e notificações.
13. [ ] **Dock**, com spec próprio.
14. [ ] **Instalação e distribuição:** script de instalação (link, trecho do `hyprland.lua`, atalhos padrão) e pacote no AUR. A verificação no CI já está feita: quatro checks obrigatórios (`ci/`, `dev/ci.sh`).
15. [ ] **Plugins próprios**, na ordem de `Lucerna — Plugins Próprios.md`: `lucerna-sysinfo`, depois `lucerna-spectrum`, depois os demais.

## Depois

- [ ] Aurora, Brasas, Chama e Vaga-lumes somam luz ao fundo e, num tema claro, estouram para branco. Adaptá-los como o Ondas (que já tem versão clara). Os efeitos próprios dos temas claros (Ondas e Névoa) estão bons.
- [ ] Sliders das configurações gravam o `Config` a cada movimento (GlassPage, NightLightPage, IdlePage, MousePage, KeyboardPage, PowerPage e NotificationsPage). Com `blockWrites` não há perda nem corrupção, e a gravação mediu 1,4 ms em NVMe, mas em disco lento o arrasto pode engasgar. Correção prevista: debounce de uns 200 ms, com o reload suspenso durante a espera e um flush ao sair.
- [ ] Fumaça com o Hyprland de verdade, quando houver runner com GPU: hoje ela roda no `sway` headless, e o que depende do Hyprland (workspaces, visão geral com janelas, `hyprctl`) não é exercitado.
- [ ] `CHANGELOG`, junto com as releases.
- [ ] Central, Wi-Fi: o `WifiState.networks` refaz a lista inteira a cada mudança, então as linhas são recriadas e a senha que estava sendo digitada se perde quando a lista de redes se atualiza. Manter as linhas pela rede (ou guardar a senha fora do delegate).
- [ ] Central, bateria: a sonda do power-profiles-daemon (`busctl`) roda só na partida do shell. Se o daemon subir depois, os botões de perfil (e o tile "Energia" de um desktop) não aparecem até reiniciar o shell. Repetir a sonda (ao abrir a central ou ao mudar o `PowerProfiles`).
- [ ] Central, saída de áudio: o volume por app mostra qualquer app com áudio aberto, inclusive pausado, porque o `PwNode` do Quickshell 0.3 não diz se o stream está tocando. Filtrar quando houver esse estado.
- [ ] Central, saída de áudio (aceito): sem saída padrão, o volume por app não aparece, porque a página da Saída some junto com o tile.
- [ ] Central, sliders (aceito): a roda do mouse sobre um slider largo (volume, brilho, microfone) muda o valor em vez de rolar a página.
- [ ] Central, saída de áudio (aceito; conferir com o mouse): ao trocar para um sink Bluetooth recém-conectado, a página da Saída pode voltar ao estado inicial se o sink demorar a ficar pronto (o recurso "some" por um instante).

## Verificar com hardware e entrada reais

No ambiente de teste não dá para simular cliques, e o Hyprland ignora teclado virtual. Estes pontos foram testados só pela lógica (IPC e capturas) e precisam de uma conferência na máquina de verdade:

- [ ] Atalhos: capturar a tecla com o teclado de verdade (o `wtype` manda outro keymap) e os atalhos do shell disparando.
- [ ] Mouse e teclado: capturar botões e teclas, remapear teclas e os binds dos botões extras.
- [ ] Monitores no login: monitor real casado pela descrição (`desc:`) e o arranjo já certo antes de o shell subir.
- [ ] Monitores: arrastar no canvas; em monitor real, a lista de resoluções, o VRR e a cor de 10 bits.
- [ ] Papel de parede: pausa com a tela bloqueada e com a tela apagada; o vídeo solta o decodificador depois de 2 min pausado; 60 fps caem para 30 na bateria.
- [ ] Ociosidade: suspender, segurar com mídia tocando e com tela cheia, e o aviso do `hypridle`.
- [ ] Luz noturna: a cor mudando de fato (a CTM não aparece no Hyprland aninhado nem em capturas) e a transição suave.
- [ ] Captura: o som da gravação (sistema e microfone) e a área com escala fracionária ou em outro monitor.
- [ ] Visão geral: arrastar uma janela para outro workspace (no container não dá para simular o arrasto) e vários monitores.
- [ ] Brilho: as teclas ajustando o monitor em foco (no container o foco é a janela aninhada, não o HDMI).
- [ ] Launcher: navegação pelo teclado nos três estilos, `Ctrl+1…9` nas ações do app e o "Mais opções".
- [ ] Central: os ícones da barra abrindo na página certa e fechando no mesmo ícone; os tiles (o corpo liga e desliga, a setinha abre a página), os sliders de volume e brilho e os volumes do microfone e de cada app; a troca de dispositivo, conectar a uma rede com senha, parear, os perfis de energia, a engrenagem e o "Limpar".

## Ambiente de teste

- [ ] Os atalhos com Alt pararam de funcionar no Hyprland aninhado (o teclado chega; os binds existem e as ações funcionam). Com o `wtype`, a causa foi achada: o Hyprland aninhado resolve os binds pelo keycode do keymap real, e o `wtype` dá ao primeiro caractere o keycode 1, que é o Esc (`wtype -M alt c` vira `Alt+Esc`, o menu de energia). O contorno, com caracteres de enchimento antes da tecla, está no `dev/test.sh`. Falta conferir com o teclado de verdade.
