# Central: Ações e Notificações independentes

**Data:** 2026-10-17
**Revisa:** `2026-10-03-central-acoes-design.md` (e o `2026-10-02-central-design.md` no que ele mantém). O conteúdo dos dois painéis não muda; muda só como eles abrem e fecham.

## Objetivo

Hoje os dois painéis da direita (Ações em cima, Notificações embaixo) abrem e fecham juntos, como um painel só (`central`). Passam a ser **independentes**: cada um tem o próprio atalho, abrir um não fecha o outro, os dois podem ficar abertos juntos, e o atalho de um fecha só ele. Um atalho geral, opcional, abre os dois.

## Comportamento

### Atalhos (configuráveis como os demais)

| Atalho padrão | Ação | Efeito |
| --- | --- | --- |
| `Super+A` (`Alt+A` no desenvolvimento) | `actions` | abre/fecha só as Ações |
| `Super+N` (`Alt+N`) | `notifications` | abre/fecha só as Notificações |
| `Super+C` (`Alt+C`) | `central` | se os dois estão abertos, fecha os dois; senão, abre o que falta (os dois ficam abertos). Pode ficar vazio nas Configurações |

Os nomes salvos antigos continuam valendo (`sidebar` → `central`, ponte já existente).

### Barra

- Ícones de rede, som e bateria: abrem as Ações na página certa (como hoje: `rede` → Wi-Fi, `som` → Saída, `energia` → Bateria); o mesmo ícone de novo fecha só as Ações (o toggle por entrada de hoje, restrito às Ações); outro ícone troca a página.
- Sino: abre/fecha só as Notificações.
- Launcher: "Wi-Fi", "Bluetooth" e "Som" abrem as Ações na página; "Notificações" abre as Notificações.

### Posição

- Os dois abertos: como hoje (Ações em cima, com a altura do conteúdo limitada; Notificações embaixo, na altura que sobra).
- Só as Ações: no mesmo lugar.
- Só as Notificações: sobem para logo abaixo da barra (`Panels.topInset`) e ocupam a altura toda até a margem de baixo.
- A mudança de posição/altura das Notificações quando as Ações abrem ou fecham com elas abertas é animada.
- A entrada e a saída de cada painel continuam animadas (desliza da direita); abrir um com o outro já aberto anima só o que entra; fechar um anima só o que sai.

### Fechar

- `Esc` e o clique fora dos painéis fecham os dois.
- Os dois continuam modais em relação ao resto do shell: abrir o painel superior, o launcher, as Configurações etc. fecha os dois; abrir qualquer um deles fecha esses outros painéis (como a central hoje).
- A barra continua clicável com eles abertos (`keepBar`).

### Popups de notificação

Escondidos (e limpos ao abrir e ao fechar, como hoje) só com o painel de **Notificações** aberto. Com só as Ações abertas, os popups aparecem normalmente.

### Estado ao abrir

- As Ações abrem no estado inicial, ou na página da entrada; fechar as Ações volta a página ao estado inicial na próxima abertura (senha e erro do Wi-Fi zerados), como hoje — mesmo se as Notificações continuarem abertas.

## IPC

- `actions open|toggle|close [rede|bluetooth|som|microfone|energia|""]`
- `notifications open|toggle|close`
- `central open|toggle|close [entrada]` — sempre os dois; a entrada, se houver, define a página das Ações (`notificacoes` abre os dois com as Ações no estado inicial). O `toggle` segue a regra do atalho geral.

## Estrutura

- `core/panels/Panels.qml`: a central deixa de ser um painel modal único. Proposta: dois painéis (`actions`, `notifications`) que formam um **grupo** — abrir um do grupo não fecha o outro do grupo, mas fecha os painéis de fora; abrir um de fora fecha os do grupo. `centralEntry` vira a entrada das Ações. Funções puras e testadas para: o toggle de cada um, o atalho geral (abre o que falta / fecha os dois), o toggle por entrada das Ações e a modalidade com os outros painéis.
- `features/central/`: a tela continua num `OverlayPanel` (um só, com `keepBar`), com os dois painéis como filhos; cada um aparece conforme o seu estado. O clique fora fecha os dois.
- `ShellShortcuts`, `InputActions`, a página de atalhos, `BarState`, `LauncherState`, `NotificationsState` (o esconder dos popups passa a depender só do painel de Notificações) e `ci/smoke.sh` acompanham.

## Testes

- Unidade (`tests/panels.test.js`, `tests/central.test.js`): cada atalho sozinho e com o outro aberto; o atalho geral nos quatro estados (nenhum, só Ações, só Notificações, os dois); o toggle por entrada das Ações sem afetar as Notificações; a modalidade com o painel superior e o launcher; os popups escondidos só com as Notificações.
- Fumaça: IPC de cada um e do geral, sem avisos.
- Na tela: só as Ações, só as Notificações (subindo), os dois, e a animação ao abrir/fechar um com o outro aberto.

## Documentação

README (atalhos, IPC), Proposta e Pendências.
