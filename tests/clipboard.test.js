// Testes de services/Clipboard: só a decodificação (o resto chama processo).
function run(t) {
    const C = t.Clipboard;

    t.test("clipboard: base64 para texto UTF-8", () => {
        t.eq(C.decode("T2zDoSwgbXVuZG8h"), "Olá, mundo!");
        t.eq(C.decode("YcOnw6NvIPCfmIA="), "ação 😀");
        t.eq(C.decode("bGluaGEgMQpsaW5oYSAy"), "linha 1\nlinha 2");
    });

    t.test("clipboard: ignora o que não é base64", () => {
        t.eq(C.decode("T2zD\noSwg bXVuZG8h"), "Olá, mundo!");
    });

    t.test("clipboard: vazio", () => {
        t.eq(C.decode(""), "");
    });
}
