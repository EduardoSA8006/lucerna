# Lucerna

**Um shell de desktop completo para o Hyprland, escrito em Quickshell.**

Barra, painel superior, central lateral, launcher, notificações, tela de bloqueio e uma tela de configurações que cobre do tema aos monitores, ao mouse e ao teclado. As animações usam as curvas de movimento do Material 3, e tudo sai de um tema em JSON, trocável ao vivo. Tudo em português.

![Painel superior aberto sobre a área de trabalho](docs/screenshots/hero.jpg)

## Destaques

- **Configurações de verdade, sem editar arquivo**: monitores arrastando, mouse, teclado, barra, painéis, energia, transparência e animações. Só o que você muda vai por cima do `hyprland.lua`, e "Voltar ao hyprland.lua" desfaz.
- **Botões e teclas mapeáveis**: os botões extras do mouse e as teclas extras do teclado (F13–F24, macro, mídia) podem abrir painéis, controlar a mídia, trocar de workspace, **enviar um atalho de teclado** para a janela ou rodar um comando.
- **Remapeamento real de teclas**, em qualquer programa e inclusive para modificadores (Caps Lock → Esc, Alt Gr → Super). O Lucerna gera o keymap, confere se ele compila e só então o entrega ao Hyprland.
- **Monitores arrastando**: a disposição se monta num canvas com encaixe magnético. Cada monitor tem resolução, taxa, escala, rotação, espelhamento, VRR e 10 bits. Aplicar pede confirmação em todas as telas e, sem resposta em 15 s, volta ao anterior.
- **Painéis que convivem**: o painel superior e a central lateral ficam abertos juntos, desviam um do outro e não cobrem a barra.
- **Papel de parede animado e leve**: cada tema tem um efeito em shader (aurora, brasas, chama, luar, papel), nas cores do tema, a 30 fps e em meia resolução. Ele pausa sozinho com tela cheia, tela bloqueada ou tela apagada. Cada tema pode trocar o seu por outro efeito, por uma imagem sua ou por um **vídeo ou GIF**. O vídeo é convertido uma vez para a resolução da tela, sem tarjas, quadros repetidos nem áudio, e toca decodificado pela GPU.
- **Vidro de verdade**: o desfoque atrás dos painéis é do próprio Hyprland, e o tema ajusta também as bordas das janelas.
- **Leve por padrão**: cada serviço só coleta dados enquanto alguém mostra. Um modo offline desliga tudo o que usa a internet.

## Galeria

### Área de trabalho

A barra em faixa e as janelas com as bordas e o arredondamento que o tema aplica no Hyprland.

![Área de trabalho com a barra e duas janelas](docs/screenshots/desktop.jpg)

### Painel superior

Visão geral, mídia com letra sincronizada, desempenho e clima. Desce de dentro da barra, e a altura acompanha a aba.

| Mídia | Desempenho |
| --- | --- |
| ![Aba Mídia](docs/screenshots/dashboard-media.jpg) | ![Aba Desempenho](docs/screenshots/dashboard-performance.jpg) |
| **Clima** | **Com a central lateral ao lado** |
| ![Aba Clima](docs/screenshots/dashboard-weather.jpg) | ![Painel superior e central lateral abertos juntos](docs/screenshots/together.jpg) |

### Central lateral e notificações

Wi-Fi, Bluetooth, som, avisos, bateria e tela, com as seções do lado de fora. As notificações chegam em popups e ficam guardadas nos avisos.

| Som | Bateria |
| --- | --- |
| ![Central lateral: som](docs/screenshots/sidebar-sound.jpg) | ![Central lateral: bateria](docs/screenshots/sidebar-battery.jpg) |
| **Popups** | **Avisos** |
| ![Notificações](docs/screenshots/notifications.jpg) | ![Central de avisos](docs/screenshots/sidebar-notifications.jpg) |

### Launcher, temas e barra

| Launcher | Seletor de temas |
| --- | --- |
| ![Launcher](docs/screenshots/launcher.jpg) | ![Seletor de temas](docs/screenshots/themes.jpg) |
| **Pergaminho (claro)** | **Brasa** |
| ![Tema Pergaminho](docs/screenshots/theme-pergaminho.jpg) | ![Tema Brasa](docs/screenshots/theme-brasa.jpg) |

