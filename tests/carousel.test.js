// Testes de core/carousel/Carousel: a volta do índice, a distância até o
// centro na fila circular e o deslocamento dos cards na tela.
function run(t) {
    const K = t.Carousel;

    t.test("carousel: volta do índice nos dois sentidos", () => {
        t.eq([K.wrap(0, 5), K.wrap(4, 5), K.wrap(5, 5), K.wrap(-1, 5), K.wrap(-6, 5), K.wrap(11, 5)], [0, 4, 0, 4, 4, 1]);
        t.eq([K.wrap(3, 1), K.wrap(-2, 1)], [0, 0], "fila de um");
        t.eq(K.wrap(2, 0), 0, "fila vazia");
    });

    t.test("carousel: distância até o centro pelo caminho mais curto", () => {
        t.eq([0, 1, 2, 3, 4].map(i => K.offset(i, 0, 5)), [0, 1, 2, -2, -1]);
        t.eq([0, 1, 2, 3, 4].map(i => K.offset(i, 4, 5)), [1, 2, -2, -1, 0], "centro no último");
        t.eq([K.offset(6, 0, 12), K.offset(7, 0, 12)], [6, -5], "empate em fila par vai para a direita");
        t.eq(K.offset(0, 0, 1), 0, "fila de um");
        t.eq([K.offset(1, 0, 2), K.offset(0, 1, 2)], [1, 1], "fila de dois: o outro fica sempre à direita");
        t.eq(K.offset(0, 0, 0), 0, "fila vazia");
    });

    t.test("carousel: deslocamento dos cards", () => {
        t.eq(K.spread(0, 320, 20, 0.8), 0);
        t.near(K.spread(1, 320, 20, 0.8), 308, 0.01, "metade do central, metade do vizinho e o vão");
        t.near(K.spread(-1, 320, 20, 0.8), -308, 0.01);
        t.near(K.spread(2, 320, 20, 0.8), 558.4, 0.01);
        t.near(K.spread(-3, 320, 20, 0.8), -762.72, 0.01);
    });
}
