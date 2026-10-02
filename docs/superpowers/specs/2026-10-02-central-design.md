# Central: quatro painéis no lugar da barra lateral

**Data:** 2026-10-02

## Objetivo

Remover a barra lateral (`features/sidebar/`: o painel de altura inteira com o trilho Wi-Fi, Bluetooth, Som, Avisos, Bateria e Tela) e pôr no lugar quatro painéis flutuantes e minimalistas, que abrem juntos: a **central**. Dois ficam à esquerda (Som e Energia) e dois à direita (Controles e Notificações). Nada repete o painel superior (relógio, calendário, clima, mídia e desempenho ficam só nele), e nada do que a barra lateral faz hoje se perde: o que sai dos painéis vai para as Configurações.

Decisões do usuário, na conversa de desenho:

- quatro painéis, um assunto cada: Som; Notificações, só; Bateria e energia; e o resto (Wi-Fi, Bluetooth etc.);
- minimalistas: sem títulos, legendas e informações óbvias; as porcentagens ficam (volume, brilho, bateria);
- o painel de controles segue a referência: Wi-Fi e Bluetooth num card único, com uma setinha que troca o conteúdo do card inteiro pela página do recurso; abaixo, os outros recursos em botões de ícone, cheios quando ligados e vazios quando desligados;
- as notificações ficam embaixo dos controles, na direita;
- a dock é um projeto seguinte, com spec próprio.

## Abertura e fechamento

- Os quatro painéis abrem e fecham juntos, como um painel só (`central`), sobre a área de trabalho, sem escurecer a tela.
- Abrem pelo atalho que hoje abre a barra lateral (`Super+C`; `Alt+C` no desenvolvimento), pelos ícones da direita da barra e pelo launcher (as entradas "Wi-Fi", "Bluetooth", "Som" e "Notificações").
- O ponto de entrada escolhe o que já vem aberto: o ícone de rede abre o card de controles na lista de redes; "Bluetooth", na lista de dispositivos; o sino e `Super+N`, a central com as notificações (sem subpágina). Os demais abrem o estado inicial.
- Clicar de novo no mesmo ícone, `Esc` ou clique fora de todos os painéis fecham.
- A central é modal como os outros painéis: abrir o painel superior, o launcher etc. fecha a central, e vice-versa. Os popups de notificação ficam escondidos com a central aberta, como hoje com a barra lateral.
- IPC: `central open [rede|bluetooth|som|notificacoes|energia]`, `central toggle [...]` e `central close`. Os nomes antigos (`sidebar open wifi` etc.) deixam de existir.
- Entrada animada: cada painel desliza do seu lado e aparece, com um pequeno atraso entre os quatro; a saída é mais rápida.

## Os painéis

Todos com o mesmo vidro dos outros painéis do shell, cantos arredondados, e grupos em cartões internos. Largura de uns 400 px a 1920 px; a esquerda e a direita colam nas bordas com a mesma margem, abaixo da barra.

### Som (esquerda, em cima)

- **Saída:** ícone, nome do dispositivo, porcentagem e uma setinha; embaixo, o volume. Clicar no ícone silencia (o ícone mostra o mudo). A setinha troca o card pela lista de saídas, com voltar.
- **Entrada:** igual, para o microfone.
- **Por aplicativo:** um item por stream de áudio tocando agora, com o ícone do app, o volume e a porcentagem; clicar no ícone silencia o app. Sem streams, o grupo some.
- Precisa de um serviço novo: hoje `services/Audio.qml` descarta os streams do Pipewire (`isStream`).

### Energia (esquerda, embaixo)

- Bateria em destaque: porcentagem grande, o tempo restante (ou "carregando") e uma barra.
- Perfil de energia em três botões de ícone (economia, equilibrado, desempenho), o atual preenchido.
- Bateria dos dispositivos Bluetooth conectados que informam bateria: ícone, nome e porcentagem.
- Sem bateria (desktop), o bloco da bateria some; sem perfil de energia disponível, os botões somem; com o painel inteiro vazio, ele não aparece.
- Saem do shell: consumo (W) e saúde da bateria.

### Controles (direita, em cima)

- **Card de rede:** duas linhas, Wi-Fi (o nome da rede, ou "Desligado") e Bluetooth ("Ligado"/"Desligado", ou o nome do dispositivo conectado), cada uma com uma setinha.
- A setinha troca o card inteiro pela página do recurso, com voltar e o liga/desliga no topo: no Wi-Fi, a lista de redes, conectar (com o campo de senha) e esquecer; no Bluetooth, procurar, pareados e disponíveis, conectar, desconectar e esquecer. É o que a barra lateral faz hoje, no formato do card.
- **Brilho:** o volume de brilho da tela em foco, com a porcentagem.
- **Botões de ícone** (cheios quando ligados, vazios quando desligados): luz noturna, não perturbe, não apagar a tela e configurações (abre as Configurações).
- Vão para as Configurações: o brilho de cada monitor e a temperatura da luz noturna.

### Notificações (direita, embaixo)

- Cabeçalho "Notificações" e o botão "Limpar"; a lista das notificações, a mais nova em cima, com as ações delas, como os cards de hoje.
- Sem notificações, um estado vazio discreto (só o ícone). O não perturbe fica nos botões do painel de controles.
- Ocupa a altura que sobra abaixo dos controles e rola.

## Estrutura

- A feature `features/sidebar/` dá lugar a `features/central/` (state e ui), seguindo a casa: lógica no `state/`, tela no `ui/`, serviços em `services/`.
- Os states de Wi-Fi, Bluetooth, Som, Avisos, Bateria e Tela que já existem são aproveitados onde servirem, em vez de reescritos.
- Sai a configuração de lado da barra lateral (`sidebarSide`) e a página dela nas Configurações; sai o recuo do painel superior para a barra lateral (`leftInset`/`rightInset`).
- Um serviço novo de streams de áudio por app.
- `core/panels/Panels.qml`: o painel `sidebar` vira `central`, com a seção de entrada; sai a convivência dele com o painel superior.

## O que mais muda

- Barra: os ícones da direita abrem a central na entrada certa.
- Launcher, atalhos (`ShellShortcuts`, `InputActions`, a página de atalhos), notificações (`centerOpen`), Configurações: trocam a barra lateral pela central.
- `ci/smoke.sh`: os passos das seis seções viram os passos da central e das subpáginas.
- `tests/panels.test.js`: os casos da barra lateral viram os da central.
- README (capturas `docs/screenshots/sidebar-*.jpg` viram uma captura da central), Proposta e Pendências.

## Testes

- Unidade: a lógica de entrada (qual subpágina abre por qual caminho, o toggle no mesmo ícone, a modalidade) em `Panels`/estado; a montagem da lista de streams por app (com dados falsos); o que some quando não há bateria ou perfil.
- Fumaça: abrir a central por cada entrada e as subpáginas de Wi-Fi e Bluetooth, sem avisos.
- Conferência na tela (`dev/test.sh`): os quatro painéis, a entrada animada, cada subpágina, os botões cheios e vazios, tema claro e escuro.
- Com o mouse (usuário): volumes, troca de dispositivo, conectar a uma rede, botões, Limpar.

## Fora do escopo

- A dock (projeto seguinte).
- Modo avião (o shell não tem rfkill hoje).
- Histórico persistente de notificações.
