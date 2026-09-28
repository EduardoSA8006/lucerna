// Testes de services/Network: segurança da rede Wi-Fi (isSecure e
// needsPassword só leem os parâmetros; nenhuma propriedade do singleton é gravada).
function run(t) {
    const N = t.Network;
    const e = t.enums;
    const wpa = 1000; // qualquer tipo que não seja aberto nem OWE

    t.test("network: rede segura", () => {
        t.check(!N.isSecure({ security: e.wifiOpen }), "aberta");
        t.check(!N.isSecure({ security: e.wifiOwe }), "OWE, sem senha");
        t.check(N.isSecure({ security: wpa }), "com senha");
    });

    t.test("network: pede senha só para rede nova e protegida", () => {
        t.check(N.needsPassword({ known: false, security: wpa }), "nova e protegida");
        t.check(!N.needsPassword({ known: true, security: wpa }), "conhecida");
        t.check(!N.needsPassword({ known: false, security: e.wifiOpen }), "aberta");
    });
}
