// Testes de services/AppInfo: entidades e cache (sem o app-info.sh).
function run(t) {
    const A = t.AppInfo;

    // info() só lê cache; o teste grava cache diretamente. Guarda o estado de
    // antes para restaurar no fim (a suíte roda no mesmo processo que as
    // seguintes).
    const original = {
        cache: A.cache
    };

    t.test("appinfo: entidades do AppStream", () => {
        t.eq(A.decodeEntities("a &lt;b&gt; &quot;c&quot; &#39;d&apos; &amp;lt;"), "a <b> \"c\" 'd' &lt;");
    });

    t.test("appinfo: cache por app", () => {
        A.cache = { kitty: { version: "0.40" } };
        t.eq(A.info("kitty"), { version: "0.40" });
        t.eq(A.info("nada"), null);
    });

    A.cache = original.cache;

    t.test("appinfo: estado original restaurado", () => {
        t.eq(A.cache, original.cache);
    });
}