A barra tem quatro estilos: **faixa** (o padrão), **ilha** (só a hora, e expande com o mouse), **pílula** e **três ilhas**. Pode ficar fixa ou escondida até o mouse encostar no topo.

![Os quatro estilos da barra](docs/screenshots/bars.png)

### Papel de parede

Cada tema tem o seu, e dá para trocar: o próprio, só a imagem parada, qualquer efeito animado (nas cores daquele tema) ou uma imagem, vídeo (MP4, WebM, MKV, MOV) ou GIF do computador, escolhido num navegador com miniaturas. O vídeo é preparado uma vez para tocar gastando o mínimo: vai para a resolução da tela, perde as tarjas pretas, os quadros repetidos e o áudio, e é decodificado pela GPU (VA-API). Um vídeo 4K de 47 MB, por exemplo, virou 537 KB e passou a gastar 1% do motor de vídeo da GPU, contra 8% antes. Cada monitor ganha a sua versão: ao conectar um de outra resolução ou proporção, como um ultrawide, a versão dele é feita em segundos, em segundo plano. Enquanto isso, ele toca a mais parecida. Há também a opção de deixar prontas as resoluções mais comuns.

![Configurações: papel de parede](docs/screenshots/settings-wallpaper.jpg)

| Luar (animado) | Brasas (animado) |
| --- | --- |
| ![Efeito Luar](docs/screenshots/wallpaper-luar.jpg) | ![Efeito Brasas](docs/screenshots/wallpaper-brasas.jpg) |

### Configurações

| Aparência | Monitores |
| --- | --- |
| ![Configurações: aparência](docs/screenshots/settings-appearance.jpg) | ![Configurações: monitores](docs/screenshots/settings-monitors.jpg) |
| **Teclado** | **Mouse** |
| ![Configurações: teclado](docs/screenshots/settings-keyboard.jpg) | ![Configurações: mouse](docs/screenshots/settings-mouse.jpg) |

### Bloqueio, energia e OSD

| Tela de bloqueio | Menu de energia |
| --- | --- |
| ![Tela de bloqueio](docs/screenshots/lock.jpg) | ![Menu de energia](docs/screenshots/power.jpg) |

![OSD de brilho](docs/screenshots/osd.png)

## O que tem

| Parte | O que faz |
| --- | --- |
| **Barra** | Workspaces, hora e data, rede, som, bateria e avisos. Tem quatro estilos e pode ficar fixa ou esconder sozinha. Na área de trabalho vazia fica sempre à mostra, e aparece por um instante ao trocar de workspace. |
| **Painel superior** | Visão geral (perfil, relógio, calendário, clima, recursos e mídia), mídia com letra sincronizada (LRCLIB) e pulso do áudio na capa, desempenho (CPU, GPU, memória, disco e rede) e clima (Open-Meteo). Abas reordenáveis e opção de abrir ao parar o mouse na hora. |
| **Central lateral** | Wi-Fi (conectar, com senha), Bluetooth (parear e conectar), som (saídas, entradas e volumes), avisos, bateria (perfil de energia) e brilho. Abre à esquerda ou à direita. |
| **Notificações** | Popups com ações, pausa no mouse e prazo ajustável, não perturbe e a central de avisos. |
| **Launcher** | Apps e ações do shell, com busca. |
| **Tela de bloqueio** | Relógio e senha (PAM). |
| **Energia** | Menu (bloquear, suspender, sair, reiniciar, desligar). Avisos de bateria baixa e crítica, ação no nível crítico com prazo para cancelar, troca de perfil na tomada e modo leve na bateria. |
| **OSD** | Volume e brilho. |
| **Papel de parede** | Imagem com transição na troca e efeito animado por cima (shader, a 30 fps e em meia resolução). Pausa com app em tela cheia, tela bloqueada ou tela apagada, e opcionalmente com qualquer janela aberta; no automático, fica parado na bateria. Modo e origem por monitor. |
| **Temas** | Cinco prontos (Nebulosa, Brasa, Lamparina, Luar e Pergaminho), com wallpaper, fontes próprias e bordas do Hyprland. Trocam ao vivo. |

