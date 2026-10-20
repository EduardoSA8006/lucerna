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
12. [x] **Central.** Dois painéis flutuantes na direita, no lugar da barra lateral: ações (tiles com uma página por recurso, inclusive o volume de cada app, e os sliders de volume e brilho) e notificações, independentes (`Super+A`, `Super+N`; os dois com `Super+C`). Mudança de comportamento: `Super+N` (a ação `notifications`) agora abre só as notificações; a central inteira fica em `Super+C`.
13. [ ] **Dock**, com spec próprio.
14. [ ] **Instalação e distribuição:** script de instalação (link, trecho do `hyprland.lua`, atalhos padrão) e pacote no AUR. A verificação no CI já está feita: quatro checks obrigatórios (`ci/`, `dev/ci.sh`).
15. [ ] **Lógica fora do shell (Rust).** Ver a seção "Separação da lógica" abaixo. Substitui o plano de plugins em C++ de `Lucerna — Plugins Próprios.md`, que precisa ser revisto à luz dela.
16. [ ] **Equalizador de áudio**, com spec próprio: muda o som (filtro do PipeWire, `filter-chain`, ou controle do EasyEffects) e mostra o espectro ao vivo atrás das faixas, reaproveitando o módulo de espectro.

## Separação da lógica (a definir melhor)

Decisão (2026-10-18): o shell é só a interface; a lógica vai para código separado, em Rust, num **repositório próprio e público**, com as mesmas configurações do `lucerna-shell` (licença GPL-3.0, CI com checks obrigatórios, ruleset da branch principal, revisão, padrão de commits em português). Ainda falta definir: a forma (um daemon com módulos, como `lucernad`, ou vários binários), o protocolo com o shell (proposta: socket Unix em `$XDG_RUNTIME_DIR` com mensagens JSON e atualizações enviadas pelo daemon, lido pelo `Socket` do `Quickshell.Io`), o empacotamento e a versão do protocolo entre os dois repositórios.

Princípio da migração: cada `services/` do shell mantém as mesmas propriedades e vira um adaptador; com o daemon rodando, lê dele; sem ele, usa a implementação atual. Um módulo por vez, como já está feito com o espectro (`services/spectrum/Cava.qml` isolado atrás do `Spectrum`).

Fica no shell: as APIs nativas do Quickshell (PipeWire, MPRIS, Bluetooth, rede, notificações, PAM, Hyprland), a coordenação dos painéis, os temas, a geometria dos monitores nas configurações, a formatação e as animações.

Módulos propostos, em ordem de prioridade:

1. [ ] **Espectro:** captura do PipeWire e FFT próprias no lugar do `cava` (hoje `services/spectrum/Cava.qml`); detecção de batida depois.
2. [x] **Sistema:** CPU, memória, rede, discos, temperaturas e GPU no lugar do parse em `services/SystemStats.qml`, do `gpu-status.sh`, do `drm-fdinfo.sh`, do `df` e do `lsblk`; NVIDIA pela NVML, sem `nvidia-smi` (feito em 2026-10-20: módulo `system` do `lucernad`).
3. [ ] **Área de transferência:** observador do Wayland, histórico com deduplicação e imagens (SQLite), no lugar do `wl-paste --watch`, do base64 decodificado em JS e do `clipboard.json`.
4. [ ] **Energia e brilho:** histórico do UPower e perfis de energia por D-Bus (hoje `busctl`), brilho interno e DDC/CI por biblioteca (hoje `brightnessctl` e `ddcutil`).
5. [ ] **Rede externa:** letras (LRCLIB) e clima (Open-Meteo), com cache em disco (hoje sem cache).
6. [ ] **Launcher:** índice de apps com pontuação, frecência de verdade (hoje só contagem), busca de arquivos (hoje `fd`/`find`) e metadados de apps (hoje `app-info.sh`).
7. [ ] **Hyprland:** binds, entrada, keymap (hoje `xkbcli`) e monitores pelo socket IPC do Hyprland, no lugar do `hyprctl eval` e da geração de Lua.
8. [ ] **Luz noturna:** gama direto pelo protocolo `wlr-gamma-control`, sem o `hyprsunset`.
- [ ] **Ferramenta à parte:** `lucerna-video`, o conversor de papel de parede em vídeo (hoje `video-wallpaper.sh`, com `ffmpeg`), em lote, fora do daemon.
- [ ] Depois, se valer: captura de tela e gravação (hoje `grim` e `wf-recorder`).

## Depois

