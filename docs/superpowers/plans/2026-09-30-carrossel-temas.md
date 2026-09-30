# Seletor de temas em carrossel — plano de implementação

> **Para agentes:** SUB-SKILL OBRIGATÓRIO: use superpowers:subagent-driven-development (recomendado) ou superpowers:executing-plans para implementar este plano tarefa por tarefa. Os passos usam checkbox (`- [ ]`) para acompanhamento.

**Objetivo:** trocar a grade de cards do seletor de temas por um carrossel de cards soltos na parte de baixo da tela, em que as setas giram a fila, o tema do card central é aplicado de verdade depois de uma espera de 300 ms, o Enter mantém e o Esc desfaz.

**Arquitetura:** as contas da fila circular (`wrap`, `offset` e o deslocamento `spread`) ficam num singleton novo de `core/`, `core/carousel/Carousel.qml`, testado pelo harness e coberto pelo gate. O fluxo (abrir, girar com espera, confirmar, desfazer) fica no `ThemeSwitcherState`, que já é o view model da feature; o teste controla a espera por `pending` e `flush()`, sem relógio. A tela (`ThemeSwitcher.qml` e `ThemeCard.qml`) é reescrita sobre o `OverlayPanel` com `dim: 0`, só posiciona os cards pela distância ao centro e repassa teclas e cliques ao estado.

**Tecnologia:** Quickshell 0.3 (QML/Qt 6, `QtQuick.Effects` para saturação, brilho e sombra), Hyprland 0.56 com config em Lua (desfoque por `hl.layer_rule`), harness `tests/runner.qml` no `qs`, `dev/ci.sh` (lint, rules, unit, smoke no `archlinux:latest`) e `dev/test.sh` (conferência visual no container `lucerna-polish`).

**Spec:** `docs/superpowers/specs/2026-09-30-carrossel-temas-design.md` (leia inteiro antes da primeira tarefa; este plano argumenta a partir dele).

## Global Constraints

- Abrir como hoje: atalho `themes` (`Super+T`; `Alt+T` no ambiente de desenvolvimento), `panels open themes` e "Trocar tema" no launcher. Nada muda em `ShellShortcuts`, `InputActions`, `InputState` nem `LauncherState`.
- Espera de **300 ms** entre o último giro e o `ThemeManager.apply` do card central; setas seguidas aplicam só o tema onde a fila parou.
- Aplicar sempre com o `ThemeManager.apply` de hoje, sem modo de prévia: cada tema aplicado grava o `Config` e troca o papel de parede com o crossfade completo (custo aceito pelo spec).
- Só setas (← →), Enter e Esc; sem scroll, sem Tab/Backtab, sem grade, sem "Mais ajustes"; sai `ThemeSwitcherState.openSettings`.
- `OverlayPanel` com `dim: 0`, sem caixa; degradê escuro só da borda de baixo até 40% da altura da tela.
- Fila centrada na horizontal, base do card central a **120 px** da borda de baixo; card central **320×180**, borda de **2 px** na cor de destaque do tema aplicado (`ThemeManager.colors.accent`); cada passo para o lado escala por **0,8**, apaga (saturação e brilho) e fica mais transparente; até **3** cards de cada lado, os demais invisíveis.
- Card: papel estático de `ThemeManager.wallpaperFor(id).static`, nome embaixo à esquerda, três bolinhas de cor à direita, nas cores do próprio tema; cantos arredondados e sombra; sem barrinha de cima e sem check.
- Girar: posição e escala com `Anim` do tipo `Spatial`; opacidade e apagamento com `Effects` (sem mola).
- Entrada em cascata do centro para fora, **40 ms** por grupo multiplicados por `ThemeManager.anim.scale`; saída com todos descendo juntos, mais rápida que a entrada.
- Camadas (`ci/rules.py`): `core/` não importa `qs.features` nem `qs.services`; `features/*/ui` não importa `qs.services`; uma feature não importa outra.
- Lint: `pragma ComponentBehavior: Bound` com `required property` nos delegates e ids qualificados; nenhuma supressão do qmllint; nenhum aviso aceito.
- Estilo compacto da casa (`Behavior on x { Anim { type: Anim.Spatial } }` numa linha); nada de `qmlformat`.
- Testes: prefira `t.eq`; `t.check(a === b)` só para identidade; restaure `Config`, `ThemeManager.themes` e `Panels.opened` no fim de cada caso; nada de hora real nem espera real; o runner já sai com `Qt.callLater(() => Qt.exit(n))`.
- Funções do escopo de cobertura declaradas como `function nome(...) {` numa linha; 100% delas chamadas pelos testes.
- Tudo em português do Brasil com acentos: comentários, textos, documentação e mensagens de commit.
- Conferência visual só no `lucerna-polish` (`dev/test.sh`); nunca mexer no container `lucerna-dev`.
- Empurrar e abrir PR só com a confirmação do usuário; conta do `gh` para este repositório: `EduardoSA8006`.

## Review Focus

1. **Fechar por outro caminho com a espera armada** (o atalho de novo, que faz `Panels.toggle`; outro painel modal; `panels close`): o esperado é desfazer como o Esc e a espera nunca aplicar um tema depois do seletor fechado. Teste na Tarefa 2 ("fechar por outro caminho também desfaz").
2. **Fila de 0, 1 ou 2 temas**: as setas não quebram nem aplicam nada à toa; com 2, a distância até o centro é estável (empate para a direita); vazia, o Enter só fecha. Testes nas Tarefas 1 ("distância até o centro") e 2 ("lista que muda com o seletor aberto").
3. **Tema da abertura fora da lista** (`Config.theme` aponta para um tema que não está em `ThemeManager.themes`): o esperado é centrar no primeiro card e o Esc voltar ao tema da abertura, não ao primeiro. Teste na Tarefa 2 ("tema da abertura fora da lista").
4. **Lista de temas trocada com o seletor aberto** (um arquivo novo em `themes/` dispara o `rebuildList`): o índice central continua dentro da lista, e os cards recriados aparecem já visíveis. Teste do índice na Tarefa 2 (mesmo caso do item 2); os cards visíveis vêm do `Component.onCompleted` do delegate na Tarefa 3.
5. **Enter sem girar e clique no card central durante a espera**: Enter sem giro não regrava o tema; clique no central com a espera armada aplica uma vez, o do centro, e fecha. Testes na Tarefa 2 ("Enter sem girar mantém o tema da abertura" e "clique num card lateral gira até ele; no central, confirma").