### Configurações

| Tópico | Opções |
| --- | --- |
| **Aparência** | Tema, contorno nos cartões e velocidade das animações. |
| **Papel de parede** | Por tema: o próprio, a imagem parada, um efeito animado ou uma imagem, vídeo ou GIF seu (com preencher ou inteira). Tem ainda o modo de exibição (automático, animado ou parado), modo e papel por monitor, quadros por segundo, parado na bateria, pausar com janelas e resolução cheia. |
| **Monitores** | Disposição arrastando, resolução, taxa de atualização, escala, rotação, espelhar, VRR e cor de 10 bits. Tem "Identificar" e aplicar com confirmação. O arranjo fica salvo por conjunto de monitores e é reaplicado ao conectar. |
| **Mouse** | Velocidade, aceleração, canhoto, foco das janelas (ao passar o mouse ou ao clicar), rolagem, touchpad (tocar para clicar, arrastar, desligar ao digitar, clique com dedos, botão do meio), **botões mapeados** e velocidade própria por mouse. |
| **Teclado** | Layouts (até quatro, com variante e atalho para trocar), repetição, Num Lock, teclas especiais (Caps Lock, Compose, trocar Alt e Super) e qualquer opção do xkb, com busca. Também **teclas remapeadas** e **teclas extras e atalhos**. |
| **Transparência e desfoque** | Opacidade dos painéis e dos cartões e intensidade do desfoque, por cima do tema. |
| **Notificações** | Não perturbe e tempo na tela. |
| **Painéis** | Quais abrem juntos e se desviam um do outro. |
| **Central lateral** | Lado da tela. |
| **Barra** | Estilo, esconder sozinha, mostrar na área vazia e ao trocar de workspace, data. |
| **Painel superior** | Abas, abrir e fechar pelo mouse, cartões, semana, letra, pulso do áudio, intervalo do desempenho, GPU, cidade, unidades e **modo offline**. |
| **Energia e bateria** | Porcentagem na barra, avisos, ação no nível crítico, perfil automático, economia abaixo de um nível e modo leve. |

## Requisitos

- **Hyprland 0.56+**, com a configuração em Lua (`hyprland.lua`)
- **Quickshell 0.3.1+**
- **Fonte de ícones**: `ttf-material-symbols-variable` (repositório oficial do Arch)
- Opcionais, cada um liga uma parte:
  - PipeWire: volume e mídia
  - UPower: bateria e perfis de energia
  - NetworkManager: rede
  - BlueZ: Bluetooth
  - `brightnessctl`: brilho
  - `nvidia-smi`: GPU NVIDIA; vem com o driver
  - `ffmpeg` e `qt6-multimedia-ffmpeg`: papel de parede em vídeo ou GIF. Para a GPU decodificar o vídeo, também o driver VA-API (`intel-media-driver` na Intel, `libva-mesa-driver` na AMD) e o `libva-utils`, que o shell usa para detectar o suporte.
- Serviços na internet, só enquanto a aba correspondente está aberta, e desligáveis pelo modo offline: [Open-Meteo](https://open-meteo.com) (clima) e [LRCLIB](https://lrclib.net) (letras).

O remapeamento de teclas usa o `xkbcli`, que vem com o libxkbcommon, dependência do próprio Hyprland.

## Instalação

```sh
git clone https://github.com/EduardoSA8006/lucerna
ln -s "$PWD/lucerna" ~/.config/quickshell/lucerna
```

No `hyprland.lua`:

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("qs -c lucerna")
end)

