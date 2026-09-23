# Lucerna — Proposta do Wallpaper

Sep 23, 2026 · @Eduardo Alves

> Implementação futura. Hoje a feature de wallpaper mostra só a imagem estática do tema ativo, com transição suave na troca de tema. Este documento descreve a evolução para wallpapers animados.

## Visão geral

A feature de wallpaper do Lucerna suporta papéis de parede estáticos e animados, com troca entre eles a qualquer momento. O animado é projetado para consumir o mínimo possível: só é desenhado quando está visível e, quando desenhado, faz o menor trabalho que mantém o efeito.

O princípio é simples: o quadro mais barato é o que não precisa ser desenhado. Quando a animação para, o último quadro fica congelado na tela e o consumo de GPU cai para praticamente zero, porque o Qt Quick só redesenha uma janela quando algo nela muda.

## Tipos de wallpaper

São dois tipos, e o animado é feito com shaders por ser o formato mais leve.

| Tipo | Formato | Custo | Uso |
| --- | --- | --- | --- |
| Estático | Imagem (PNG, JPG, WebP) | Carregado uma vez; zero após exibido | Padrão e modo de economia |
| Animado | Shader GLSL compilado (`.qsb`), desenhado por `ShaderEffect` | Baixo, na GPU, só enquanto visível | Efeitos ambientes ligados ao tema |

Todo wallpaper animado tem uma imagem estática equivalente, usada como fallback e como quadro inicial. A troca é instantânea e nunca mostra tela vazia: a imagem aparece primeiro, e o shader surge por cima dela quando fica pronto.

### Modos

O tema diz **o que** está disponível (imagem e, opcionalmente, shader). O usuário escolhe **como** exibir, com um modo por monitor:

| Modo | Comportamento |
| --- | --- |
| `auto` (padrão) | Animado quando o tema tem shader e as regras de pausa permitem; estático caso contrário |
| `animated` | Sempre animado quando visível; ainda respeita as regras de pausa |
| `static` | Sempre a imagem estática |

O modo pode ser trocado de três formas:

- **Pelo painel de temas:** um controle no seletor. O `themeSwitcher` grava o modo em `core/config/Config.qml`, e a feature de wallpaper reage à mudança. Uma feature não importa a outra; a comunicação passa pela config.
- **Por um atalho do Hyprland**, via IPC: `qs -c lucerna ipc call wallpaper mode animated` (também `static`, `auto` e `toggle`). Sem monitor, vale para o monitor com foco; `wallpaper modeFor HDMI-A-1 static` escolhe um específico.
- **Automaticamente**, pelas regras de economia abaixo.

### Por monitor

Cada tela pode ter um modo e um wallpaper próprios. As escolhas ficam salvas em `Config.qml`, pelo nome do conector (como `eDP-1`):

```json
"wallpaper": {
    "monitors": {
        "eDP-1": { "mode": "static" },
        "HDMI-A-1": { "mode": "animated", "source": "brasa" }
    }
}
```

- `mode`: o modo daquele monitor. Sem entrada, vale `auto`.
- `source`: opcional. É o id de outro tema, cujo wallpaper (imagem e shader) aquele monitor usa no lugar do wallpaper do tema ativo. Sem `source`, o monitor segue o tema ativo.

Mesmo com `source`, as cores do shader vêm do tema ativo, para o efeito combinar com o resto da interface. O wallpaper continua sendo dado de tema: um monitor pode pegar emprestado o wallpaper de outro tema, mas não aponta para um arquivo solto.

## Regras de pausa

A animação para sempre que o wallpaper não estiver visível. Cada monitor decide sozinho: um app em tela cheia em uma tela não pausa a outra.

| Condição | Fonte do sinal | Ação |
| --- | --- | --- |
| App em tela cheia no monitor | `services/Hypr.qml`: `hasFullscreen` do workspace ativo do monitor | Pausa |
| Tela bloqueada | `services/Session.qml`: `locked` | Pausa |
| Monitor apagado (DPMS) | `services/Hypr.qml`: `dpmsStatus` dos dados do monitor | Pausa |
| Fora da tomada | `services/Battery.qml`: `onBattery` | Troca para o estático equivalente |
| Modo estrito: qualquer janela no workspace | `services/Hypr.qml`: janelas do workspace ativo do monitor | Pausa (opcional) |

- **Monitor desativado ou desconectado:** não precisa de regra. A tela some de `Quickshell.screens`, e o `Variants` destrói a janela do wallpaper daquele monitor.
- **Tela bloqueada:** o sinal vem de `services/Session.qml`, e não da feature `lockscreen`, porque uma feature não importa outra.
- **DPMS:** o Quickshell não tem uma propriedade própria para DPMS; o `Hypr.qml` lê `dpmsStatus` de `lastIpcObject` do monitor e pede `refreshMonitors()` quando o Hyprland avisa de mudança. Qual evento do Hyprland 0.56 sinaliza DPMS precisa ser confirmado na implementação.
- **Fora da tomada:** vale só no modo `auto`. No modo `animated`, o usuário pediu animação explicitamente.
- **Modo estrito:** desligado por padrão e configurável em `Config.qml`. Com gaps, sobra um pouco de wallpaper visível nas bordas, então ele troca esse detalhe visual por economia máxima.

Ao retomar, a animação continua de onde parou, sem saltos: o tempo do shader só avança enquanto ele está rodando.

