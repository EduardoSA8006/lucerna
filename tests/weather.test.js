// Testes de services/Weather: quando a previsão está velha (sem rede).
function run(t) {
    const W = t.Weather;

    // isStale() só lê updatedAt; o teste grava updatedAt diretamente. Guarda
    // o estado de antes para restaurar no fim (a suíte roda no mesmo processo
    // que as seguintes).
    const original = {
        updatedAt: W.updatedAt
    };

    t.test("weather: previsão velha", () => {
        W.updatedAt = null;
        t.check(W.isStale(), "sem previsão");
        W.updatedAt = new Date(0);
        t.check(W.isStale(), "de 1970");
        W.updatedAt = new Date(8640000000000000);
        t.check(!W.isStale(), "do futuro distante");
    });

    W.updatedAt = original.updatedAt;

    t.test("weather: estado original restaurado", () => {
        t.eq(W.updatedAt, original.updatedAt);
    });
}