---

## Decisões

- **`wrap` e `offset` em `core/carousel/Carousel.qml`**: o `core/` entra sozinho no escopo do gate (`tests/coverage.json`, `"escopo": "core/"`), o harness já importa módulos `qs.core.*`, e tanto o `state` quanto a `ui` da feature podem importar o `core` sem ferir as camadas. Entra junto a `spread(d, size, gap, ratio)`, o deslocamento horizontal de cada card, para a tela não ter conta solta sem teste.
- **Espera sem relógio**: o estado expõe `pending` (o `Timer` armado) e `flush()` (aplica agora o card central, se ele não é o tema aplicado). O `flush()` não é só para teste: é o que o `confirm()` e o próprio `Timer` chamam. O teste gira, confere `pending` e o tema intacto, e chama `flush()`.
- **Teste do fluxo pelo caminho real**: o teste abre o seletor com `Panels.open("themes")`, e o estado reage ao `open` (`begin()` ao abrir, `finish()` ao fechar). Por isso qualquer fechamento que não seja o Enter desfaz, e o Esc (`cancel()`) só fecha. O runner passa a importar `qs.features.themeSwitcher.state` (o `ci/rules.py` não confere `tests/`, e o `ThemeSwitcherState` só lê o `Hypr` por propriedades, que não fazem nada sem Hyprland). O `ThemeSwitcherState` fica fora do gate de cobertura (o escopo é o `core/` e as funções puras de `services/`), mas o fluxo inteiro é testado.
- **Clique fora com o degradê na tela**: o `OverlayPanel` só dispensa quando o clique não cai em nenhum filho direto (`container.childAt`). A fila e o degradê ficam num `Item` sem tamanho (`stage`), que nunca contém o ponto; os cards têm `MouseArea` próprio e ficam com o clique deles.
- **Degradê e desfoque**: o degradê chega a no máximo 40% de opacidade, abaixo do `ignore_alpha = 0.45` da regra de desfoque do Hyprland; ele nunca é desfocado. A Tarefa 4 confere na tela se a camada sem escurecimento desfoca a tela inteira ou deixa faixas; se sim, o seletor deixa de pedir desfoque (`blur: false` no `OverlayPanel`, com o namespace `lucerna-themes`).
- **`ci/rules.py` fica como está**: não existe regra de papéis de cor. As linhas `ThemeCard.qml:80-88` e `ThemeSwitcher.qml:121` citadas pelo spec vêm da conferência do `pragma ComponentBehavior: Bound` do plano do CI (Tarefa 22, "papéis" do modelo nos delegates), que foi uma sonda, não uma regra. O código novo segue a mesma regra (delegates com `required property`), e a Tarefa 4 confirma que o `ci/rules.py` não cita esses arquivos.

## Arquivos

| Arquivo | O quê |
| --- | --- |
| `core/carousel/Carousel.qml` (novo) | singleton com `wrap`, `offset` e `spread` |
| `tests/carousel.test.js` (novo) | testes do `Carousel` |
| `features/themeSwitcher/state/ThemeSwitcherState.qml` | fluxo: `index`, `openedWith`, `pending`, `opened`, `step`, `pick`, `flush`, `confirm`, `cancel`, `Timer` de 300 ms; saem `openSettings`, `apply`, `close`, `current` e `currentIndex` |
| `tests/themeswitcher.test.js` (novo) | testes do fluxo |
| `tests/runner.qml` | imports, `suites` e os getters `Carousel` e `ThemeSwitcherState` |
| `features/themeSwitcher/ui/ThemeSwitcher.qml` | reescrito: carrossel sobre o `OverlayPanel` |
| `features/themeSwitcher/ui/ThemeCard.qml` | reescrito: card solto, com distância ao centro, entrada e saída |
| `core/widgets/OverlayPanel.qml` | só se a Tarefa 4 mostrar o desfoque na tela inteira: `blur` |
| `CONTRIBUTING.md` | uma linha: o `state` de uma feature pode vir em `t` |
| `README.md`, `Lucerna — Proposta.md`, `docs/screenshots/themes.jpg` | texto e captura do seletor novo |

---

### Tarefa 1: contas da fila circular no `core`

**Files:**
- Create: `core/carousel/Carousel.qml`
- Create: `tests/carousel.test.js`
- Modify: `tests/runner.qml` (imports, `suites`, `context()`)

**Interfaces:**
- Consumes: nada.
- Produces (singleton `Carousel`, `import qs.core.carousel`):
  - `wrap(i: int, n: int): int` — índice com volta em `[0, n)`; `n <= 0` dá `0`.
  - `offset(i: int, center: int, n: int): int` — distância com sinal do item `i` ao `center`, pelo caminho mais curto, em `(-n/2, n/2]` (empate de fila par vai para a direita); `n <= 0` dá `0`.
  - `spread(d: int, size: real, gap: real, ratio: real): real` — deslocamento horizontal do centro do card a `d` passos do centro da fila, com cada passo escalando por `ratio` e `gap` entre as bordas; sinal de `d`.
  - No runner: `t.Carousel`.

- [ ] **Passo 1: escrever o teste que falha**

`tests/carousel.test.js`:

