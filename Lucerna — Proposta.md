# Lucerna — Proposta

Sep 23, 2026 · @Eduardo Alves

## Visão geral

Lucerna é um shell de desktop próprio, escrito do zero em Quickshell (QML), feito para rodar sobre o Hyprland no Arch Linux. Ele substitui barra, launcher, notificações e demais painéis por um conjunto único, leve e totalmente personalizável.

O nome vem do latim *lucerna*, "lamparina": luz sobre o escuro. A ideia guia o projeto inteiro — uma interface escura e discreta, em que os elementos só se acendem quando são necessários.

## Motivação

Shells prontos em Quickshell, como Noctalia, Caelestia e DankMaterialShell, carregam módulos, serviços e telas de configuração que nem sempre são usados. Mexer fundo neles exige primeiro entender a arquitetura de outra pessoa.

Com um shell próprio, só roda o que foi escrito, e cada decisão visual e de comportamento é intencional. Os shells prontos servem como material de estudo, não como base de código.

## Princípios

- **Leveza:** nenhum módulo ou serviço entra sem uso real. O custo base é o do Qt; o resto é mínimo.
- **Controle total:** todo o código é próprio e legível, sem camadas de configuração que escondam comportamento.
- **Específico para Hyprland:** integração nativa com o IPC do Hyprland via `Quickshell.Hyprland`, sem scripts externos. Outros compositores ficam fora, pelo menos por enquanto.
- **Feature-first:** o código se organiza por funcionalidade; cada feature pode ser adicionada, trocada ou removida sem afetar as outras.
- **Camadas bem definidas:** interface, estado e serviços são separados, e as dependências só apontam para baixo.

## Requisitos

- **Hyprland 0.56 ou mais novo, com configuração em Lua** (`hyprland.lua`). O formato `.conf` sai na 0.57, e o modo Lua muda o IPC: `dispatch` passa a receber código Lua (`hl.dsp.focus({ workspace = 2 })`) e `keyword` é substituído por `eval`. O Lucerna fala só o dialeto Lua.
- **Quickshell 0.3.1 ou mais novo**, que detecta o modo Lua do Hyprland (`Hyprland.usingLua`).
- Serviços do sistema usados quando presentes: PipeWire (áudio), UPower (bateria), NetworkManager (rede) e `brightnessctl` (brilho). Na falta de um deles, o componente correspondente simplesmente não aparece.

## Identidade visual

O Lucerna terá vários temas pré-configurados, trocáveis a qualquer momento por um painel de seleção rápida. O tema padrão, **Lamparina**, segue a ideia do nome: fundo escuro e profundo com um único acento âmbar, como a chama de uma lamparina.

- **Tema como dado:** cada tema é um arquivo em `themes/` com cores, fontes, raios, espaçamentos e wallpaper. Criar um tema novo é adicionar um arquivo, sem tocar em código.
- **Um ponto de verdade:** um `ThemeManager` (singleton) carrega o tema ativo e expõe os tokens (cores, fontes, raios, espaçamentos, durações de animação e altura da barra); nenhum componente usa cor, fonte ou espaçamento fixo. As dimensões estruturais de cada painel, como a largura do launcher, ficam no próprio componente.
- **Temas embutidos:** Lamparina (padrão, âmbar), Luar (azul frio), Brasa (vermelho-alaranjado) e Pergaminho (claro). Os wallpapers são gerados por `dev/wallpapers.py`.
- **Troca ao vivo:** ao escolher um tema no painel, toda a interface muda na hora, com transição suave, e a escolha fica salva para a próxima sessão.
- **Integração com o Hyprland:** a troca também ajusta bordas e arredondamento do compositor via `hyprctl eval`, para o visual ficar coeso fora do shell.

## Escopo

O Lucerna cresce por módulos, começando pelo essencial.

| Componente | Função |
| --- | --- |
| Barra | Workspaces do Hyprland, relógio, volume, bateria e rede |
| Launcher | Abrir aplicativos e ações rápidas |
| Notificações | Servidor de notificações próprio, com central lateral |
| Tela de bloqueio | Bloqueio próprio, no visual do tema ativo |
| Wallpaper | Gerenciamento de papel de parede, vinculado ao tema |
| Seletor de temas | Painel para trocar rapidamente entre temas pré-configurados |
| OSD | Indicadores de volume e brilho na tela |
| Menu de energia | Bloquear, suspender, reiniciar e desligar |

Fora do escopo inicial: o controle de ociosidade continua com `hypridle`. O shell é específico para o Hyprland; suporte a outros compositores não é objetivo, pelo menos por enquanto.

## Arquitetura

A arquitetura é feature-first com separação por camadas. Cada feature vive em sua própria pasta e se divide internamente em camadas; o que é compartilhado fica em `core/` e `services/`.

