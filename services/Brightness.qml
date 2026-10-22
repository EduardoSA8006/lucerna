pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.services

// O brilho das telas, vindo do módulo power do lucernad: a tela integrada
// (pelo logind) e os monitores externos (por DDC/CI) com o valor real. As
// teclas ajustam a tela em foco; o daemon junta os ajustes. Sem o daemon,
// `screens` fica vazio.
Singleton {
    id: root

    // Não é readonly: os testes trocam por um cliente próprio.
    property var client: Lucernad.client
    // O error do power.status: o módulo pode estar parado com o daemon de pé.
    property string error: ""
    // Disponível é conectado e sem `error` (o `available` do status não diz
    // se o módulo funciona).
    readonly property bool available: client.connected && error === ""

    // As telas com brilho ajustável: [{ id, kind, label, output, value (0–1),
    // error }]. A integrada tem id "backlight"; os monitores, "ddc:<conector>".
    // Sem leitura, `value` é 0; uma tela com `error` fica na lista, fora do foco.
    property var screens: []
    // O valor da tela integrada (0 sem ela): o OSD observa.
    readonly property real value: screens.find(s => s.kind === "backlight")?.value ?? 0

    // A tela em foco (ver focusedId), reativa ao monitor e às telas; null se não há.
    readonly property var focusedScreen: screens.find(s => s.id === focusedId()) ?? null

    // A última ajustada, para o OSD mostrar o valor certo.
    property string lastId: "backlight"
    readonly property real shownValue: screens.find(s => s.id === lastId)?.value ?? value

    // Depois de um ajuste local, o valor que chega do daemon para aquela tela
    // é ignorado por esse tempo: o slider não volta no meio do arrasto.
    readonly property int holdMs: 1000
    // id → Date.now() do último ajuste local.
    property var holds: ({})

    // Emitido a cada pedido de ajuste, mesmo que o valor já esteja no limite.
    signal adjusted

    function wantedTopics(): var {
        return ["power.status", "power.screens"];
    }

    function sync(): void {
        client.want("power", wantedTopics());
    }

    // Uma tela do power.screens no formato do shell.
    function toScreen(s: var): var {
        return {
            id: String(s.id),
            kind: String(s.kind),
            label: String(s.name ?? ""),
            output: String(s.output ?? ""),
            value: typeof s.percent === "number" ? s.percent / 100 : 0,
            error: s.error ? String(s.error) : ""
        };
    }

    // As telas que chegam, mas com o valor local para as ajustadas há menos
    // de holdMs.
    function merged(incoming: var, local: var, holds: var, now: real): var {
        const mine = Array.from(local);
        return Array.from(incoming).map(s => {
            const held = holds[s.id] !== undefined && now - holds[s.id] < holdMs;
            const current = held ? mine.find(m => m.id === s.id) : undefined;
            return current ? Object.assign({}, s, {
                value: current.value
            }) : s;
        });
    }

    // Um estado recebido do daemon; `null` (o tópico ainda sem amostra) e
    // tópico desconhecido não mudam nada.
    function apply(topic: string, data: var): void {
        if (data === null || data === undefined)
            return;
        switch (topic) {
        case "power.screens":
            applyScreens(data);
            break;
        case "power.status":
            applyStatus(data);
            break;
        }
    }

    // O array que vem do sinal do cliente é uma lista do QML (Array.isArray
    // dá falso): vira array de JS antes do map.
    function applyScreens(data: var): void {
        const incoming = (data.screens ? Array.from(data.screens) : []).map(s => toScreen(s));
        screens = merged(incoming, screens, holds, Date.now());
    }

    // Com o módulo parado, as telas saem (um ajuste daria o erro 1002).
    function applyStatus(data: var): void {
        error = data.error ? String(data.error) : "";
        if (error !== "")
            screens = [];
    }

    // A conexão com o daemon mudou: ao cair, as telas somem; nos dois casos,
    // a assinatura vai de novo.
    function connectionChanged(connected: bool): void {
        if (!connected) {
            screens = [];
            error = "";
        }
        sync();
    }

    // A lista com o valor de uma tela trocado (a mesma lista se o id não existe).
    function withValue(list: var, id: string, value: real): var {
        const all = Array.from(list);
        if (!all.some(s => s.id === id))
            return list;
        return all.map(s => s.id === id ? Object.assign({}, s, {
            value: value
        }) : s);
    }

    // A resposta de um power.set ou power.change. O 1003 é a linha da tela
    // com erro: o texto vai para ela (sai do foco e o slider desabilita).
    function answered(id: string, response: var): void {
        const failure = response?.error;
        if (!failure)
            return;
        const message = String(failure.message ?? "erro desconhecido.");
        if (failure.code === 1003)
            screens = Array.from(screens).map(s => s.id === id ? Object.assign({}, s, {
                error: message
            }) : s);
        else
            console.warn(`Brightness: o ajuste de ${id} falhou: ${message}`);
    }

    // Guarda a hora do ajuste local de uma tela (o holdMs conta dela).
    function hold(id: string): void {
        const next = Object.assign({}, holds);
        next[id] = Date.now();
        holds = next;
    }

    function set(fraction: real): void {
        setScreen("backlight", fraction);
    }

    function setScreen(id: string, fraction: real): void {
        const f = Math.max(0.01, Math.min(1, fraction));
        screens = withValue(screens, id, f);
        hold(id);
        lastId = id;
        client.call("power.set", {
            id: id,
            percent: Math.round(f * 100)
        }, response => root.answered(id, response));
        adjusted();
    }

    // Tela em foco: a sem erro no monitor em foco do Hyprland; senão a
    // integrada sem erro; senão a primeira sem erro.
    function focusedId(): string {
        const name = Hyprland.focusedMonitor?.name ?? "";
        const usable = Array.from(screens).filter(s => s.error === "");
        const screen = (name ? usable.find(s => s.output === name) : undefined) ?? usable.find(s => s.kind === "backlight") ?? usable[0];
        return screen?.id ?? "";
    }

    // As teclas: o delta (limitado a ±1) vai ao daemon, que soma ao alvo
    // pendente; aqui o valor muda na hora.
    function change(delta: real): void {
        const screen = focusedScreen;
        if (!screen)
            return;
        const d = Math.max(-1, Math.min(1, delta));
        const id = screen.id;
        lastId = id;
        screens = withValue(screens, id, Math.max(0.01, Math.min(1, screen.value + d)));
        hold(id);
        client.call("power.change", {
            id: id,
            delta: Math.round(d * 100)
        }, response => root.answered(id, response));
        adjusted();
    }

    Connections {
        target: root.client

        function onReceived(topic: string, data: var): void {
            root.apply(topic, data);
        }

        function onConnectedChanged(): void {
            root.connectionChanged(root.client.connected);
        }
    }

    Component.onCompleted: sync()

    IpcHandler {
        target: "brightness"

        // A tela em foco.
        function up(): void {
            root.change(0.05);
        }

        function down(): void {
            root.change(-0.05);
        }

        function set(percent: int): void {
            const id = root.focusedId();
            if (id)
                root.setScreen(id, percent / 100);
        }

        // Uma tela específica: "backlight" ou "ddc:<conector>" (ver `list`).
        function setFor(id: string, percent: int): void {
            root.setScreen(id, percent / 100);
        }

        // Todas: "Tela integrada (backlight, eDP-1): 40%"; com erro, o erro
        // no lugar do percentual.
        function list(): string {
            return root.screens.map(s => `${s.label} (${s.id}${s.output ? `, ${s.output}` : ""}): ${s.error || `${Math.round(s.value * 100)}%`}`).join("\n");
        }
    }
}
