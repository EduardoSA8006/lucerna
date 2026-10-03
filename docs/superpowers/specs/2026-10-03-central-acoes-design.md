# Central: dois painéis, Ações e Notificações

**Data:** 2026-10-03
**Revisa:** `2026-10-02-central-design.md` (mesma branch, `feat/central`, ainda não mesclada). O que este spec não muda continua valendo de lá: abertura e fechamento, modalidade, `keepBar`, IPC, popups escondidos, atalhos, o que foi para as Configurações e o que saiu do shell.

## Objetivo

A central deixa de ter quatro painéis (Som e Energia à esquerda, Controles e Notificações à direita) e passa a ter **dois, na direita**: **Ações** em cima e **Notificações** embaixo. Som e Energia entram no painel de Ações, no estilo da referência do usuário: tiles em duas colunas e sliders largos.

Decisões do usuário:

- só dois painéis, na direita; as notificações ficam como estão;
- tiles em duas colunas com ícone, título e uma linha de estado; setinha nos que têm página;
- sliders largos de volume e brilho, com rótulo e porcentagem dentro;
- **sem** a linha de CPU, RAM e disco da referência (repetiria o painel superior);
- a energia vira um tile "Bateria" com página;
- os tiles e a ordem abaixo, e a engrenagem das Configurações fora do grid.

## Layout

- Dois painéis colados na borda direita, abaixo da barra (`Panels.topInset`), com a mesma margem de hoje e **440 px** de largura (`CentralPanel.width` vira propriedade).
- Ações em cima, com a altura do conteúdo, **limitada** à altura disponível menos 160 px (o mínimo das Notificações e o espaço entre os dois); passando disso, o conteúdo da página rola dentro do card. Notificações embaixo, na altura que sobra (no mínimo 160 px), rolando como hoje.
- A altura do Ações anima ao trocar de página (`Behavior` em `height`), e as Notificações acompanham.
- A cascata de entrada (`CentralPanel`) fica com os dois painéis, na mesma direção (da direita).
- **Engrenagem:** um botão de ícone pequeno no canto superior direito do painel de Ações, numa faixa fina acima dos tiles (uns 8 px de respiro antes deles), sem título. Abre as Configurações.

## Painel de Ações

### Estado inicial

```
                                   [⚙]
[ Wi-Fi          › ]  [ Bluetooth      › ]
[ Saída de áudio › ]  [ Bateria        › ]
[ Microfone      › ]  [ Luz noturna      ]
[ Não perturbe     ]  [ Não apagar tela  ]
  ████ Volume                        25%
  ████████ Brilho                    55%
```

### Tile

- Retângulo arredondado; à esquerda um ícone num círculo; título e, embaixo, uma linha de estado menor; nos tiles com página, a setinha à direita, separada por um traço vertical fino (como na referência).
- **Ligado:** preenchido na cor de destaque (o texto e o ícone no contraste dela); **desligado:** fundo neutro elevado. Tiles sem estado liga/desliga (Saída de áudio, Bateria) usam o fundo neutro.
- Clique no corpo: liga/desliga (Wi-Fi e Bluetooth: o rádio; Microfone: mudo; Luz noturna, Não perturbe, Não apagar a tela: o recurso). Clique na setinha: abre a página. Saída de áudio e Bateria não têm liga/desliga: o corpo também abre a página. Wi-Fi bloqueado (rfkill): o corpo abre a página, que já explica o bloqueio. O tile "Rede" (sem placa Wi-Fi) não tem clique.
- **Quando o tile está ligado (cheio):** Wi-Fi e Bluetooth, com o rádio ligado; Microfone, sem mudo; Luz noturna, Não perturbe e Não apagar a tela, com o recurso ligado. Saída de áudio, Bateria e Rede ficam sempre neutros; a Bateria com pouca carga (`Battery.isLow`, sem carregar) mostra o ícone na cor de erro, como o vermelho da barra.
- Número ímpar de tiles: o último ocupa meia largura, alinhado à esquerda.
- Os tiles vêm de uma lista pura num state (`ControlsState.tiles`, como o `toggles` de hoje), lida por quantidade (modelo estável). Quando um tile some, os seguintes trocam de índice; a cor e o hover seguem o tile novo — aceitável.
- Ripple e hover como os `Clickable` da casa.

| Tile | Linha de estado | Some quando |
| --- | --- | --- |
| Wi-Fi | o `WifiState.summary` de hoje: o nome da rede, "Não conectado", "Cabo", "Desligado" ou "Bloqueado" | sem placa Wi-Fi (vira "Rede", com o estado da conexão cabeada, sem página e sem clique — como hoje) |
| Bluetooth | o `summary` de hoje: o dispositivo conectado, "N conectados", "Ligado" ou "Desligado" | sem adaptador |
| Saída de áudio | o nome do dispositivo de saída | sem saída de áudio |
| Bateria | `78% · 1 h 52 min` (sem estimativa, só `78%`), `40% · Carregando` ou `100% · Carregada`; sem bateria, vira "Energia" com o nome do perfil atual ("Economia", "Equilibrado", "Turbo"; os nomes vêm de `Battery.profileNames`) ou, sem perfil, "N dispositivos" | `PowerState.any` falso (sem bateria, sem perfil e sem dispositivo BT com bateria) |
| Microfone | o nome da entrada, ou "Mudo" | sem entrada |
| Luz noturna | "Ligada" / "Desligada" | sem o hyprsunset (`NightLight.available`), como hoje |
| Não perturbe | "Ligado" / "Desligado" | — |
| Não apagar a tela | "Ligado" / "Desligado" | com a ociosidade do shell desligada (`Config.idleEnabled`), como hoje |

Os tiles que somem tiram o lugar do grid; os demais se reorganizam na mesma ordem, duas colunas.

