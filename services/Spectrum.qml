pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Espectro do áudio que está tocando, pelo `cava` (dependência opcional), para
// visualizadores: `values` traz uma faixa de frequência por barra, de 0 a 1,
// das graves às agudas. O cava só roda enquanto `active` (quem mostra pede) e
// com ele no PATH (`available`). A config é gerada aqui, sem tocar na do
// usuário: as barras, o framerate e a saída crua em texto pelo stdout.
Singleton {
    id: root

    property bool active: false
    property bool available: false
    readonly property int bars: 32
    readonly property int framerate: 45
    // [0..1] por barra; parado, fica o último quadro (quem mostra recolhe).
    property var values: []

    // A config do cava: saída "raw" em ASCII, mono, cada quadro numa linha,
    // as barras separadas por ";" e de 0 a 1000.
    function configFor(bars: int, framerate: int): string {
        return ["[general]", `bars = ${bars}`, `framerate = ${framerate}`, "", "[output]", "method = raw", "raw_target = /dev/stdout", "data_format = ascii", "ascii_max_range = 1000", "bar_delimiter = 59", "frame_delimiter = 10", "channels = mono", ""].join("\n");
    }

    // Um quadro ("12;400;1000;") em [0..1] por barra; um quadro incompleto ou
    // inválido devolve null (o anterior fica).
    function parse(line: string, bars: int): var {
        const parts = String(line).split(";").filter(p => p.trim() !== "");
        if (parts.length !== bars)
            return null;
        const values = parts.map(p => Number(p) / 1000);
        return values.every(v => isFinite(v)) ? values.map(v => Math.max(0, Math.min(1, v))) : null;
    }

    // Tem o cava? Sem ele, nada roda e nada vai para o log.
    Process {
        running: true
        command: ["sh", "-c", "command -v cava > /dev/null"]
        onExited: code => root.available = code === 0
    }

    Process {
        running: root.active && root.available
        // A config vai para um arquivo da sessão; o pdeathsig faz o cava sair
        // junto com o shell.
        command: ["sh", "-c", "f=\"${XDG_RUNTIME_DIR:-/tmp}/lucerna-cava.conf\"; printf '%s' \"$1\" > \"$f\" && exec setpriv --pdeathsig TERM cava -p \"$f\" 2> /dev/null", "sh", root.configFor(root.bars, root.framerate)]
        stdout: SplitParser {
            onRead: line => {
                const values = root.parse(line, root.bars);
                if (values)
                    root.values = values;
            }
        }
    }
}
