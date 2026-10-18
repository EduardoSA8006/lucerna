import QtQuick
import Quickshell
import Quickshell.Io

// Backend do espectro pelo `cava` (dependência opcional). Quem usa pede com
// start() e stop(); cada quadro sai em `frame`, de 0 a 1 por barra, das graves
// às agudas, e uma saída do cava que não foi pedida sai em `stopped`. A config
// é gerada aqui, sem tocar na do usuário: as barras, o framerate e a saída
// crua em texto pelo stdout, num arquivo próprio da sessão (com o PID no
// nome), apagado quando o cava sai.
Scope {
    id: root

    property int bars: 32
    property int framerate: 30
    // O cava está no PATH.
    property bool installed: false
    // Pedido por start(), até stop().
    property bool wanted: false

    signal frame(var values)
    signal stopped(int code)

    function start(): void {
        wanted = true;
        if (installed)
            process.running = true;
    }

    function stop(): void {
        wanted = false;
        process.running = false;
    }

    onInstalledChanged: {
        if (installed && wanted)
            process.running = true;
    }

    // A config do cava: saída "raw" em ASCII, mono, cada quadro numa linha,
    // as barras separadas por ";" e de 0 a 1000.
    function configFor(bars: int, framerate: int): string {
        return ["[general]", `bars = ${bars}`, `framerate = ${framerate}`, "", "[output]", "method = raw", "raw_target = /dev/stdout", "data_format = ascii", "ascii_max_range = 1000", "bar_delimiter = 59", "frame_delimiter = 10", "channels = mono", ""].join("\n");
    }

    // Um quadro ("12;400;1000;") em [0..1] por barra; um quadro incompleto ou
    // inválido devolve null (fica o anterior).
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
        onExited: code => root.installed = code === 0
    }

    Process {
        id: process

        // A config no XDG_RUNTIME_DIR (ou, sem ele, no mktemp), apagada na
        // saída; o pdeathsig faz o cava sair junto com o shell.
        command: ["sh", "-c", `d="\${XDG_RUNTIME_DIR:-}"
if [ -n "$d" ] && [ -d "$d" ] && [ -w "$d" ]; then f="$d/lucerna-cava-$$.conf"; else f=$(mktemp) || exit 1; fi
trap 'rm -f "$f"' EXIT
trap 'kill "$pid" 2> /dev/null; exit 143' TERM INT
printf '%s' "$1" > "$f" || exit 1
setpriv --pdeathsig TERM cava -p "$f" 2> /dev/null &
pid=$!
wait "$pid"`, "sh", root.configFor(root.bars, root.framerate)]
        stdout: SplitParser {
            onRead: line => {
                const values = root.parse(line, root.bars);
                if (values)
                    root.frame(values);
            }
        }
        onExited: code => {
            if (root.wanted)
                root.stopped(code);
        }
    }
}