### Sliders

- Pílulas largas (~40 px de altura), a parte cheia na cor de destaque; ícone à esquerda; rótulo ("Volume", "Brilho") e porcentagem à direita, dentro da pílula.
- Volume: o volume da saída; clicar no ícone silencia (o ícone mostra o mudo). Some sem saída de áudio.
- Brilho: o da tela em foco (`Brightness.focusedScreen`), com o mínimo de 1% de hoje (`from: 0.01`, a tela não apaga). Some quando a tela em foco não tem brilho ajustável.
- Arrastar não pode ser interrompido por atualização do modelo (mesma regra de modelo estável de hoje).

### Páginas

A setinha (ou o corpo, nos tiles sem liga/desliga) troca **o card inteiro**, tiles e sliders, pela página do recurso, com a animação de troca de hoje e um cabeçalho com voltar e o título; nas páginas com liga/desliga (Wi-Fi, Bluetooth), o interruptor fica no cabeçalho, como hoje.

- **Wi-Fi:** como hoje (lista de redes, conectar com senha, esquecer).
- **Bluetooth:** como hoje (procurar, pareados e disponíveis, conectar, desconectar, esquecer).
- **Saída de áudio:** a lista de saídas (a atual marcada) e, embaixo, o volume de cada app com áudio aberto (ícone do app, slider, porcentagem; o nome só na falta do ícone; clicar no ícone silencia o app) — o conteúdo do painel de Som de hoje.
- **Microfone:** o volume do microfone num `PillSlider` (com o mudo no ícone) e a lista de entradas.
- **Bateria:** reformulada em `.superpowers/sdd/2026-10-03-bateria/design.md`: o card em forma de bateria, cheio até a carga na cor dela, com a porcentagem e o tempo (ou "Carregando"/"Carregada") por cima; os perfis em botões de texto (o atual cheio); o consumo da última hora num gráfico (o histórico do UPower); as baterias dos dispositivos Bluetooth. Sem bateria, só o que existir.

Fechar a central volta tudo ao estado inicial na próxima abertura (como hoje: página, senha e erro do Wi-Fi zerados).

Se o recurso da página aberta deixa de existir (o fone USB sai na página da Saída, o adaptador BT some, a placa Wi-Fi some), a página volta ao estado inicial (`page = ""`), por uma regra no `CentralState`, com teste.

## Entradas

| Entrada | Abre em |
| --- | --- |
| ícone de rede, `central open rede` | página do Wi-Fi (sem Wi-Fi: estado inicial) |
| launcher "Bluetooth", `central open bluetooth` | página do Bluetooth |
| ícone de som, launcher "Som", `central open som` | página da Saída de áudio |
| ícone de bateria, `central open energia` | página da Bateria |
| sino, `Super+N`, launcher "Notificações", `central open notificacoes` | estado inicial |
| `Super+C`, `central open` | estado inicial |
| `central open microfone` (entrada nova, só IPC) | página do Microfone |

O toggle no mesmo ícone continua fechando, mesmo que o usuário tenha navegado para outra página depois (comportamento de hoje, mantido); outra entrada troca a página. Entrada para uma página cujo recurso não existe (ex.: `som` sem áudio) abre o estado inicial.

## Estrutura

- `features/central/`: o `ControlsPanel` vira o painel de Ações (`ActionsPanel`); o `SoundPanel` e o `EnergyPanel` deixam de ser painéis e viram páginas dentro dele; sai a coluna da esquerda do `Central.qml`.
- Componentes novos de interface em `features/central/ui/`: `Tile` e `PillSlider` (se servirem a mais de uma feature, `core/widgets/`).
- O estado de página passa a ser um só (`CentralState.page`: `""`, `wifi`, `bluetooth`, `output`, `input`, `battery`), no lugar de `controlsPage` e `soundPage`; `pageFor(entry, has)` decide a página da entrada, com `has = { wifi, bluetooth, output, input, power }` (o que existe).
- Dependências da troca para `page` que precisam acompanhar: `BluetoothState.showing` (hoje lê `controlsPage === "bluetooth"`), o `Binding` do `Network.scanning` no `CentralState`, o voltar do `WifiPage` e do `BluetoothPage` (`setControlsPage`), `Panels.centralEntries` (entrada `microfone`), `ci/smoke.sh` e `tests/central.test.js` (`controlsPage`, `soundPage`, `pageFor` com dois argumentos).
- Os states existentes (`SoundState`, `PowerState`, `ControlsState`, `WifiState`, `BluetoothState`, `InboxState`) são reaproveitados; o que ficar sem uso sai.
- O `LevelRow` fica para o volume de cada app; o `DeviceLevel` sai (saída e entrada passam a `PillSlider`); o que mais sobrar sem uso sai.

## Testes

- Unidade: `pageFor` para cada entrada, inclusive `som`, `energia` e `microfone` abrindo páginas e a queda para o estado inicial sem o recurso; a volta ao estado inicial quando o recurso da página some; a linha de estado da bateria (com tempo, sem estimativa, carregando, carregada, sem bateria com perfil, só dispositivos); a lista `tiles` (o que some sem bateria/perfil/dispositivos, sem microfone, sem Wi-Fi, sem hyprsunset, com a ociosidade desligada).
- Fumaça: abrir a central por cada entrada e cada página por IPC, sem avisos.
- Na tela (`dev/test.sh`): o estado inicial, cada página, tiles ligados e desligados, os dois temas; a captura `docs/screenshots/central.jpg` refeita.
- Com o mouse (usuário): os tiles, as setinhas, os sliders, a troca de dispositivo, o Wi-Fi com senha.

## Documentação

README, Proposta e Pendências passam a descrever os dois painéis.

## Fora do escopo

A linha de CPU, RAM e disco; a dock; modo avião.