```js
// Testes de core/carousel/Carousel: a volta do índice, a distância até o
// centro na fila circular e o deslocamento dos cards na tela.
function run(t) {
    const K = t.Carousel;

    t.test("carousel: volta do índice nos dois sentidos", () => {
        t.eq([K.wrap(0, 5), K.wrap(4, 5), K.wrap(5, 5), K.wrap(-1, 5), K.wrap(-6, 5), K.wrap(11, 5)], [0, 4, 0, 4, 4, 1]);
        t.eq([K.wrap(3, 1), K.wrap(-2, 1)], [0, 0], "fila de um");
        t.eq(K.wrap(2, 0), 0, "fila vazia");
    });

    t.test("carousel: distância até o centro pelo caminho mais curto", () => {
        t.eq([0, 1, 2, 3, 4].map(i => K.offset(i, 0, 5)), [0, 1, 2, -2, -1]);
        t.eq([0, 1, 2, 3, 4].map(i => K.offset(i, 4, 5)), [1, 2, -2, -1, 0], "centro no último");
        t.eq([K.offset(6, 0, 12), K.offset(7, 0, 12)], [6, -5], "empate em fila par vai para a direita");
        t.eq(K.offset(0, 0, 1), 0, "fila de um");
        t.eq([K.offset(1, 0, 2), K.offset(0, 1, 2)], [1, 1], "fila de dois: o outro fica sempre à direita");
        t.eq(K.offset(0, 0, 0), 0, "fila vazia");
    });

    t.test("carousel: deslocamento dos cards", () => {
        t.eq(K.spread(0, 320, 20, 0.8), 0);
        t.near(K.spread(1, 320, 20, 0.8), 308, 0.01, "metade do central, metade do vizinho e o vão");
        t.near(K.spread(-1, 320, 20, 0.8), -308, 0.01);
        t.near(K.spread(2, 320, 20, 0.8), 558.4, 0.01);
        t.near(K.spread(-3, 320, 20, 0.8), -762.72, 0.01);
    });
}
```

No `tests/runner.qml`, acrescentar o import do módulo (antes de `import qs.core.config`) e o do teste (antes de `import "clipboard.test.js" as ClipboardTest`):

```qml
import qs.core.carousel
```

```qml
import "carousel.test.js" as CarouselTest
```

Em `suites`, logo depois de `["format", FormatTest],`:

```qml
        ["carousel", CarouselTest],
```

Em `context()`, logo depois de `get Format() { return Format; },`:

```qml
            get Carousel() { return Carousel; },
```

- [ ] **Passo 2: rodar e ver falhar**

Run: `dev/ci.sh unit`
Expected: FAIL com "o runner não chegou ao fim (sem a linha RESULT; código 255 ...)": o módulo `qs.core.carousel` ainda não existe. Em `ci-out/unit/unit.log`, o erro do import.

- [ ] **Passo 3: implementar**

`core/carousel/Carousel.qml`:

```qml
pragma Singleton

import QtQuick
import Quickshell

// Contas da fila circular do seletor de temas: a volta do índice, a distância
// de um item até o centro pelo caminho mais curto e o deslocamento na tela.
Singleton {
    // Índice com volta: wrap(-1, 5) → 4, wrap(5, 5) → 0. Fila vazia dá 0.
    function wrap(i: int, n: int): int {
        return n > 0 ? ((i % n) + n) % n : 0;
    }

    // Distância com sinal do item i até o centro, pelo lado mais curto, entre
    // -n/2 (exclusive) e n/2; no empate (fila par), o lado direito.
    function offset(i: int, center: int, n: int): int {
        const d = wrap(i - center, n);
        return d > n / 2 ? d - n : d;
    }

    // Quanto o centro do item a d passos fica do centro da fila: cada passo
    // escala o item por ratio, com gap entre as bordas de um e do outro.
    function spread(d: int, size: real, gap: real, ratio: real): real {
        let x = 0;
        for (let k = 1; k <= Math.abs(d); k++)
            x += size / 2 * (Math.pow(ratio, k - 1) + Math.pow(ratio, k)) + gap;
        return d < 0 ? -x : x;
    }
}
```

- [ ] **Passo 4: rodar e ver passar**

Run: `dev/ci.sh unit && grep -E "SUITE carousel|RESULT|FAIL" ci-out/unit/unit.log`
Expected: `SUITE carousel casos=3`, `RESULT passed=N failed=0` e "unidade: ok (..., cobertura completa)" (as três funções do `Carousel` entram sozinhas no gate e são chamadas).

Run: `dev/ci.sh lint && python3 ci/rules.py`
Expected: lint sem avisos; "regras: nenhuma violação".

- [ ] **Passo 5: commit**

```bash
git add core/carousel/Carousel.qml tests/carousel.test.js tests/runner.qml
git commit -m "Carousel: contas da fila circular do seletor de temas"
```

---

### Tarefa 2: fluxo do seletor no estado

**Files:**
- Modify: `features/themeSwitcher/state/ThemeSwitcherState.qml:1-33` (cabeçalho e propriedades; a integração com o Hyprland, da linha 35 em diante, fica igual)
- Create: `tests/themeswitcher.test.js`
- Modify: `tests/runner.qml` (import, `suites`, `context()`)
- Modify: `CONTRIBUTING.md` (seção "Escrever um teste")

**Interfaces:**
- Consumes: `Carousel.wrap(i, n)` e `Carousel.offset(i, center, n)` da Tarefa 1.
- Produces (singleton `ThemeSwitcherState`, `import qs.features.themeSwitcher.state`):
  - `readonly property bool open`, `readonly property var screen`, `readonly property var themes` (como hoje);
  - `property int index` — o card central; `property string openedWith` — o id do tema aplicado ao abrir;
  - `readonly property bool pending` — a espera de 300 ms está armada;
  - `signal opened` — emitido ao abrir, depois de centrar a fila (a tela começa a cascata aqui);
  - `step(delta: int): void` — gira com volta e rearma a espera;
  - `pick(i: int): void` — clique num card: no central, `confirm()`; num lateral, `step` até ele;
  - `flush(): void` — para a espera e aplica o card central, se ele não é o tema aplicado;
  - `confirm(): void` — `flush()` e fecha mantendo;
  - `cancel(): void` — fecha; o fechamento (este ou qualquer outro que não seja o `confirm`) para a espera e volta ao `openedWith`.
  - Ficam por enquanto, para a tela antiga seguir compilando até a Tarefa 3: `current`, `currentIndex`, `apply(id)`, `close()` e `openSettings()`.
  - No runner: `t.ThemeSwitcherState`.

- [ ] **Passo 1: escrever o teste que falha**

`tests/themeswitcher.test.js`:

