// Testes de services/Notifications: popups e prazos (sem o servidor D-Bus).
function run(t) {
    const N = t.Notifications;
    const e = t.enums;

    // hidePopup()/clearPopups() gravam popups; o teste também grava popups e
    // receivedAt diretamente. Guarda o estado de antes para restaurar no fim
    // (a suíte roda no mesmo processo que as seguintes).
    const original = {
        popups: N.popups,
        receivedAt: N.receivedAt
    };

    t.test("notifications: tirar e limpar os popups", () => {
        N.popups = ["a", "b", "c"];
        N.hidePopup("b");
        t.eq(N.popups, ["a", "c"]);
        N.clearPopups();
        t.eq(N.popups, []);
    });

    t.test("notifications: tempo do popup na tela", () => {
        t.eq(N.timeoutFor({ urgency: e.urgencyCritical, expireTimeout: 3000 }), 0, "crítica fica até fechar");
        t.eq(N.timeoutFor({ urgency: e.urgencyNormal, expireTimeout: 3000 }), 3000, "prazo do app");
        t.eq(N.timeoutFor({ urgency: e.urgencyNormal, expireTimeout: 0 }), N.defaultTimeout, "sem prazo, o padrão");
        t.eq(N.timeoutFor({ urgency: e.urgencyNormal, expireTimeout: -1 }), N.defaultTimeout);
    });

    t.test("notifications: horário de chegada guardado", () => {
        N.receivedAt = { 7: 1767225600000 };
        t.eq(N.timeOf({ id: 7 }).getTime(), 1767225600000);
    });

    N.popups = original.popups;
    N.receivedAt = original.receivedAt;

    t.test("notifications: estado original restaurado", () => {
        t.eq([N.popups, N.receivedAt], [original.popups, original.receivedAt]);
    });
}