## Otimização do animado

Quando visível, o animado faz o menor trabalho que mantém o efeito.

- **Taxa de quadros limitada:** 30 fps por padrão, e o tema pode pedir menos (por exemplo, 20). O tempo do shader (`uniform float time`) é avançado por um `Timer` com intervalo de `1000 / fps`, em vez de uma animação do Qt, que seguiria a taxa do monitor.
- **Resolução reduzida:** o `ShaderEffect` é desenhado com metade da largura e da altura da tela e ampliado com `scale: 2`. Para gradientes, névoa e chamas, a diferença visual é mínima, e o custo cai para cerca de um quarto.
- **Shaders simples:** poucas operações por pixel, sem texturas grandes nem múltiplos passes. Movimentos lentos e sutis, coerentes com a proposta da Lucerna.
- **Redesenho só quando necessário:** fora do tique do `Timer`, nada dispara redesenho; pausado, o `Timer` para e o custo é zero.
- **Memória mínima:** um único shader carregado por monitor, sem guardar quadros em RAM. GIF e vídeo ficam de fora por decodificarem na CPU e ocuparem memória.
- **GPU integrada:** o shell desenha na GPU que o Hyprland usa para compor. Em notebooks híbridos, deixar a iGPU como primária (`AQ_DRM_DEVICES` com a Intel primeiro) mantém a NVIDIA desligada. No ambiente de desenvolvimento isso já acontece, porque só a GPU Intel é repassada ao container.

## Integração com temas e arquitetura

Cada tema declara seu wallpaper, e os shaders recebem as cores do tema ativo como uniforms. Como as cores do `ThemeManager` já são animadas na troca de tema, um mesmo efeito, como a chama da Lamparina, muda de cor sozinho e com transição suave.

O campo `wallpaper` do tema aceita duas formas. Os caminhos são relativos a `themes/`, como já acontece hoje.

```json
"wallpaper": "wallpapers/lamparina.jpg"
```

```json
"wallpaper": {
    "static": "wallpapers/lamparina.jpg",
    "shader": "shaders/chama.qsb",
    "fps": 30
}
```

A forma em texto é a atual e continua valendo: um tema só com imagem estática. O `ThemeManager` normaliza as duas formas e expõe `wallpaper` (a imagem) e `wallpaperShader` (vazio se o tema não tiver). A lista `themes` traz os mesmos dois campos para cada tema, e é dela que sai o wallpaper de um `source` por monitor.

O modo não fica no tema. Ele é preferência do usuário e mora em `Config.qml`, junto do tema ativo e do "não perturbe".

### Shaders

O Qt 6 não carrega GLSL direto: o `ShaderEffect` exige shaders compilados para `.qsb` com a ferramenta `qsb` (pacote `qt6-shadertools`). Ficam os dois no repositório, e um script refaz a compilação:

```
themes/shaders/
├── chama.frag   # fonte GLSL 440
└── chama.qsb    # compilado; é o que o tema referencia
```

```sh
dev/shaders.sh   # compila themes/shaders/*.frag → *.qsb
```

Os shaders ficam em `themes/`, e não dentro da feature, porque são dados do tema, como os wallpapers: criar um tema animado novo continua sendo adicionar arquivos, sem tocar em código.

Todos os shaders recebem os mesmos uniforms, para qualquer tema poder usar qualquer efeito:

| Uniform | Conteúdo |
| --- | --- |
| `time` | Segundos de animação acumulados (só avança enquanto roda) |
| `resolution` | Tamanho desenhado, em pixels |
| `base`, `surface`, `accent`, `text` | Cores do tema ativo |

### Camadas

A feature segue as camadas do Lucerna. O `state/` junta todos os sinais de modo e de pausa numa única decisão por monitor; a `ui/` só liga ou desliga a animação com base nela. Uma nova condição de pausa é adicionada só no `state/`.

- `WallpaperState.shouldAnimate(screen)`: verdadeiro quando o monitor deve animar agora.
- `WallpaperState.mode(screen)` e `setMode(screen, mode)`: modo do monitor, lido e gravado em `Config.qml`.
- `WallpaperState.source(screen)`: imagem e shader daquele monitor, do tema ativo ou do `source` configurado.

As fontes dos sinais seguem a regra de dependências: `state/` lê `services/` (`Hypr`, `Session`, `Battery`) e `core/` (`ThemeManager`, `Config`), e a `ui/` lê só o `state/` e o `core/`.

```
features/wallpaper/
├── state/
│   └── WallpaperState.qml   # modo por monitor, sinais de pausa, shouldAnimate
└── ui/
    ├── Wallpaper.qml        # Variants: uma janela por monitor
    ├── WallpaperWindow.qml  # camada de fundo; imagem por baixo, shader por cima
    ├── StaticWallpaper.qml  # imagem com transição na troca de tema (o comportamento atual)
    └── ShaderWallpaper.qml  # ShaderEffect em meia resolução, tempo por Timer
```

## Fora do escopo

- **Vídeo (MP4, WebM):** exige Qt Multimedia e decodificação contínua, o que contraria a meta de consumo mínimo.
- **GIF e APNG:** decodificam na CPU e guardam quadros na RAM; o mesmo efeito sai mais barato como shader.
- **Wallpapers interativos** (que reagem ao mouse ou ao áudio): exigiriam redesenho constante.
