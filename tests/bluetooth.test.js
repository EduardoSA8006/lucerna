// Testes de services/Bluetooth: dispositivo ocupado (isBusy só lê o
// parâmetro; nenhuma propriedade do singleton é gravada).
function run(t) {
    const B = t.Bluetooth;
    const e = t.enums;

    t.test("bluetooth: dispositivo ocupado", () => {
        t.check(B.isBusy({ pairing: true, state: e.btConnected }), "pareando");
        t.check(B.isBusy({ pairing: false, state: e.btConnecting }), "conectando");
        t.check(B.isBusy({ pairing: false, state: e.btDisconnecting }), "desconectando");
        t.check(!B.isBusy({ pairing: false, state: e.btConnected }), "conectado e parado");
    });
}
