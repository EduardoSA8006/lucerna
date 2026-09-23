# Lucerna — Plugins Próprios

Sep 23, 2026 · @Eduardo Alves

> Anotações para o futuro. Nada disto é necessário hoje: tudo abaixo já funciona em QML puro, com recursos do Qt e do Quickshell. Os plugins só entram quando a versão em QML ficar pesada ou limitada demais.

## Por quê

O Lucerna depende do mínimo possível de pacotes de terceiros. Quando uma parte do shell crescer a ponto de pedir C++ (desempenho, acesso a APIs do sistema, processamento de sinal), a saída é escrever um plugin QML **nosso**, em um repositório separado, em vez de adotar uma biblioteca externa. É o mesmo caminho do Caelestia, que tem o próprio plugin C++, mas sem as bibliotecas de terceiros que ele puxa (`libcava`, `aubio`, `libsensors`, `qt6-m3shapes`).

Regras para um plugin próprio:

- Repositório e pacote próprios (por exemplo, `lucerna-sysinfo`), com versão e changelog.
- Módulo QML com nome `Lucerna.<Nome>` e API pequena, documentada.
- Depende só do Qt e de interfaces do kernel ou do sistema (`/proc`, `/sys`, D-Bus, PipeWire).
- O shell continua funcionando sem ele: o `services/` correspondente detecta o plugin e, na falta dele, usa a implementação em QML.

## Candidatos

| Plugin | Substitui | Hoje, no Lucerna | Ganho com o plugin |
| --- | --- | --- | --- |
| `lucerna-sysinfo` | Leituras de CPU, memória, disco, rede, temperatura e GPU | `FileView` em `/proc` e `/sys`, `df` para disco e `nvidia-smi` para NVIDIA | Leitura sem criar processos (`statvfs` no lugar do `df`); NVML carregado sob demanda no lugar do `nvidia-smi`; uso da GPU Intel pelos contadores `fdinfo` do DRM, hoje indisponível |
| `lucerna-spectrum` | `libcava` + `aubio` (visualizador e batida) | Pulso de volume pelo `PwNodePeakMonitor` do Quickshell | Espectro por frequência (FFT própria sobre um stream do PipeWire) e detecção de batida |
| `lucerna-shapes` | `qt6-m3shapes` | Formas desenhadas com `QtQuick.Shapes` (curvas polares) | Morfismo entre formas diferentes, com o mesmo número de vértices, em C++ e com antisserrilhamento melhor |
| `lucerna-ddc` | `ddcutil` | Não há: só o brilho da tela interna, via `brightnessctl` | Brilho de monitores externos por DDC/CI direto no `/dev/i2c-*` |
| `lucerna-palette` | `python-materialyoucolor` (usado pelo `caelestia-cli`) | Não há: os temas são fixos | Gerar um tema a partir das cores do wallpaper |
| `lucerna-brightness` | `brightnessctl` | `brightnessctl` | Brilho da tela interna pelo `SetBrightness` do logind, via D-Bus, sem processo externo |

## Ordem sugerida

1. `lucerna-sysinfo`: é o que mais roda (a aba Desempenho consulta a cada 2 s) e o que mais cria processos.
2. `lucerna-spectrum`: é a maior diferença visual em relação ao Caelestia.
3. Os demais, quando houver necessidade real.
