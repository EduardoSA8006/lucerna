// Testes de services/Capture: a região no formato do grim e do wf-recorder.
function run(t) {
    t.test("capture: região arredondada no formato do grim", () => {
        t.eq(t.Capture.geometryArg({ x: 10.4, y: 20.6, width: 300.5, height: 200 }), "10,21 301x200");
        t.eq(t.Capture.geometryArg({ x: -1920, y: 0, width: 1920, height: 1080 }), "-1920,0 1920x1080");
    });
}
