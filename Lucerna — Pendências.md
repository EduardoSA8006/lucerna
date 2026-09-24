# Lucerna — Pendências

O que falta fazer, na ordem em que vamos seguir. Cada item vira um PR; ao terminar, ele é marcado aqui.

## Em ordem

1. [x] **Proposta atualizada.** A tabela "Escopo" de `Lucerna — Proposta.md` ainda diz que barra, painel e energia estão por fazer e descreve o launcher como só "abrir aplicativos". Faltam monitores, mouse, teclado, papel de parede animado e vídeo.
2. [ ] **Launcher: o que hoje só o estilo completo tem.** Fixar nos favoritos e ocultar um app (por clique direito ou atalho) no compacto e na tela cheia. Busca em arquivos e na web também fora do estilo completo (por prefixo ou atalho).
3. [ ] **Ociosidade e tela.** Desligar a tela e bloquear depois de X minutos, suspender depois de Y, sem depender do `hypridle` (o Quickshell tem `IdleMonitor`). Com exceções: mídia tocando, app em tela cheia e, no modo apresentação, não apagar.
4. [ ] **Luz noturna.** Temperatura de cor por horário (fixo ou pôr e nascer do sol), na seção Tela da central lateral e nas configurações.
5. [ ] **Temas claros.** Catppuccin Latte e Rosé Pine Dawn, as versões claras oficiais (hoje nenhum dos dez temas é claro).
6. [ ] **Atalhos editáveis.** A página Atalhos das configurações só informa; os atalhos do shell continuam no `hyprland.lua`. Passar a editar ali, reaproveitando os binds da aba Teclado.
7. [ ] **Monitores no login.** O arranjo salvo só vale quando o Lucerna inicia, e no login o `hyprland.lua` aparece antes. Opção de gravar o arranjo num arquivo que o `hyprland.lua` inclui.
8. [ ] **Histórico da área de transferência**, no launcher.
9. [ ] **Captura de tela e gravação:** área, janela ou tela, com notificação e atalho.
10. [ ] **Visão geral dos workspaces**, com as janelas em miniatura.
11. [ ] **Brilho de monitores externos** por DDC/CI.
12. [ ] **Instalação e distribuição:** script de instalação (link, trecho do `hyprland.lua`, atalhos padrão), pacote no AUR e verificação no CI (`qmllint`).
13. [ ] **Plugins próprios**, na ordem de `Lucerna — Plugins Próprios.md`: `lucerna-sysinfo`, depois `lucerna-spectrum`, depois os demais.

## Verificar com hardware e entrada reais

No ambiente de teste não dá para simular cliques, e o Hyprland ignora teclado virtual. Estes pontos foram testados só pela lógica (IPC e capturas) e precisam de uma conferência na máquina de verdade:

- [ ] Mouse e teclado: capturar botões e teclas, remapear teclas e os binds dos botões extras.
- [ ] Monitores: arrastar no canvas; em monitor real, a lista de resoluções, o VRR e a cor de 10 bits.
- [ ] Papel de parede: pausa com a tela bloqueada e com a tela apagada; o vídeo solta o decodificador depois de 2 min pausado; 60 fps caem para 30 na bateria.
- [ ] Launcher: navegação pelo teclado nos três estilos, `Ctrl+1…9` nas ações do app e o "Mais opções".

## Ambiente de teste

- [ ] Os atalhos com Alt pararam de funcionar no Hyprland aninhado (o teclado chega; os binds existem e as ações funcionam). A causa não foi achada.
