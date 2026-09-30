# Seletor de temas em carrossel

**Data:** 2026-09-30
**Feature:** `features/themeSwitcher/`

## Objetivo

Trocar a grade de cards dentro de um painel por um carrossel de cards soltos na tela. As setas giram a fila, o tema do card central é aplicado de verdade enquanto você escolhe, o Enter mantém e o Esc desfaz.

Decisões do usuário, na conversa de desenho:

- prévia ao vivo: girar aplica o tema no shell inteiro;
- só setas e Enter (sem scroll, sem Tab, sem grade);
- aplicar de verdade com o `ThemeManager.apply` de hoje, sem modo de prévia; o custo de cada troca fica como está até as configurações do tema serem simplificadas, em outro trabalho;
- fila plana, sem a barrinha de cima do card;
- tudo dentro do card: papel de parede, nome e cores;
- fila na parte de baixo da tela, com degradê escuro só ali;
- entrada em cascata;
- o "Mais ajustes" sai do seletor (os ajustes ficam nas Configurações).

## Comportamento

- **Abrir:** igual a hoje, pelo atalho `themes` (`Super+T`; `Alt+T` no ambiente de desenvolvimento), por `panels open themes` e por "Trocar tema" no launcher. Ao abrir, o seletor guarda o id do tema aplicado (o tema da abertura), e o card central é esse tema.
- **← e →:** giram a fila um card por vez, com volta (depois do último vem o primeiro, e vice-versa). Cada giro reinicia uma espera de 300 ms; ao fim dela, o tema do card central é aplicado com `ThemeManager.apply`. Setas seguidas aplicam só o tema onde a fila parou.
- **Enter:** se o tema central ainda não foi aplicado (espera correndo), aplica na hora; depois fecha, mantendo o tema.
- **Esc ou clique fora:** para a espera; se o tema aplicado não é o da abertura, aplica o da abertura; depois fecha.
- **Mouse:** clicar num card lateral gira a fila até ele (mesmo caminho das setas, com a espera); clicar no card central equivale ao Enter.
- **Saem:** a grade, o scroll, o Tab/Backtab, o "Mais ajustes" e o `ThemeSwitcherState.openSettings`.
- **Custo aceito:** cada tema aplicado grava o `Config` e troca o papel de parede com o crossfade completo, como o clique de hoje. A espera evita que uma sequência rápida de setas aplique os temas do meio.

## Visual

- **Fundo:** sem caixa e sem o escurecimento da tela inteira (`OverlayPanel` com `dim: 0`). Só um degradê escuro que sobe da borda de baixo até uns 40% da altura da tela; o resto da tela mostra o tema aplicado.
- **Fila:** centrada na horizontal, com a base do card central a 120 px da borda de baixo da tela. Card central de 320×180 (16:9), com borda de 2 px na cor de destaque do tema aplicado. Cada passo para o lado reduz a escala em 20% (1, 0,8, 0,64…), apaga (menos saturação e brilho) e aumenta a transparência; aparecem até 3 cards de cada lado, e os demais ficam invisíveis.
- **Card:** o papel de parede estático do tema (`ThemeManager.wallpaperFor(id).static`, que respeita a escolha do usuário por tema), o nome embaixo à esquerda e as três bolinhas de cor à direita, nas cores do próprio tema; cantos arredondados e sombra. Sem a barrinha de cima e sem o check.
- **Girar:** posição e escala animadas com `Anim` do tipo Spatial (com mola); opacidade e brilho com uma curva sem mola (Effects ou Standard), para não passar do ponto.
- **Entrada:** ao abrir, os cards sobem da borda de baixo e aparecem em cascata, do centro para fora (o central primeiro, depois os de distância 1, depois 2…), com uns 40 ms entre um grupo e o seguinte, multiplicados pela escala de animação do `ThemeManager`.
- **Saída:** todos descem juntos e somem, mais rápido que a entrada.

## Estrutura

A feature segue o padrão da casa: lógica em `state/`, tela em `ui/`.

- **`features/themeSwitcher/state/ThemeSwitcherState.qml`:**
  - `index` (o card central) e `openedWith` (o id do tema da abertura), preenchidos quando o painel abre;
  - `step(delta)`: gira com volta e reinicia a espera;
  - `confirm()`: aplica na hora, se faltar, e fecha;
  - `cancel()`: para a espera, reaplica `openedWith` se o aplicado for outro, e fecha;
  - um `Timer` de 300 ms que chama `ThemeManager.apply` com o id do card central;
  - sai `openSettings`.
- **Funções puras** (com teste de unidade): a volta do índice (`wrap(i, n)`) e a distância com sinal de um card até o centro, pelo caminho mais curto na fila circular (`offset(i, centro, n)`). Ficam onde o harness de `tests/` alcança; se precisar, num arquivo de `core/`.
- **`features/themeSwitcher/ui/ThemeSwitcher.qml`** (reescrito): `OverlayPanel` com `dim: 0`; o degradê; um `Repeater` que posiciona cada card pela `offset`; setas e Enter em `Keys.onPressed`; `onDismissed` chama `cancel()`.
- **`features/themeSwitcher/ui/ThemeCard.qml`:** sem a barrinha e sem o check; ganha a borda de destaque quando é o central.
- **A conferir na implementação:** se o blur do Hyprland no namespace `lucerna-panel-themes` desfoca a tela inteira quando não há escurecimento; se sim, o seletor passa a não pedir blur nessa camada.

## O que mais muda

- `ci/rules.py`: as exceções da regra de papéis de cor que apontam linhas de `ThemeCard.qml` e `ThemeSwitcher.qml` passam a apontar as linhas novas (ou saem, se o código novo não precisar delas).
- `README.md`: o texto do seletor e a captura `docs/screenshots/themes.jpg`.
- `Lucerna — Proposta.md`: as menções ao seletor.
- O roteiro do `dev/test.sh` e a fumaça (`ci/smoke.sh`) continuam abrindo `panels open themes`; nada muda neles além do que a tela nova exigir.

## Testes

- **Unidade:** `wrap` e `offset` (volta nos dois sentidos, fila de 1 e de 2 temas, distância pelo caminho mais curto); o fluxo `step`/`confirm`/`cancel` no estado, com a espera controlada no teste e o tema original restaurado no fim da suíte, como as demais.
- **Fumaça:** `panels open themes` sem avisos novos.
- **Conferência na tela** (`dev/test.sh`): abrir; girar para os dois lados e ver o tema aplicado depois da espera; várias setas seguidas aplicando só o último; Enter mantendo; Esc voltando ao tema da abertura; a cascata de entrada.
- **Com o mouse (usuário):** clique num card lateral e no central; clique fora desfazendo.

## Fora do escopo

- Modo de prévia sem gravar no `ThemeManager` e redução do custo de aplicar um tema: ficam para quando as configurações do tema forem simplificadas.
- Scroll, navegação por Tab e o "Mais ajustes" no seletor.