```js
// Testes do fluxo do seletor de temas (features/themeSwitcher/state): abrir,
// girar com a espera, confirmar e desfazer. A espera de 300 ms não corre
// aqui: `pending` diz se ela está armada e `flush()` a dispara na hora. Cada
// caso usa uma fila de três temas e devolve Config.theme, a lista de temas e
// os painéis abertos ao que eram. Fica por último no runner: trocar de tema
// anima as cores, e as outras suítes leem cores.
function run(t) {
    const S = t.ThemeSwitcherState;
    const T = t.ThemeManager;
    const C = t.Config;
    const P = t.Panels;
    const theme0 = C.theme;
    const themes0 = T.themes;
    const opened0 = P.opened;
    const three = [{ id: "catppuccin-mocha", name: "Catppuccin Mocha" }, { id: "dracula", name: "Dracula" }, { id: "nord", name: "Nord" }];

    // Aplica `id`, abre o seletor com a fila de três e roda o corpo; no fim,
    // mesmo com exceção, fecha e restaura.
    function scenario(name, id, body) {
        t.test(name, () => {
            T.themes = three;
            T.apply(id);
            P.open("themes");
            try {
                body();
            } finally {
                P.close();
                C.theme = theme0;
                T.themes = themes0;
                P.opened = opened0;
            }
        });
    }

    scenario("themeswitcher: abrir guarda o tema e centra a fila nele", "dracula", () => {
        t.eq([S.open, S.openedWith, S.index, S.pending], [true, "dracula", 1, false]);
    });

    scenario("themeswitcher: girar espera antes de aplicar e aplica só onde parou", "catppuccin-mocha", () => {
        S.step(1);
        t.eq([S.index, S.pending, T.current], [1, true, "catppuccin-mocha"], "a espera armada, nada aplicado");
        S.step(1);
        S.step(1);
        t.eq(S.index, 0, "depois do último vem o primeiro");
        S.step(-1);
        t.eq([S.index, T.current], [2, "catppuccin-mocha"], "antes do primeiro vem o último");
        S.flush();
        t.eq([S.pending, T.current, S.open], [false, "nord", true], "só o tema onde a fila parou");
    });

    scenario("themeswitcher: Enter aplica o que falta e mantém", "catppuccin-mocha", () => {
        S.step(1);
        S.confirm();
        t.eq([S.open, S.pending, T.current], [false, false, "dracula"]);
    });

    scenario("themeswitcher: Enter sem girar mantém o tema da abertura", "nord", () => {
        S.confirm();
        t.eq([S.open, T.current], [false, "nord"]);
    });

    scenario("themeswitcher: Esc para a espera e volta ao tema da abertura", "catppuccin-mocha", () => {
        S.step(1);
        S.flush();
        S.step(1);
        t.eq([T.current, S.pending], ["dracula", true]);
        S.cancel();
        t.eq([S.open, S.pending, T.current], [false, false, "catppuccin-mocha"]);
    });

    scenario("themeswitcher: fechar por outro caminho também desfaz", "catppuccin-mocha", () => {
        S.step(-1);
        S.flush();
        t.eq(T.current, "nord");
        P.open("launcher");
        t.eq([S.open, T.current], [false, "catppuccin-mocha"], "outro painel modal");
        P.open("themes");
        S.step(1);
        P.toggle("themes");
        t.eq([S.open, S.pending, T.current], [false, false, "catppuccin-mocha"], "o atalho de novo, com a espera armada");
    });

    scenario("themeswitcher: clique num card lateral gira até ele; no central, confirma", "catppuccin-mocha", () => {
        S.pick(2);
        t.eq([S.index, S.pending, T.current], [2, true, "catppuccin-mocha"], "gira pelo lado mais curto, com a espera");
        S.pick(2);
        t.eq([S.open, S.pending, T.current], [false, false, "nord"]);
    });

    scenario("themeswitcher: tema da abertura fora da lista", "gruvbox-dark", () => {
        t.eq([S.openedWith, S.index], ["gruvbox-dark", 0]);
        S.step(1);
        S.flush();
        t.eq(T.current, "dracula");
        S.cancel();
        t.eq(T.current, "gruvbox-dark");
    });

    scenario("themeswitcher: lista que muda com o seletor aberto", "nord", () => {
        t.eq(S.index, 2);
        T.themes = three.slice(0, 2);
        t.eq(S.index, 0, "o índice volta para dentro da lista");
        T.themes = [];
        S.step(1);
        t.eq([S.index, S.pending], [0, false], "fila vazia não gira");
        S.confirm();
        t.eq([S.open, T.current], [false, "nord"], "vazia, o Enter só fecha");
    });
}
```

No `tests/runner.qml`: o import do módulo, logo depois de `import qs.core.time`:

```qml
import qs.features.themeSwitcher.state
```

o do teste, logo depois de `import "theme.test.js" as ThemeTest`:

```qml
import "themeswitcher.test.js" as ThemeSwitcherTest
```

em `suites`, por último (trocar `["weather", WeatherTest]` por):

```qml
        ["weather", WeatherTest],
        ["themeswitcher", ThemeSwitcherTest]
```

e em `context()`, depois de `get Weather() { return Weather; }` (acrescentando a vírgula nele):

```qml
            get Weather() { return Weather; },
            get ThemeSwitcherState() { return ThemeSwitcherState; }
```

No `CONTRIBUTING.md`, trocar a linha

```md
- Os singletons vêm em `t` (`t.Format`, `t.Panels`, `t.Monitors`…); os enums
  usados nos testes, em `t.enums`.
```

por

```md
- Os singletons vêm em `t` (`t.Format`, `t.Panels`, `t.Monitors`…); os enums
  usados nos testes, em `t.enums`. O `state` de uma feature também pode vir,
  quando o teste é do fluxo dela (`t.ThemeSwitcherState`): o runner importa o
  módulo da feature, e o `rules` não confere `tests/`.
```

- [ ] **Passo 2: rodar e ver falhar**

Run: `dev/ci.sh unit; grep -E "SUITE themeswitcher|FAIL themeswitcher|RESULT" ci-out/unit/unit.log`
Expected: `SUITE themeswitcher casos=9`, vários `FAIL themeswitcher: ...` (por exemplo "exceção: TypeError: Property 'step' of object ... is not a function" e "esperado [true,\"dracula\",1,false], veio [true,null,...]") e `RESULT passed=N failed=M` com M > 0.

- [ ] **Passo 3: implementar**

