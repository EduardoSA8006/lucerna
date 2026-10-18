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
- Só as Ações: no mesmo lugar; sozinhas podem usar a altura toda (sem reservar o mínimo das Notificações).
- Só as Notificações: sobem para logo abaixo da barra (`Panels.topInset`) e ocupam a altura toda até a margem de baixo.
- A mudança de posição/altura das Notificações quando as Ações abrem ou fecham com elas abertas é animada (as Notificações sobem/descem junto com a saída/entrada das Ações); a troca de página das Ações continua animando a altura como hoje, e as Notificações acompanham.
- A entrada e a saída de cada painel continuam animadas (desliza da direita), cada painel reagindo ao próprio estado: abrir um com o outro já aberto anima só o que entra; fechar um anima só o que sai. O atraso em cascata (40 ms) só vale quando os dois abrem juntos. Ao fechar o último, a saída do painel cabe no tempo de saída do `OverlayPanel`.

### Fechar

- `Esc` e o clique fora dos painéis são o "fechar tudo" da janela: fecham os dois. Os atalhos e os ícones são individuais. (Durante a animação de saída de um painel, um clique na área dele ainda conta como dentro — aceitável.)
- Ao fechar as Ações com um campo focado (a senha do Wi-Fi), o foco volta ao `focusSink` da janela.
- Os dois continuam modais em relação ao resto do shell: abrir o painel superior, o launcher, as Configurações etc. fecha os dois; abrir qualquer um deles fecha esses outros painéis (como a central hoje).
- A barra continua clicável com eles abertos (`keepBar`).

### Popups de notificação

Os popups ficam no canto superior direito, exatamente onde as Ações aparecem, e a janela da central cobre a tela: com só as Ações abertas, um popup cobriria as Ações ou ficaria visível mas não clicável. Por isso (revisão do spec): os popups ficam **escondidos com qualquer um dos dois aberto**, como hoje; a fila só é **limpa** ao abrir e ao fechar as **Notificações** (com só as Ações, o que chega fica para aparecer quando elas fecharem, ou na lista das Notificações).

### Estado ao abrir

- As Ações abrem no estado inicial, ou na página da entrada; fechar as Ações volta a página ao estado inicial na próxima abertura (senha e erro do Wi-Fi zerados), como hoje — mesmo se as Notificações continuarem abertas.

## IPC

- `controls open|toggle|close [rede|bluetooth|som|microfone|energia|""]` — as Ações (o nome `controls` evita a confusão com o alvo `action` que já existe).
- `notifications open|toggle|close` — no `IpcHandler` que já existe em `NotificationsState` (junto de `clear`, `toggleDnd`, `count`), não num segundo handler com o mesmo alvo.
- `central open|toggle|close [entrada]` — os dois. `open`: abre os dois; a entrada, se houver, define a página das Ações (`notificacoes` = estado inicial). `toggle` sem entrada: a regra do atalho geral. `toggle` com entrada: fecha os dois só se os dois estiverem abertos e a entrada for a atual; senão abre o que falta e troca a página.
- `panels open|toggle central` (e o nome antigo `sidebar`, que já é ignorado) abre os dois.

## Estrutura

- `core/panels/Panels.qml` (estrutura recomendada na revisão): `central` **continua um único painel modal**; ganha dois sub-estados, `actionsOpen` e `notificationsOpen`, com `isOpen("central") === actionsOpen || notificationsOpen`. Uma função pura (`setCentral(a, n)` ou equivalente) faz `open("central")` quando um fica verdadeiro e `dismiss("central")` quando os dois ficam falsos; o `onOpenedChanged` zera os dois e o `centralEntry` (a entrada das Ações) quando a central é fechada por fora (outro modal, `Esc`, `panels close`). `toggleActions(entry)`, `toggleNotifications()` e `toggleCentral(entry)` são combinações dela, puras e testadas. Modalidade, grab, companions, `names`, o IPC `panels` e o `OverlayPanel` (`keepBar`, máscara, `keyboardFocus`) ficam como estão; fechar o último fecha a janela de graça. (Contra aceito: `panels get` mostra só `central`.)
- `features/central/state/CentralState.qml`: o `reset()` ao abrir, as `Binding` de `Network.scanning` e `Battery.historyActive` e o zerar da página passam a depender de `actionsOpen` (abrir as Ações com as Notificações já abertas reseta; fechar só as Ações para a busca de redes e o histórico).
- `features/central/ui/`: a tela continua num `OverlayPanel` (um só, com `keepBar`), com os dois painéis como filhos; cada um entra e sai pelo próprio estado.
- `ShellShortcuts`, `InputActions` (rótulos: "Abrir as ações", "Abrir as notificações", "Abrir a central"), `InputState` (o `case "notifications"` passa a abrir só as Notificações — **mudança de comportamento** do `Super+N`, que hoje abre a central inteira nas notificações), a página de atalhos, `BarState` (o sino aceso = Notificações abertas; o ícone de uma entrada aceso = Ações abertas com essa entrada; com só as Notificações abertas, `toggleEntry("rede")` abre as Ações), `LauncherState`, `NotificationsState` e `ci/smoke.sh` (que hoje faz `central toggle som` depois de `central open notificacoes`) acompanham.

## Testes

- Unidade (`tests/panels.test.js`, `tests/central.test.js`): cada atalho sozinho e com o outro aberto; o fechamento por fora zerando os dois sub-estados; o `central toggle` com e sem entrada; as regras de aceso da barra; o atalho geral nos quatro estados (nenhum, só Ações, só Notificações, os dois); o toggle por entrada das Ações sem afetar as Notificações; a modalidade com o painel superior e o launcher; os popups escondidos só com as Notificações.
- Fumaça: IPC de cada um e do geral, sem avisos.
- Na tela: só as Ações, só as Notificações (subindo), os dois, e a animação ao abrir/fechar um com o outro aberto.

## Documentação

README (atalhos, IPC), Proposta e Pendências.
