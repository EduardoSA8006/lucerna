// Testes de core/launcher/SearchEngines (só dados).
function run(t) {
    const all = t.SearchEngines.all;

    t.test("searchengines: ids únicos e buscas com um %s", () => {
        const ids = all.map(e => e.id);
        t.eq(new Set(ids).size, ids.length, "ids repetidos");
        for (const e of all)
            t.check(e.url.startsWith("https://") && e.url.split("%s").length === 2, `${e.id}: ${e.url}`);
    });

    t.test("searchengines: o buscador padrão da Config existe", () => {
        t.check(all.some(e => e.id === t.Config.launcherSearchEngine), t.Config.launcherSearchEngine);
    });
}