Em `features/themeSwitcher/state/ThemeSwitcherState.qml`, trocar tudo do início do arquivo até o fim de `openSettings()` (linhas 1–33) por:

```qml
pragma Singleton

import QtQuick
import Quickshell
import qs.core.carousel
import qs.core.config
import qs.core.panels
import qs.core.theme
import qs.services

// View model do seletor de temas em carrossel. Ao abrir, guarda o tema
// aplicado (openedWith) e centra a fila nele. Girar (step) aplica o tema do
// card central depois de uma espera, para setas seguidas aplicarem só o
// último; confirm aplica o que faltar e fecha mantendo; qualquer outro
// fechamento (Esc, clique fora, o atalho de novo, outro painel) volta ao tema
// da abertura. Também mantém as bordas do Hyprland em sintonia com o tema
// ativo, inclusive na inicialização.
Singleton {
    id: root

    readonly property bool open: Panels.isOpen("themes")
    readonly property var screen: Hypr.focusedScreen
    readonly property var themes: ThemeManager.themes
    readonly property string current: ThemeManager.current
    readonly property int currentIndex: themes.findIndex(t => t.id === current)

    // O card central e o tema aplicado quando o seletor abriu.
    property int index: 0
    property string openedWith: ""
    // A espera está armada: o card central ainda não foi aplicado.
    readonly property bool pending: applyDelay.running
    // Ligado pelo confirm: o fechamento mantém o tema em vez de desfazer.
    property bool keep: false

    // A fila foi centrada ao abrir: a tela começa a cascata de entrada.
    signal opened

    onOpenChanged: {
        if (open)
            begin();
        else
            finish();
    }

    // Uma troca na lista (tema novo em themes/) não deixa o índice de fora.
    onThemesChanged: index = Carousel.wrap(index, themes.length)

    function begin(): void {
        openedWith = ThemeManager.current;
        index = Math.max(0, themes.findIndex(t => t.id === openedWith));
        keep = false;
        opened();
    }

    function finish(): void {
        applyDelay.stop();
        if (!keep && openedWith && ThemeManager.current !== openedWith)
            ThemeManager.apply(openedWith);
        keep = false;
    }

    function step(delta: int): void {
        if (!themes.length)
            return;
        index = Carousel.wrap(index + delta, themes.length);
        applyDelay.restart();
    }

    function pick(i: int): void {
        if (i === index)
            confirm();
        else
            step(Carousel.offset(i, index, themes.length));
    }

    function flush(): void {
        applyDelay.stop();
        const id = themes[index]?.id ?? "";
        if (id && id !== ThemeManager.current)
            ThemeManager.apply(id);
    }

    function confirm(): void {
        flush();
        keep = true;
        Panels.close();
    }

    function cancel(): void {
        Panels.close();
    }

    Timer {
        id: applyDelay

        interval: 300
        onTriggered: root.flush()
    }

    function apply(id: string): void {
        ThemeManager.apply(id);
    }

    function close(): void {
        Panels.close();
    }

    // Leva à tela de configurações, na parte de aparência.
    function openSettings(): void {
        Config.settingsTopic = "appearance";
        Panels.open("settings");
    }
```

O resto do arquivo (`// Integração com o Hyprland` em diante) não muda.

- [ ] **Passo 4: rodar e ver passar**

Run: `dev/ci.sh unit && grep -E "SUITE themeswitcher|RESULT|FAIL" ci-out/unit/unit.log`
Expected: `SUITE themeswitcher casos=9`, nenhum `FAIL`, `RESULT passed=N failed=0` e "unidade: ok (..., cobertura completa)".

Run: `dev/ci.sh lint && python3 ci/rules.py`
Expected: lint sem avisos (a tela antiga ainda usa `current`, `currentIndex`, `apply`, `close` e `openSettings`, que ficaram); "regras: nenhuma violação".

- [ ] **Passo 5: commit**

```bash
git add features/themeSwitcher/state/ThemeSwitcherState.qml tests/themeswitcher.test.js tests/runner.qml CONTRIBUTING.md
git commit -m "Seletor de temas: girar com espera, confirmar e desfazer no estado"
```

---

### Tarefa 3: a tela do carrossel

**Files:**
- Modify (reescrito): `features/themeSwitcher/ui/ThemeCard.qml`
- Modify (reescrito): `features/themeSwitcher/ui/ThemeSwitcher.qml`
- Modify: `features/themeSwitcher/state/ThemeSwitcherState.qml` (saem `current`, `currentIndex`, `apply`, `close`, `openSettings` e o `import qs.core.config`)

**Interfaces:**
- Consumes: `Carousel.offset` e `Carousel.spread` (Tarefa 1); `ThemeSwitcherState.open`, `screen`, `themes`, `index`, `opened`, `step`, `pick`, `confirm`, `cancel` (Tarefa 2).
- Produces: `ThemeCard { required property var theme; required property int distance; property real shown; signal clicked; function enter(): void; function leave(): void }`. Nada fora da feature depende dele.

- [ ] **Passo 1: reescrever o card**

`features/themeSwitcher/ui/ThemeCard.qml`:

