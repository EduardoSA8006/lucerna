// Testes de services/Audio: o nome mostrado de um dispositivo (nodeName só lê
// o parâmetro; nenhuma propriedade do singleton é gravada).
function run(t) {
    const A = t.Audio;

    t.test("audio: nome do dispositivo", () => {
        t.eq(A.nodeName({ description: "Alto-falantes", nickname: "x", name: "y" }), "Alto-falantes");
        t.eq(A.nodeName({ description: "", nickname: "Fone", name: "y" }), "Fone");
        t.eq(A.nodeName({ name: "alsa_output.pci" }), "alsa_output.pci");
        t.eq(A.nodeName(null), "");
    });
}