local ipc = "qs -c lucerna ipc call "
hl.bind("SUPER + Space",  hl.dsp.exec_cmd(ipc .. "panels toggle launcher"))
hl.bind("SUPER + D",      hl.dsp.exec_cmd(ipc .. "panels toggle dashboard"))
hl.bind("SUPER + S",      hl.dsp.exec_cmd(ipc .. "panels toggle settings"))
hl.bind("SUPER + N",      hl.dsp.exec_cmd(ipc .. "sidebar toggle notifications"))
hl.bind("SUPER + C",      hl.dsp.exec_cmd(ipc .. "sidebar toggle \"\""))
hl.bind("SUPER + T",      hl.dsp.exec_cmd(ipc .. "panels toggle themes"))
hl.bind("SUPER + Escape", hl.dsp.exec_cmd(ipc .. "panels toggle power"))
hl.bind("SUPER + L",      hl.dsp.exec_cmd(ipc .. "session lock"))
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(ipc .. "brightness up"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(ipc .. "brightness down"), { locked = true, repeating = true })
```

O volume pode ficar no `wpctl`, direto nos atalhos: o shell percebe a mudança pelo PipeWire e mostra o OSD. O [`dev/hyprland.lua`](dev/hyprland.lua) tem um exemplo completo. As regras de desfoque dos painéis são aplicadas pelo próprio shell, sem mexer no `hyprland.lua`.

## Comandos IPC

Tudo pode ser chamado de fora com `qs -c lucerna ipc call <alvo> <função> [argumentos]`.

| Alvo | Funções |
| --- | --- |
| `panels` | `open <nome>`, `toggle <nome>`, `dismiss <nome>` (fecha só esse), `close` (fecha todos), `get`. Nomes: `launcher`, `dashboard`, `sidebar`, `settings`, `themes`, `power` |
| `dashboard` | `open <aba>` (`overview`, `media`, `performance`, `weather`), `toggle` |
| `sidebar` | `open <seção>`, `toggle <seção>` (`wifi`, `bluetooth`, `sound`, `notifications`, `battery`, `display`; vazio = a última) |
| `settings` | `open <tópico>` (`appearance`, `wallpaper`, `displays`, `mouse`, `keyboard`, `glass`, `notifications`, `panels`, `sidebar`, `bar`, `dashboard`, `power`, `shortcuts`, `about`) |
| `notifications` | `clear`, `toggleDnd`, `count` |
| `session` | `lock`, `isLocked` |
| `theme` | `set <id>`, `get`, `list` |
| `brightness` | `up`, `down`, `set <0-100>` |
| `monitors` | `identify` |
| `wallpaper` | `mode <auto\|animated\|static\|toggle>`, `modeFor <monitor> <modo>` (`default` volta ao geral), `get` |
| `action` | `run <id>`: as mesmas ações dos botões e teclas mapeados (`launcher`, `play-pause`, `volume-up`, `lock`…; a lista está em [`core/input/InputActions.qml`](core/input/InputActions.qml)) |
| `battery` | `simulate <0-100> <true\|false>` e `real`, só no ambiente de desenvolvimento |

## Temas

Cada arquivo em `themes/*.json` é um tema, e o nome do arquivo é o id. Para criar um, copie o `themes/nebulosa.json` (o padrão), mude as cores e o wallpaper: ele aparece no seletor na hora. Além de cores, fontes, raios e espaçamentos, o tema define:

- `transparency`: `enabled`, `base` (opacidade dos painéis) e `layers` (dos cartões dentro deles).
- `hyprland`: bordas, arredondamento e intensidade do desfoque (`blurSize`, `blurPasses`), aplicados via `hyprctl eval`.
- `wallpaper`: a imagem (`"wallpapers/luar.jpg"`) ou `{ "static": ..., "shader": "shaders/luar.qsb", "fps": 30 }`. Os efeitos ficam em `themes/shaders/`, com a fonte GLSL ao lado do `.qsb` compilado. `dev/shaders.sh` recompila todos, e isso requer o `qsb`, do pacote `qt6-shadertools`. Todo efeito recebe os mesmos uniforms (`time`, `resolution`, `base`, `surface`, `accent`, `text`), então qualquer tema pode usar qualquer efeito, e um efeito novo entra no catálogo em `themes/shaders/effects.json`.
- `animation.scale`: velocidade geral das animações (1 = padrão, 0 = desligadas).
- `fonts`: fontes que o tema traz em `themes/fonts/`, carregadas pelo shell sem instalar nada no sistema. O Nebulosa traz a Rubik, sob licença OFL.
- `surfaces.outline`: contorno fino nos cartões. O padrão é sem contorno; os cartões se destacam pelo tom.
- `colors.track`: cor opcional dos trilhos de medidores e sliders.

Transparência, desfoque, contorno e velocidade das animações também se ajustam nas configurações, por cima de qualquer tema. "Restaurar padrões do tema" desfaz.

## Onde ficam as preferências

Em `~/.local/state/quickshell/by-shell/<id>/config.json`. Os ajustes de monitores, mouse e teclado guardam **só o que foi mudado**; o resto continua vindo do `hyprland.lua`. O Lucerna reaplica esses ajustes ao iniciar, quando um monitor é conectado e depois de um `hyprctl reload`. O keymap gerado para as teclas remapeadas fica ao lado, em `keymap.xkb`.

## Arquitetura

Organizado por feature, com camadas que só olham para baixo:

```
core/       tema, config, painéis, widgets e o catálogo de ações de entrada
services/   a conversa com o sistema: Hyprland, PipeWire, UPower, NetworkManager,
            BlueZ, MPRIS, notificações, monitores, entrada, clima…
features/   uma pasta por parte do shell (bar, dashboard, sidebar, settings,
            launcher, input, displays…), cada uma com state/ e ui/
```

- A `ui` fala com o `state` da própria feature, e o `state` fala com `services` e `core`.
- Uma feature não importa outra. Quando precisam conversar, a conversa passa pelo `core`: por exemplo, o `Panels` diz quais painéis estão abertos.

Os princípios e o desenho completo estão em [`Lucerna — Proposta.md`](<Lucerna — Proposta.md>). O desenho dos wallpapers animados está em [`Lucerna — Proposta do Wallpaper.md`](<Lucerna — Proposta do Wallpaper.md>), e os plugins próprios planejados, em [`Lucerna — Plugins Próprios.md`](<Lucerna — Plugins Próprios.md>).

## Desenvolvimento

O shell roda num Hyprland aninhado, dentro de um container Docker com Arch, que abre como uma janela na sessão Wayland do host. O repositório é montado em `~/.config/quickshell/lucerna` dentro do container, então o Quickshell recarrega sozinho quando um arquivo muda.

```sh
dev/run.sh            # constrói a imagem na primeira vez e abre a janela
dev/run.sh --build    # reconstrói a imagem (ex.: depois de mudar o Dockerfile)
dev/run.sh shell      # abre um bash no container em execução
dev/run.sh log        # segue o log do Quickshell
```

No host é preciso Docker, uma sessão Wayland e o usuário no grupo `docker`.

- Volume, bateria e rede mostram o estado real do host: o PipeWire e o D-Bus do sistema são repassados ao container.
- Com `LUCERNA_DEV=1`, definido pelo `run.sh`, as ações que chegariam ao host são só simuladas: suspender, reiniciar e desligar, ligar e desligar Wi-Fi e Bluetooth, conectar a redes e dispositivos, e o perfil de energia. A leitura é real.
- O brilho é só leitura no container; os ajustes são simulados.
- A senha da tela de bloqueio no container é `lucerna` (usuário `dev`).
- Para testar a aba Mídia, a imagem tem `mpv` com `mpv-mpris`: rode `dev/run.sh shell` e depois `mpv --no-video arquivo.mp3`.
- Para testar monitores, crie saídas virtuais: `hyprctl output create headless`.

Atalhos no Hyprland aninhado (a tecla de mod é `Alt`, para não brigar com o desktop do host):

| Atalho | Ação |
| --- | --- |
| `Alt+Space` | Launcher |
| `Alt+S` | Configurações |
| `Alt+D` | Painel superior (também clicando na hora da barra). Dentro dele, `Tab`/`Shift+Tab` ou `1`–`4` trocam de aba |
| `Alt+N` | Central lateral nos avisos |
| `Alt+C` | Central lateral (última seção) |
| `Alt+T` | Seletor de temas |
| `Alt+Esc` | Menu de energia |
| `Alt+L` | Bloquear a tela |
| `Alt+↑` / `Alt+↓` / `Alt+M` | Volume / mudo |
| `Alt+→` / `Alt+←` | Brilho |
| `Alt+Enter` | Abrir o kitty |
| `Alt+Q` | Fechar a janela |
| `Alt+1..5` / `Alt+Shift+1..5` | Ir para o workspace / mover a janela |
| `Alt+Shift+R` | Reiniciar o Quickshell |
| `Alt+Shift+E` | Sair do Hyprland |