```qml
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.core.theme
import qs.core.widgets

// Um tema na fila do seletor: o papel de parede estático (com a escolha do
// usuário para aquele tema), o nome e três amostras de cor, nas cores do
// próprio tema. `distance` é quantos passos o card está do centro, com sinal:
// cada passo encolhe 20%, apaga e deixa mais transparente; depois do
// terceiro, some. O central ganha a borda na cor de destaque do tema ativo.
Item {
    id: card

    required property var theme
    required property int distance
    // Entrada e saída (0 → 1), animadas por enter() e leave().
    property real shown: 0
    readonly property var c: theme.colors ?? ({})
    readonly property int reach: Math.abs(distance)
    readonly property string still: ThemeManager.wallpaperFor(theme.id).static
    // Quanto o card apaga: 0 no centro, 1 no terceiro passo.
    property real dimness: Math.min(reach, 3) / 3

    signal clicked

    width: 320
    height: 180
    z: -reach
    scale: Math.pow(0.8, reach)
    opacity: Math.min(1, shown)
    visible: shown > 0 && effect.opacity > 0
    // Sobe da borda de baixo na entrada e desce na saída.
    transform: Translate { y: (1 - card.shown) * 240 }

    // Sem animar enquanto escondido: ao abrir, a fila já está no lugar.
    Behavior on x { enabled: card.shown > 0; Anim { type: Anim.Spatial } }
    Behavior on scale { enabled: card.shown > 0; Anim { type: Anim.Spatial } }
    Behavior on dimness { enabled: card.shown > 0; Anim { type: Anim.Effects } }

    function enter(): void {
        leaving.stop();
        shown = 0;
        entering.restart();
    }

    function leave(): void {
        entering.stop();
        leaving.restart();
    }

    // Cascata do centro para fora: 40 ms por passo, na escala de animação.
    SequentialAnimation {
        id: entering

        PauseAnimation { duration: card.reach * 40 * ThemeManager.anim.scale }
        Anim { target: card; property: "shown"; to: 1; type: Anim.Spatial }
    }

    Anim {
        id: leaving

        target: card
        property: "shown"
        to: 0
        type: Anim.StandardAccel
    }

    Item {
        id: body

        anchors.fill: parent
        visible: false
        layer.enabled: true

        ClippingRectangle {
            anchors.fill: parent
            radius: ThemeManager.radius.large
            color: card.c.base ?? "black"
            border.width: ThemeManager.outlines ? 1 : 0
            border.color: card.c.border ?? "gray"

            Image {
                anchors.fill: parent
                source: card.still ? `file://${card.still}` : ""
                sourceSize: Qt.size(640, 360)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            // Véu na base do card, para o nome e as cores lerem sobre o papel.
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 64
                gradient: Gradient {
                    GradientStop { position: 0; color: ThemeManager.alpha(card.c.base ?? "black", 0) }
                    GradientStop { position: 1; color: ThemeManager.alpha(card.c.base ?? "black", 0.85) }
                }
            }

            Text {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: ThemeManager.spacing.normal
                text: card.theme.name
                color: card.c.text ?? "white"
                font.family: ThemeManager.font.sans
                font.pixelSize: ThemeManager.font.normal
                font.weight: Font.DemiBold
            }

            Row {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: ThemeManager.spacing.normal
                anchors.bottomMargin: ThemeManager.spacing.normal + 2
                spacing: 4

                Repeater {
                    model: ["raised", "text", "accent"]

                    delegate: Rectangle {
                        required property string modelData

                        width: 12
                        height: 12
                        radius: 6
                        color: card.c[modelData] ?? "gray"
                        border.width: 1
                        border.color: card.c.border ?? "gray"
                    }
                }
            }
        }

        // Borda do card central, por cima do papel de parede.
        Rectangle {
            anchors.fill: parent
            radius: ThemeManager.radius.large
            color: "transparent"
            border.width: 2
            border.color: ThemeManager.colors.accent
            opacity: card.reach === 0 ? 1 : 0

            Behavior on opacity { Anim { type: Anim.Effects } }
        }
    }

    // Apagado (saturação e brilho), transparência e sombra.
    MultiEffect {
        id: effect

        anchors.fill: body
        source: body
        opacity: card.reach > 3 ? 0 : 1 - 0.6 * card.dimness
        saturation: -0.7 * card.dimness
        brightness: -0.35 * card.dimness
        shadowEnabled: true
        shadowColor: "#000000"
        shadowOpacity: 0.45
        shadowBlur: 0.8
        shadowVerticalOffset: 6

        Behavior on opacity { enabled: card.shown > 0; Anim { type: Anim.Effects } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: card.clicked()
    }
}
```

- [ ] **Passo 2: reescrever o painel**

`features/themeSwitcher/ui/ThemeSwitcher.qml`:

```qml
pragma ComponentBehavior: Bound

import QtQuick
import qs.core.carousel
import qs.core.theme
import qs.core.widgets
import qs.features.themeSwitcher.state

// Seletor de temas em carrossel, solto na parte de baixo da tela, sem caixa e
// sem escurecer o resto: só um degradê escuro atrás da fila. ← e → giram a
// fila (o ThemeSwitcherState aplica o tema do centro depois da espera), Enter
// mantém, Esc ou clique fora desfaz. Clicar num card lateral gira até ele; no
// central, é o Enter.
OverlayPanel {
    id: panel

    name: "themes"
    open: ThemeSwitcherState.open
    screen: ThemeSwitcherState.screen
    dim: 0
    onDismissed: ThemeSwitcherState.cancel()

    // Centro vertical da fila: a base do card central a 120 px da borda de baixo.
    readonly property real rowY: height - 120 - 180 / 2

    // Entrada em cascata, depois de o estado centrar a fila.
    Connections {
        target: ThemeSwitcherState

        function onOpened() {
            stage.forceActiveFocus();
            for (let i = 0; i < cards.count; i++)
                (cards.itemAt(i) as ThemeCard)?.enter();
        }
    }

    // Saída: todos descem juntos.
    onOpenChanged: {
        if (!open) {
            for (let i = 0; i < cards.count; i++)
                (cards.itemAt(i) as ThemeCard)?.leave();
        }
    }

    // Sem tamanho: o OverlayPanel fecha no clique que não cai em nenhum filho
    // dele (childAt), e assim o degradê não segura o clique fora. Os cards,
    // com o próprio MouseArea, ficam com o clique deles.
    Item {
        id: stage

        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Left)
                ThemeSwitcherState.step(-1);
            else if (event.key === Qt.Key_Right)
                ThemeSwitcherState.step(1);
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                ThemeSwitcherState.confirm();
            else
                return;
            event.accepted = true;
        }

        // Degradê só atrás da fila, subindo até 40% da altura. No máximo 40%
        // de opacidade: abaixo do ignore_alpha (0,45) da regra de desfoque do
        // Hyprland (ThemeSwitcherState.blurLua), então nunca é desfocado.
        Rectangle {
            y: panel.height * 0.6
            width: panel.width
            height: panel.height * 0.4
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: ThemeManager.alpha("#000000", 0.4) }
            }
        }

        Repeater {
            id: cards

            model: ThemeSwitcherState.themes

            delegate: ThemeCard {
                id: tile

                required property var modelData
                required property int index

                theme: tile.modelData
                distance: Carousel.offset(tile.index, ThemeSwitcherState.index, ThemeSwitcherState.themes.length)
                x: panel.width / 2 + Carousel.spread(tile.distance, tile.width, ThemeManager.spacing.large, 0.8) - tile.width / 2
                y: panel.rowY - tile.height / 2
                onClicked: ThemeSwitcherState.pick(tile.index)
                // A lista trocada com o seletor aberto recria os cards: já visíveis.
                Component.onCompleted: {
                    if (panel.open)
                        tile.shown = 1;
                }
            }
        }
    }
}
```

- [ ] **Passo 3: tirar do estado o que era da grade**

Em `features/themeSwitcher/state/ThemeSwitcherState.qml`, apagar a linha `import qs.core.config`, as duas propriedades

```qml
    readonly property string current: ThemeManager.current
    readonly property int currentIndex: themes.findIndex(t => t.id === current)
