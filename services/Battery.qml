pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.core.config

// Bateria do notebook, via UPower. `available` é falso em desktops.
//
// No modo de desenvolvimento dá para simular a bateria por IPC, para testar
// avisos e automações sem tirar o notebook da tomada:
//   qs -c lucerna ipc call battery simulate 12 true   (12%, na bateria)
//   qs -c lucerna ipc call battery real
Singleton {
    id: root

    // { percentage (0-1), onBattery } ou null (valores reais)
    property var simulated: null

    readonly property UPowerDevice device: UPower.displayDevice
    readonly property bool available: simulated !== null || ((device?.ready ?? false) && device.isLaptopBattery && device.isPresent)
    readonly property real percentage: simulated ? simulated.percentage : (device?.percentage ?? 0)
    readonly property bool onBattery: simulated ? simulated.onBattery : UPower.onBattery
    readonly property bool charging: simulated ? !simulated.onBattery && simulated.percentage < 1 : (device?.state === UPowerDeviceState.Charging || device?.state === UPowerDeviceState.PendingCharge)
    readonly property bool full: simulated ? !simulated.onBattery && simulated.percentage >= 1 : device?.state === UPowerDeviceState.FullyCharged
    // Bateria baixa: no limite das configurações ou abaixo, e sem carregar (a
    // barra e a central mostram em vermelho). Arredondada como o aviso da
    // feature energy, para o vermelho e o aviso coincidirem.
    readonly property real low: Config.batteryLowLevel / 100
    readonly property bool isLow: Math.round(percentage * 100) / 100 <= low && !charging
    // Segundos até esvaziar (descarregando) ou encher (carregando); 0 se desconhecido.
    readonly property real timeRemaining: simulated ? 0 : charging ? (device?.timeToFull ?? 0) : (device?.timeToEmpty ?? 0)
    // Potência agora, em W: o consumo na bateria ou a carga na tomada (real
    // mesmo com a bateria simulada; 0 se o UPower não sabe).
    readonly property real rate: Math.abs(device?.changeRate ?? 0)

    // Consumo da última hora, para o gráfico da central: [{ time (s), value
    // (W) }], do mais antigo ao mais novo, e quando foi lido (historyAt, em s).
    // Vem do histórico do UPower (GetHistory "rate" no dispositivo da bateria;
    // o DisplayDevice não tem), pedido ao ligar `historyActive` (a central na
    // página da bateria) e a cada 60 s enquanto ele fica ligado. Sem esse
    // histórico, o shell junta uma amostra do `rate` a cada 30 s.
    property bool historyActive: false
    property var history: []
    property real historyAt: 0
    property bool upowerHistory: false
    readonly property int historySpan: 3600

    // A resposta do `busctl --json=short` ao GetHistory (a(udu): tempo, valor,
    // estado; o mais novo primeiro) em pontos do mais antigo ao mais novo. Fora
    // do formato, nenhum ponto.
    function parseHistory(text: string): var {
        let rows;
        try {
            rows = JSON.parse(text).data[0];
        } catch (e) {
            return [];
        }
        if (!Array.isArray(rows))
            return [];
        return rows.filter(r => Array.isArray(r) && typeof r[0] === "number" && typeof r[1] === "number" && r[1] >= 0).map(r => ({ time: r[0], value: r[1] })).sort((a, b) => a.time - b.time);
    }

    // A lista com a amostra no fim, sem as mais velhas que `span` segundos.
    function pushSample(list: var, sample: var, span: real): var {
        return [...list.filter(p => p.time >= sample.time - span), sample];
    }

    Timer {
        interval: 60000
        repeat: true
        triggeredOnStart: true
        running: root.historyActive && root.available
        onTriggered: historyQuery.running = true
    }

    // O dispositivo da bateria do notebook: o primeiro battery_* que alimenta o
    // sistema (os de fones e mouses não). Pelo sh, calado, como a sonda dos perfis.
    Process {
        id: historyQuery

        command: ["sh", "-c", `exec 2> /dev/null
command -v busctl > /dev/null || exit 1
for p in $(busctl --system --json=short call org.freedesktop.UPower /org/freedesktop/UPower org.freedesktop.UPower EnumerateDevices | grep -o '/org/freedesktop/UPower/devices/battery_[A-Za-z0-9_]*'); do
    busctl --system get-property org.freedesktop.UPower "$p" org.freedesktop.UPower.Device PowerSupply | grep -q true && exec busctl --system --json=short call org.freedesktop.UPower "$p" org.freedesktop.UPower.Device GetHistory suu rate ${root.historySpan} 120
done
exit 1`]
        stdout: StdioCollector {
            onStreamFinished: {
                const points = root.parseHistory(text);
                root.upowerHistory = points.length > 0;
                if (root.upowerHistory) {
                    root.history = points;
                    root.historyAt = Date.now() / 1000;
                }
            }
        }
    }

    // A amostra do shell, enquanto o UPower não dá o histórico.
    Timer {
        interval: 30000
        repeat: true
        triggeredOnStart: true
        running: root.available && !root.upowerHistory
        onTriggered: {
            root.historyAt = Date.now() / 1000;
            root.history = root.pushSample(root.history, { time: root.historyAt, value: root.rate }, root.historySpan);
        }
    }

    // Perfil de energia (power-profiles-daemon): 0 economia, 1 equilibrado, 2 desempenho (o "Turbo").
    // No modo de desenvolvimento a troca é simulada, e o perfil simulado fica aqui.
    property int simulatedProfile: -1
    readonly property int profile: simulatedProfile >= 0 ? simulatedProfile : PowerProfiles.profile
    readonly property bool hasPerformance: PowerProfiles.hasPerformanceProfile
    readonly property var profileNames: ["Economia", "Equilibrado", "Turbo"]

    // O power-profiles-daemon responde no D-Bus do sistema? O PowerProfiles do
    // Quickshell não diz; sem ele, a central esconde os botões de perfil. Pelo
    // sh: sem busctl ou sem o D-Bus do sistema (o CI), sai com erro, calado.
    property bool profilesAvailable: false

    Process {
        running: true
        command: ["sh", "-c", "command -v busctl > /dev/null && { busctl --system introspect net.hadess.PowerProfiles /net/hadess/PowerProfiles || busctl --system introspect org.freedesktop.UPower.PowerProfiles /org/freedesktop/UPower/PowerProfiles; } > /dev/null 2>&1"]
        onExited: code => root.profilesAvailable = code === 0
    }

    function setProfile(value: int): void {
        if (value === profile)
            return;
        if (DevMode.simulate(`Perfil ${profileNames[value] ?? value}`))
            simulatedProfile = value;
        else
            PowerProfiles.profile = value;
    }

    IpcHandler {
        target: "battery"
        enabled: DevMode.active

        // Simula a bateria (percentual de 0 a 100; na bateria ou na tomada).
        function simulate(percent: int, onBattery: bool): void {
            root.simulated = { percentage: Math.max(0, Math.min(100, percent)) / 100, onBattery: onBattery };
        }

        // Volta aos valores reais.
        function real(): void {
            root.simulated = null;
        }
    }
}
