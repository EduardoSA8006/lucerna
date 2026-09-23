# Lucerna — Proposta

voSep 23, 2026 · @Eduardo Alves

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

## Identidade visual

O Lucerna terá vários temas pré-configurados, trocáveis a qualquer momento por um painel de seleção rápida. O tema padrão, **Lamparina**, segue a ideia do nome: fundo escuro e profundo com um único acento âmbar, como a chama de uma lamparina.

- **Tema como dado:** cada tema é um arquivo em `themes/` com cores, fontes, raios, espaçamentos e wallpaper. Criar um tema novo é adicionar um arquivo, sem tocar em código.
- **Um ponto de verdade:** um `ThemeManager` (singleton) carrega o tema ativo e expõe os tokens; nenhum componente usa cor ou tamanho fixo.
- **Troca ao vivo:** ao escolher um tema no painel, toda a interface muda na hora, com transição suave, e a escolha fica salva para a próxima sessão.
- **Integração com o Hyprland:** a troca também pode ajustar bordas e cores do compositor, para o visual ficar coeso fora do shell.

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
| `services/` | Integração com o sistema: Hyprland, áudio, rede, bateria, notificações | Apenas Quickshell e o sistema |
| `core/` | Motor de temas, widgets base e configuração compartilhados | Nada de features |

Regras: as dependências só apontam para baixo, uma feature nunca importa outra, e a comunicação entre features passa por `services/` ou `core/`. Toda conversa com o Hyprland fica em `services/Hypr.qml`.

```
~/.config/quickshell/lucerna/
├── shell.qml               # ponto de entrada, monta as features
├── core/
│   ├── theme/ThemeManager.qml  # carrega o tema ativo e expõe os tokens
│   ├── widgets/            # botões, ícones, painéis base
│   └── config/             # preferências persistidas
├── services/
│   ├── Hypr.qml            # IPC do Hyprland
│   ├── Audio.qml
│   ├── Network.qml
│   ├── Battery.qml
│   └── Notifications.qml
├── features/
│   ├── bar/
│   │   ├── ui/
│   │   └── state/
│   ├── launcher/
│   ├── notifications/
│   ├── lockscreen/
│   ├── wallpaper/
│   ├── theme-switcher/
│   ├── osd/
│   └── power-menu/
└── themes/
    └── lamparina.json      # um arquivo por tema
```