```

e o bloco logo depois do `Timer { id: applyDelay ... }`:

```qml
    function apply(id: string): void {
        ThemeManager.apply(id);
    }

    function close(): void {
        Panels.close();
    }

    // Leva à tela de configurações, na parte de aparência.
    function openSettings(): void {
        Config.settingsTopic = "appearance";
        Panels.open("settings");
    }
```

Run: `grep -rn "ThemeSwitcherState\.\(apply\|close\|current\|currentIndex\|openSettings\)" features core shell.qml`
Expected: nenhuma linha.

- [ ] **Passo 4: lint, unidade e fumaça**

Run: `dev/ci.sh lint unit smoke && python3 ci/rules.py`
Expected: os três checks passam (lint sem avisos; `SUITE themeswitcher casos=9` e `SUITE carousel casos=3` com `failed=0` e cobertura completa; fumaça sem avisos novos no passo `themes`); "regras: nenhuma violação". A captura da fumaça do passo `themes` fica em `ci-out/smoke/`.

- [ ] **Passo 5: conferência na tela com o teclado**

Os temas, em ordem na fila: Catppuccin Mocha (o padrão, primeiro), depois por nome: Catppuccin Latte, Decay Green, Dracula, Everforest, Gruvbox Dark, Kanagawa, Matte Black, Nord, Rosé Pine, Rosé Pine Dawn, Tokyo Night. As teclas vão pelo `wtype` do container (`dev/test.sh run`), que chega à camada com o teclado exclusivo do seletor.

```bash
dev/test.sh up
dev/test.sh ipc theme set catppuccin-mocha
dev/test.sh errs
dev/test.sh see carrossel panels open themes
```

Expected: `errs` sem avisos do seletor; `/tmp/lucerna-test/carrossel-panels-open-themes.png` (1920×1080, ver com o Read) mostra a fila embaixo, sem caixa e sem escurecer o topo da tela; o card central com uns 320×180, de x≈800 a 1120 e y≈780 a 960, com a borda de destaque; três cards menores e mais apagados de cada lado; o degradê só na parte de baixo.

```bash
dev/test.sh ipc panels open themes; sleep 1
dev/test.sh run 'wtype -k Right; qs -c lucerna ipc call theme get; sleep 0.6; qs -c lucerna ipc call theme get'
dev/test.sh shot carrossel-direita
```

Expected: `catppuccin-mocha` e depois `catppuccin-latte` (a espera, depois o tema aplicado); a captura com o shell inteiro no Latte e a fila girada.

```bash
dev/test.sh run 'wtype -k Left -k Left; for i in 1 2 3 4 5 6 7 8; do qs -c lucerna ipc call theme get; sleep 0.1; done'
```

Expected: `catppuccin-latte` nas primeiras linhas e depois só `tokyo-night` (a fila passou pelo Mocha e deu a volta); `catppuccin-mocha` não aparece: setas seguidas aplicam só o último.

```bash
dev/test.sh run 'wtype -k Escape'; sleep 1
dev/test.sh ipc theme get; dev/test.sh ipc panels get
```

Expected: `catppuccin-mocha` (o tema da abertura) e nenhum painel aberto.

```bash
dev/test.sh ipc panels open themes; sleep 1
dev/test.sh run 'wtype -k Right -k Return; qs -c lucerna ipc call theme get; qs -c lucerna ipc call panels get'
dev/test.sh ipc theme set catppuccin-mocha
```

Expected: `catppuccin-latte` na hora (o Enter não espera) e nenhum painel aberto.

```bash
dev/test.sh setc "dict(animationScale=5)"
dev/test.sh ipc panels open themes; dev/test.sh shot carrossel-cascata
sleep 3; dev/test.sh ipc panels close; dev/test.sh setc "dict(animationScale=-1)"
dev/test.sh errs
```

Expected: `carrossel-cascata.png` pega a entrada no meio, com o central mais alto que os vizinhos e os de fora ainda embaixo ou invisíveis; `errs` sem avisos nem erros novos.

Se alguma captura não bater, corrigir antes do commit. O mouse (clique no lateral, no central e fora) fica para o usuário conferir, como diz o spec.

- [ ] **Passo 6: commit**

```bash
git add features/themeSwitcher/ui/ThemeCard.qml features/themeSwitcher/ui/ThemeSwitcher.qml features/themeSwitcher/state/ThemeSwitcherState.qml
git commit -m "Seletor de temas em carrossel: fila solta embaixo, com prévia ao vivo e entrada em cascata"
```

---

### Tarefa 4: desfoque, captura e documentação

**Files:**
- Modify (só se o critério do Passo 1 mandar): `core/widgets/OverlayPanel.qml:20-21,50-51`, `features/themeSwitcher/ui/ThemeSwitcher.qml` (propriedade `blur`)
- Modify: `docs/screenshots/themes.jpg`
- Modify: `README.md:51,53,115`
- Modify: `Lucerna — Proposta.md:35,42,47,70`

**Interfaces:**
- Consumes: a tela da Tarefa 3.
- Produces: se o desfoque for desligado, `OverlayPanel { property bool blur: true }`, com namespace `lucerna-panel-<name>` quando `blur` e `lucerna-<name>` quando não.

- [ ] **Passo 1: conferir o desfoque da camada sem escurecimento**

O desfoque vem de `hl.layer_rule({ match = { namespace = "^lucerna-panel-.*" }, blur = true, ignore_alpha = 0.45 })` (`ThemeSwitcherState.blurLua`) e só vale com a transparência do tema ligada (o Catppuccin Mocha liga).

```bash
dev/test.sh ipc theme set catppuccin-mocha
dev/test.sh setc "dict(transparencyOverride=None, blurOverride=None)"
dev/test.sh ipc panels close; sleep 1; dev/test.sh shot desfoque-fechado
dev/test.sh ipc panels open themes; sleep 1.5; dev/test.sh shot desfoque-aberto; dev/test.sh ipc panels close
python3 - <<'EOF'
from PIL import Image, ImageFilter, ImageStat
def edges(name, box):
    im = Image.open(f"/tmp/lucerna-test/{name}.png").convert("L").crop(box)
    return ImageStat.Stat(im.filter(ImageFilter.FIND_EDGES)).mean[0]