| Camada | Responsabilidade | Pode depender de |
| --- | --- | --- |
| `ui/` | Componentes visuais em QML, sem lógica de negócio | `state/`, `core/` |
| `state/` | Estado e lógica da feature (equivalente a um view model) | `services/`, `core/` |
| `services/` | Integração com o sistema: Hyprland, áudio, rede, bateria, brilho, notificações, sessão | Apenas Quickshell e o sistema |
| `core/` | Motor de temas, painéis, widgets base e configuração compartilhados | Apenas Quickshell |

Regras:

- As dependências só apontam para baixo, e uma feature nunca importa outra.
- A comunicação entre features passa por `services/` ou `core/`. Exemplo: o botão do launcher na barra chama `Panels.toggle("launcher")` em `core/panels/`, e o launcher reage a `Panels.current`. Um painel aberto fecha o anterior.
- Toda conversa com o Hyprland fica em `services/Hypr.qml`.
- Os imports usam o sistema de módulos do Quickshell, em que cada pasta vira um módulo (`import qs.core.theme`, `import qs.features.bar.state`). Por isso os nomes de pasta são identificadores QML válidos: `themeSwitcher`, e não `theme-switcher`.

O repositório inteiro é a configuração do shell. Fora do código do shell ficam só `dev/`, com o ambiente de teste, e a documentação.

```
lucerna/
├── shell.qml                   # ponto de entrada, monta as features
├── core/
│   ├── theme/ThemeManager.qml  # carrega o tema ativo e expõe os tokens
│   ├── panels/Panels.qml       # qual painel está aberto; ponte entre features
│   ├── widgets/                # botões, ícones, painéis base
│   └── config/Config.qml       # preferências persistidas
├── services/
│   ├── Hypr.qml                # IPC do Hyprland (dialeto Lua)
│   ├── Audio.qml
│   ├── Network.qml
│   ├── Battery.qml
│   ├── Brightness.qml
│   ├── Notifications.qml
│   └── Session.qml             # bloquear, suspender, reiniciar, desligar
├── features/
│   ├── bar/
│   │   ├── ui/
│   │   └── state/
│   ├── launcher/
│   ├── notifications/
│   ├── lockscreen/
│   ├── wallpaper/
│   ├── themeSwitcher/
│   ├── osd/
│   └── powerMenu/
├── themes/
│   ├── lamparina.json          # um arquivo por tema
│   └── wallpapers/
└── dev/                        # ambiente de teste (não é carregado pelo shell)
    ├── Dockerfile
    ├── hyprland.lua
    └── run.sh
```

## Controle externo

Atalhos do Hyprland falam com o shell por `IpcHandler`, sem scripts intermediários:

```sh
qs -c lucerna ipc call panels toggle launcher   # launcher, notifications, themes, power
qs -c lucerna ipc call session lock
qs -c lucerna ipc call brightness up            # up, down, set <0-100>
qs -c lucerna ipc call theme set luar           # get, list
qs -c lucerna ipc call notifications clear      # toggleDnd, count
```

O volume não precisa de IPC: os atalhos chamam `wpctl`, e o shell reage à mudança pelo PipeWire.

## Segurança da tela de bloqueio

- O bloqueio usa o protocolo `ext-session-lock`: se o shell cair, o Hyprland continua bloqueado.
- O estado de bloqueio fica em `PersistentProperties`, então recarregar o shell (por exemplo, ao salvar um arquivo) não desbloqueia a tela.
- A autenticação usa uma configuração PAM própria (`features/lockscreen/pam/password`), só com `pam_unix`, em vez do `login` do sistema.

## Ambiente de desenvolvimento

O sistema de desenvolvimento roda KDE Plasma, não Hyprland. Para testar, o Lucerna roda num **Hyprland aninhado dentro de um container Docker com Arch**, que abre como uma janela na sessão Wayland do host (`dev/run.sh`).

- **Ciclo rápido:** o repositório é montado em `~/.config/quickshell/lucerna` dentro do container, e o Quickshell recarrega sozinho quando um arquivo muda.
- **Dados reais:** o container recebe o socket do PipeWire e o D-Bus do sistema do host, então volume, bateria e rede mostram o estado real da máquina.
- **Modo de desenvolvimento:** `dev/run.sh` define `LUCERNA_DEV=1`. Nesse modo, suspender, reiniciar, desligar e sair só registram a ação e mostram uma notificação. Sem isso, um `poweroff` no container chegaria ao host pelo D-Bus do sistema.
- **GPU:** só a GPU Intel é repassada; o container não tem os drivers da NVIDIA.
- **Tela de bloqueio:** o usuário do container é `dev`, com a senha `lucerna`.
- **Limitações:** o brilho é só leitura no container, porque ajustá-lo exige uma sessão do logind. A sessão completa (login pelo TTY, `hypridle`, PAM do sistema real) fica para uma VM QEMU com virgl, quando for preciso.

## Instalação

No sistema com Hyprland, o repositório é ligado ao diretório de configuração do Quickshell e iniciado pelo Hyprland:

```sh
ln -s ~/Documentos/projetos/lucerna ~/.config/quickshell/lucerna
```

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("qs -c lucerna")
end)
```

`dev/hyprland.lua` serve de referência para os atalhos.
