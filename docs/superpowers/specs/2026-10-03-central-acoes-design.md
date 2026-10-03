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

- Dois painéis colados na borda direita, abaixo da barra (`Panels.topInset`), com a mesma margem de hoje e **440 px** de largura.
- Ações em cima, com a altura do conteúdo; Notificações embaixo, na altura que sobra, rolando (como hoje).
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
- Clique no corpo: liga/desliga (Wi-Fi e Bluetooth: o rádio; Microfone: mudo; Luz noturna, Não perturbe, Não apagar a tela: o recurso). Clique na setinha: abre a página. Saída de áudio e Bateria não têm liga/desliga: o corpo também abre a página.
- Ripple e hover como os `Clickable` da casa.

| Tile | Linha de estado | Some quando |
| --- | --- | --- |
| Wi-Fi | o nome da rede, "Desligado" ou "Bloqueado" | sem placa Wi-Fi (vira "Rede", com o estado da conexão cabeada, sem página — como hoje) |
| Bluetooth | o dispositivo conectado, "Ligado" ou "Desligado" | sem adaptador |
| Saída de áudio | o nome do dispositivo de saída | sem saída de áudio |
| Bateria | `78% · 1 h 52 min`, `40% · Carregando` ou `100% · Carregada`; sem bateria, vira "Energia" com o perfil atual | sem bateria e sem perfil de energia |
| Microfone | o nome da entrada, ou "Mudo" | sem entrada |
| Luz noturna | "Ligada" / "Desligada" | — |
| Não perturbe | "Ligado" / "Desligado" | — |
| Não apagar a tela | "Ligado" / "Desligado" | — |

Os tiles que somem tiram o lugar do grid; os demais se reorganizam na mesma ordem, duas colunas.

### Sliders

- Pílulas largas (~40 px de altura), a parte cheia na cor de destaque; ícone à esquerda; rótulo ("Volume", "Brilho") e porcentagem à direita, dentro da pílula.
- Volume: o volume da saída; clicar no ícone silencia (o ícone mostra o mudo). Some sem saída de áudio.
- Brilho: o da tela em foco (`Brightness.focusedScreen`). Some quando a tela em foco não tem brilho ajustável.
- Arrastar não pode ser interrompido por atualização do modelo (mesma regra de modelo estável de hoje).

### Páginas

A setinha (ou o corpo, nos tiles sem liga/desliga) troca **o card inteiro**, tiles e sliders, pela página do recurso, com a animação de troca de hoje e um cabeçalho com voltar e o título; nas páginas com liga/desliga (Wi-Fi, Bluetooth), o interruptor fica no cabeçalho, como hoje.

- **Wi-Fi:** como hoje (lista de redes, conectar com senha, esquecer).
- **Bluetooth:** como hoje (procurar, pareados e disponíveis, conectar, desconectar, esquecer).
- **Saída de áudio:** a lista de saídas (a atual marcada) e, embaixo, o volume de cada app com áudio aberto (ícone do app, slider, porcentagem; o nome só na falta do ícone; clicar no ícone silencia o app) — o conteúdo do painel de Som de hoje.
- **Microfone:** o volume do microfone (com o mudo no ícone) e a lista de entradas.
- **Bateria:** o conteúdo do painel de Energia de hoje: a porcentagem grande com o tempo (ou "Carregando"/"Carregada") e a barra; os botões de perfil (o atual cheio); as baterias dos dispositivos Bluetooth. Sem bateria, só o que existir.

Fechar a central volta tudo ao estado inicial na próxima abertura (como hoje: página, senha e erro do Wi-Fi zerados).

## Entradas

| Entrada | Abre em |
| --- | --- |
| ícone de rede, `central open rede` | página do Wi-Fi (sem Wi-Fi: estado inicial) |
| launcher "Bluetooth", `central open bluetooth` | página do Bluetooth |
| ícone de som, launcher "Som", `central open som` | página da Saída de áudio |
| ícone de bateria, `central open energia` | página da Bateria |
| sino, `Super+N`, launcher "Notificações", `central open notificacoes` | estado inicial |
| `Super+C`, `central open` | estado inicial |

O toggle no mesmo ícone continua fechando; outra entrada troca a página. Entrada para uma página cujo recurso não existe (ex.: `som` sem áudio) abre o estado inicial.

## Estrutura

- `features/central/`: o `ControlsPanel` vira o painel de Ações (`ActionsPanel`); o `SoundPanel` e o `EnergyPanel` deixam de ser painéis e viram páginas dentro dele; sai a coluna da esquerda do `Central.qml`.
- Componentes novos de interface em `features/central/ui/`: `Tile` e `PillSlider` (se servirem a mais de uma feature, `core/widgets/`).
- O estado de página passa a ser um só (`CentralState.page`: `""`, `wifi`, `bluetooth`, `output`, `input`, `battery`), no lugar de `controlsPage` e `soundPage`; `pageFor(entry, …)` decide a página da entrada, considerando o que existe.
- Os states existentes (`SoundState`, `PowerState`, `ControlsState`, `WifiState`, `BluetoothState`, `InboxState`) são reaproveitados; o que ficar sem uso sai.
- `LevelRow`, `DeviceLevel` e afins: ficam só se as páginas os usarem; o que sobrar sai.

## Testes

- Unidade: `pageFor` para cada entrada, inclusive `som` e `energia` abrindo páginas e a queda para o estado inicial sem o recurso; a linha de estado da bateria (com tempo, carregando, carregada, sem bateria com perfil); o que some sem bateria/perfil, sem microfone, sem Wi-Fi.
- Fumaça: abrir a central por cada entrada e cada página por IPC, sem avisos.
- Na tela (`dev/test.sh`): o estado inicial, cada página, tiles ligados e desligados, os dois temas; a captura `docs/screenshots/central.jpg` refeita.
- Com o mouse (usuário): os tiles, as setinhas, os sliders, a troca de dispositivo, o Wi-Fi com senha.

## Documentação

README, Proposta e Pendências passam a descrever os dois painéis.

## Fora do escopo

A linha de CPU, RAM e disco; a dock; modo avião.