# Abaixo da barra e acima do degradê: nada do seletor desenha aí.
top = (0, 80, 1920, 600)
a, f = edges("desfoque-aberto", top), edges("desfoque-fechado", top)
print(f"bordas no topo: aberto {a:.2f}, fechado {f:.2f}, razão {a / f:.2f}")
EOF
```

Critério: **desfocou** se a razão ficar abaixo de 0,8, ou se, vendo `desfoque-aberto.png` com o Read, aparecer uma faixa desfocada de borda dura no degradê ou um salto de desfoque atrás dos cards laterais. Com razão de 0,9 ou mais e sem faixa, o desfoque não atrapalha: pular para o Passo 3 sem mexer no código.

- [ ] **Passo 2 (só se desfocou): o seletor deixa de pedir desfoque**

Em `core/widgets/OverlayPanel.qml`, depois de `property string name: "panel"`:

```qml
    // Pede o desfoque do Hyprland atrás da camada. Falso num painel sem fundo
    // próprio (o seletor de temas), em que ele pegaria a tela inteira.
    property bool blur: true
```

e trocar

```qml
    // "lucerna-panel-*" recebe o desfoque do Hyprland (ver ThemeSwitcherState).
    WlrLayershell.namespace: `lucerna-panel-${name}`
```

por

```qml
    // "lucerna-panel-*" recebe o desfoque do Hyprland (ver ThemeSwitcherState);
    // sem blur, o namespace foge da regra.
    WlrLayershell.namespace: blur ? `lucerna-panel-${name}` : `lucerna-${name}`
```

Em `features/themeSwitcher/ui/ThemeSwitcher.qml`, depois de `dim: 0`:

```qml
    blur: false
```

Nada mais usa o namespace `lucerna-panel-themes` (`grep -rn "lucerna-panel-themes" --exclude-dir=.git .` só acha o spec e este plano). Rodar de novo o Passo 1: a razão precisa ficar em 0,9 ou mais, sem faixa. Depois, `dev/ci.sh lint smoke`: passam.

- [ ] **Passo 3: a captura do README**

```bash
dev/test.sh ipc theme set catppuccin-mocha
dev/test.sh ipc panels open themes; sleep 1.5; dev/test.sh shot themes-carrossel; dev/test.sh ipc panels close
magick /tmp/lucerna-test/themes-carrossel.png -resize 1600x900 -quality 90 docs/screenshots/themes.jpg
magick identify -format "%wx%h %Q\n" docs/screenshots/themes.jpg
```

Expected: `1600x900 90`, como as outras capturas; ver com o Read que a fila está inteira e nítida.

- [ ] **Passo 4: README e Proposta**

`README.md`, linha 51: trocar `| Seletor de temas | Launcher compacto |` por

```md
| Seletor de temas em carrossel | Launcher compacto |
```

linha 53: trocar `![Seletor de temas](docs/screenshots/themes.jpg)` por `![Seletor de temas em carrossel](docs/screenshots/themes.jpg)`.

Linha 115, no fim da linha **Temas**, trocar `Trocam ao vivo. |` por

```md
Trocam ao vivo pelo seletor em carrossel (`Super+T`): as setas aplicam o tema do card central, Enter mantém e Esc desfaz. |
```

`Lucerna — Proposta.md`:

- linha 35: trocar `trocáveis a qualquer momento por um painel de seleção rápida.` por `trocáveis a qualquer momento por um seletor em carrossel.`;
- linha 42: trocar a linha inteira (`- **Troca ao vivo:** ao escolher um tema no painel, ...`) por

```md
- **Troca ao vivo:** no seletor em carrossel, as setas giram a fila e o tema do card central é aplicado de verdade em toda a interface, com transição suave, depois de uma espera curta (setas seguidas aplicam só o último). Enter mantém a escolha, que fica salva para a próxima sessão; Esc ou clique fora voltam ao tema de antes.
```

- linha 47: trocar `Seleções (launcher, menu de energia, temas, abas) são um destaque único que desliza com mola até o item escolhido.` por `Seleções (launcher, menu de energia, abas) são um destaque único que desliza com mola até o item escolhido; no seletor de temas, é a fila que gira com mola.`;
- linha 70: trocar a linha inteira por

```md
| Seletor de temas | Carrossel na parte de baixo da tela: as setas aplicam o tema do card central ao vivo, Enter mantém e Esc desfaz |
```

- [ ] **Passo 5: `ci/rules.py` e as regras**

Run: `grep -n "ThemeCard\|ThemeSwitcher" ci/rules.py ci/tests/test_rules.py; python3 ci/rules.py`
Expected: nenhuma linha do `grep` (não há exceção de papéis de cor a mover; ver "Decisões") e "regras: nenhuma violação" (acentos, espaços e links dos `.md` alterados em dia).

- [ ] **Passo 6: CI completo e commit**

Run: `dev/ci.sh`
Expected: `lint`, `rules`, `unit` e `smoke` passam.

```bash
git add README.md "Lucerna — Proposta.md" docs/screenshots/themes.jpg
git add core/widgets/OverlayPanel.qml features/themeSwitcher/ui/ThemeSwitcher.qml   # só se o Passo 2 rodou
git commit -m "Seletor de temas em carrossel: captura, README e Proposta"
```
