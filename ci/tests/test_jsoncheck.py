"""Testes do ci/jsoncheck.py."""

import contextlib
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import jsoncheck  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]


def theme(**changes):
    data = {
        "name": "Teste",
        "colors": {c: "#112233" for c in jsoncheck.COLORS},
        "font": {
            "sans": "Rubik",
            "mono": "Mono",
            "icon": "Material Symbols Rounded",
            "size": {"small": 11, "normal": 13, "large": 16, "huge": 44},
        },
        "wallpaper": {"static": "wallpapers/t.jpg", "shader": "shaders/t.qsb"},
        "hyprland": {k: 1 for k in jsoncheck.HYPRLAND},
        "fonts": ["fonts/F.ttf"],
    }
    data.update(changes)
    return data


class JsonCheckTest(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.themes = Path(tmp.name) / "themes"
        for rel in ("wallpapers/t.jpg", "shaders/t.qsb", "fonts/F.ttf"):
            (self.themes / rel).parent.mkdir(parents=True, exist_ok=True)
            (self.themes / rel).write_bytes(b"\0")

    def test_tema_completo(self):
        self.assertEqual(jsoncheck.check_theme(theme(), self.themes), [])

    def test_track_e_opcional(self):
        colors = dict(theme()["colors"], track="#445566")
        self.assertEqual(jsoncheck.check_theme(theme(colors=colors), self.themes), [])

    def test_faltam_cores(self):
        colors = {c: "#112233" for c in jsoncheck.COLORS if c not in ("surface", "raised")}
        self.assertEqual(jsoncheck.check_theme(theme(colors=colors), self.themes), ["faltam as cores surface, raised"])

    def test_cor_fora_do_formato(self):
        colors = dict(theme()["colors"], accent="roxo")
        self.assertEqual(
            jsoncheck.check_theme(theme(colors=colors), self.themes), ["cores fora do formato #rrggbb: accent"]
        )

    def test_arquivo_citado_que_falta(self):
        found = jsoncheck.check_theme(theme(wallpaper="wallpapers/nada.jpg"), self.themes)
        self.assertEqual(found, ["aponta para um arquivo que não existe: wallpapers/nada.jpg"])

    def test_faltam_hyprland_e_font(self):
        data = theme(font={"sans": "Rubik"})
        del data["hyprland"]
        self.assertEqual(
            jsoncheck.check_theme(data, self.themes), ["faltam em font: mono, icon, size", 'falta "hyprland"']
        )

    def test_efeitos(self):
        effects = [
            {"id": "a", "name": "A", "shader": "shaders/t.qsb"},
            {"id": "a", "name": "B", "shader": "shaders/t.qsb"},
            {"id": "c", "name": "C", "shader": "shaders/c.qsb"},
            {"id": "d", "name": "D", "shader": "shaders/d.frag"},
        ]
        self.assertEqual(
            jsoncheck.check_effects(effects, self.themes),
            [
                'efeito "a" repetido',
                'efeito "c": shaders/c.qsb não existe',
                'efeito "d": o shader precisa ser um .qsb (shaders/d.frag)',
            ],
        )

    def test_efeitos_vazio_e_erro(self):
        self.assertEqual(jsoncheck.check_effects([], self.themes), ["a lista de efeitos está vazia"])

    def run_main(self):
        with contextlib.redirect_stdout(io.StringIO()) as out:
            code = jsoncheck.main([str(self.themes)])
        return code, out.getvalue()

    def test_zero_temas_reprova(self):
        (self.themes / "shaders" / "effects.json").write_text(
            json.dumps([{"id": "a", "name": "A", "shader": "shaders/t.qsb"}]), encoding="utf-8"
        )
        code, out = self.run_main()
        self.assertEqual(code, 1)
        self.assertIn("nenhum tema", out)

    def test_effects_json_vazio_reprova(self):
        (self.themes / "t.json").write_text(json.dumps(theme()), encoding="utf-8")
        (self.themes / "shaders" / "effects.json").write_text("[]", encoding="utf-8")
        code, out = self.run_main()
        self.assertEqual(code, 1)
        self.assertIn("vazia", out)

    def test_temas_do_repositorio(self):
        self.assertEqual(jsoncheck.main([str(ROOT / "themes")]), 0)


if __name__ == "__main__":
    unittest.main()