- [ ] Aba Desempenho: um medidor de bateria em forma de pilha, só no notebook. Rascunhos de três encaixes (ao lado de CPU e GPU, em pé ao lado da Memória, faixa embaixo) em `.superpowers/brainstorm/436361-1792526405/content/bateria-desempenho.html`; o usuário quer planejar melhor antes.
- [ ] Aurora, Brasas, Chama e Vaga-lumes somam luz ao fundo e, num tema claro, estouram para branco. Adaptá-los como o Ondas (que já tem versão clara). Os efeitos próprios dos temas claros (Ondas e Névoa) estão bons.
- [ ] Sliders das configurações gravam o `Config` a cada movimento (GlassPage, NightLightPage, IdlePage, MousePage, KeyboardPage, PowerPage e NotificationsPage). Com `blockWrites` não há perda nem corrupção, e a gravação mediu 1,4 ms em NVMe, mas em disco lento o arrasto pode engasgar. Correção prevista: debounce de uns 200 ms, com o reload suspenso durante a espera e um flush ao sair.
- [ ] Fumaça com o Hyprland de verdade, quando houver runner com GPU: hoje ela roda no `sway` headless, e o que depende do Hyprland (workspaces, visão geral com janelas, `hyprctl`) não é exercitado.
- [ ] `CHANGELOG`, junto com as releases.
- [ ] Central, Wi-Fi: o `WifiState.networks` refaz a lista inteira a cada mudança, então as linhas são recriadas e a senha que estava sendo digitada se perde quando a lista de redes se atualiza. Manter as linhas pela rede (ou guardar a senha fora do delegate).
- [ ] Central, bateria: a sonda do power-profiles-daemon (`busctl`) roda só na partida do shell. Se o daemon subir depois, os botões de perfil (e o tile "Energia" de um desktop) não aparecem até reiniciar o shell. Repetir a sonda (ao abrir a central ou ao mudar o `PowerProfiles`).
- [ ] Central, saída de áudio: o volume por app mostra qualquer app com áudio aberto, inclusive pausado, porque o `PwNode` do Quickshell 0.3 não diz se o stream está tocando. Filtrar quando houver esse estado.
- [ ] Central, saída de áudio (aceito): sem saída padrão, o volume por app não aparece, porque a página da Saída some junto com o tile.
- [ ] Central, sliders (aceito): a roda do mouse sobre um slider largo (volume, brilho, microfone) muda o valor em vez de rolar a página.
- [ ] Central (aceito): as ações e as notificações são sub-estados de um painel modal só, então o `panels get` mostra só `central`, sem dizer qual dos dois está aberto.
- [ ] Central (aceito): durante a saída animada de um dos dois painéis, um clique na área dele ainda conta como dentro (não fecha a central).
- [ ] Central, saída de áudio (aceito; conferir com o mouse): ao trocar para um sink Bluetooth recém-conectado, a página da Saída pode voltar ao estado inicial se o sink demorar a ficar pronto (o recurso "some" por um instante).
- [ ] Central, popups (alternativa adiada): com só as ações abertas, os popups ficam escondidos e esperam. Poderiam descer para baixo das ações e continuar aparecendo.
- [ ] Notificações: histórico persistente (hoje só sobrevive ao reload) e modo avião (o shell não tem rfkill), ambos fora do escopo da central.
- [ ] Espectro: o `cava` escuta a saída padrão inteira, então qualquer som da máquina mexe nas barras, não só o player escolhido. Resolver no módulo de espectro em Rust (capturar o stream do player).
- [ ] README: a captura `docs/screenshots/hero.jpg` (cena montada com terminais e música) ainda mostra o visual antigo do painel superior. Refazer a cena.
- [ ] Lint: quando o CI deixar de testar o Qt 6.11, tirar o `unqualified` das quatro linhas de supressão das margens e do `QMLLINT_ALLOWED_COMMENT` em `ci/rules.py`.
- [ ] Crédito ao Caelestia também na página Sobre das configurações (hoje só no README).

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
- [ ] Painel superior: as setas do calendário (a bolha some em outro mês e volta no atual), o clique nos cards de GPU e de Disco trocando de GPU e de disco (com o esmaecimento), o "4,8 / 224 GiB" do `sda`, o clique numa linha da letra pulando para o trecho, a troca de player pelo ícone e as ondas do card de mídia reagindo ao som (sem o `cava`).
- [ ] Aba Desempenho: a temperatura da RTX (lida pela NVML do `lucernad`, só com a placa em uso; o container de teste não tem a NVIDIA) e o uso da Intel pelo fdinfo do `lucernad` na máquina real.
- [ ] Central: os ícones da barra abrindo as ações na página certa e fechando no mesmo ícone (sem fechar as notificações), o sino abrindo e fechando só as notificações, e o foco voltando ao painel (o `Esc` fecha) depois de fechar as ações com a senha do Wi-Fi sendo digitada; os tiles (o corpo liga e desliga, a setinha abre a página), os sliders de volume e brilho e os volumes do microfone e de cada app; a troca de dispositivo, conectar a uma rede com senha, parear, os perfis de energia, a engrenagem e o "Limpar".

## Ambiente de teste

- [ ] Os atalhos com Alt pararam de funcionar no Hyprland aninhado (o teclado chega; os binds existem e as ações funcionam). Com o `wtype`, a causa foi achada: o Hyprland aninhado resolve os binds pelo keycode do keymap real, e o `wtype` dá ao primeiro caractere o keycode 1, que é o Esc (`wtype -M alt c` vira `Alt+Esc`, o menu de energia). O contorno, com caracteres de enchimento antes da tecla, está no `dev/test.sh`. Falta conferir com o teclado de verdade.
- [ ] `dev/ci.sh` usa nomes fixos de contêiner (`lucerna-ci-<check>`) e começa com `docker rm -f`, então duas execuções ao mesmo tempo (dois worktrees) se derrubam. Acrescentar um sufixo por worktree ou PID.
- [ ] A imagem do container de teste avisa "locale C" (o `LANG=pt_BR.UTF-8` sem o locale gerado) e o log mostra `qt.qpa.wayland.textinput ... disableSurface`. Gerar o locale no `dev/Dockerfile` e conferir se o aviso do textinput some.
- [ ] Os testes de áudio no container tocam pelo PipeWire do host (saem nos alto-falantes). Usar sempre `mpv --ao=null` ou um sink nulo; documentar no `dev/test.sh`.
