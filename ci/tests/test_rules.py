"""Testes do ci/rules.py (rodam no job rules: python3 -m unittest discover -s ci/tests)."""

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import rules  # noqa: E402


class RepoCase(unittest.TestCase):
    def repo(self, files):
        """Cria um repositório de mentira: {caminho: conteúdo (str ou bytes)}."""
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        for rel, content in files.items():
            path = root / rel
            path.parent.mkdir(parents=True, exist_ok=True)
            if isinstance(content, bytes):
                path.write_bytes(content)
            else:
                path.write_text(content, encoding="utf-8")
        return root


class RepoFilesTest(RepoCase):
    def test_ignora_gitignore_e_pastas_de_saida(self):
        root = self.repo({
            ".gitignore": ".qmlls.ini\n*.qmlc\n.cache/\n",
            "shell.qml": "",
            ".qmlls.ini": "",
            "core/a.qmlc": "",
            ".cache/x.txt": "",
            "ci-out/lint/qmllint.log": "",
            "ci/__pycache__/rules.cpython-313.pyc": b"\0",
            "Lucerna — Proposta.md": "texto\n",
        })
        files = sorted(p.as_posix() for p in rules.repo_files(root))
        self.assertEqual(files, [".gitignore", "Lucerna — Proposta.md", "shell.qml"])


class LayersTest(RepoCase):
    def test_ui_nao_importa_services(self):
        root = self.repo({"features/bar/ui/Bar.qml": "import QtQuick\nimport qs.features.bar.state\nimport qs.services\n"})
        found = rules.check_layers(root)
        self.assertEqual([(p, n) for p, n, _ in found], [("features/bar/ui/Bar.qml", 3)])
        self.assertIn("qs.services", found[0][2])

    def test_state_pode_importar_services(self):
        root = self.repo({"features/bar/state/BarState.qml": "import qs.services\nimport qs.core.config\n"})
        self.assertEqual(rules.check_layers(root), [])

    def test_feature_nao_importa_outra(self):
        root = self.repo({"features/bar/state/BarState.qml": "import qs.features.dashboard.state\n"})
        found = rules.check_layers(root)
        self.assertEqual(len(found), 1)
        self.assertIn('"bar"', found[0][2])
        self.assertIn("qs.features.dashboard", found[0][2])

    def test_core_nao_importa_features_nem_services(self):
        root = self.repo({
            "core/panels/Panels.qml": "import qs.core.config\nimport qs.services\nimport qs.features.bar.state\n",
        })
        self.assertEqual([n for _, n, _ in rules.check_layers(root)], [2, 3])


class WhitespaceTest(RepoCase):
    def test_aponta_tab_espaco_no_fim_crlf_e_falta_de_quebra(self):
        root = self.repo({
            "a.sh": "echo\tx\n",
            "b.qml": "Item {  \n}\n",
            "c.md": "linha\r\noutra\r\n",
            "d.py": "x = 1",
        })
        found = {(p, n, m.split(" (")[0]) for p, n, m in rules.check_whitespace(root)}
        self.assertEqual(found, {
            ("a.sh", 1, "tab"),
            ("b.qml", 1, "espaço no fim da linha"),
            ("c.md", 1, "quebra de linha CRLF"),
            ("d.py", 1, "sem quebra de linha no fim do arquivo"),
        })

    def test_ignora_binarios_e_terceiros(self):
        root = self.repo({
            "docs/x.png": b"\x89PNG\0\0\t  ",
            "LICENSE": "texto com espaço no fim \n",
            "themes/fonts/Rubik-OFL.txt": "idem \n",
        })
        self.assertEqual(rules.check_whitespace(root), [])

    def test_le_nome_com_espaco_e_acento(self):
        root = self.repo({"Lucerna — Pendências.md": "ok \n"})
        self.assertEqual([(p, n) for p, n, _ in rules.check_whitespace(root)], [("Lucerna — Pendências.md", 1)])


class SegmentsTest(unittest.TestCase):
    def test_js_comentarios_e_strings(self):
        text = 'Item {\n    // comentário nao\n    property string a: "texto"\n    x: /"/g.test(b) ? `um\ndois` : 0\n}\n'
        segs = rules.js_segments(text)
        self.assertIn((2, " comentário nao"), segs)
        self.assertIn((3, "texto"), segs)
        self.assertIn((4, "um"), segs)
        self.assertIn((5, "dois"), segs)
        self.assertFalse(any('"' in s for _, s in segs), "a regex /\"/g não abre string")

    def test_sh_comentarios_e_strings_sem_confundir_cerquilha(self):
        segs = rules.sh_segments('echo "${#x} $#" # fim\nn=${v#pre}\n')
        self.assertEqual(segs, [(1, "${#x} $#"), (1, " fim")])

    def test_py_comentarios_e_strings(self):
        segs = rules.py_segments('x = "texto"  # nota\n')
        self.assertEqual([s for _, s in segs], ['"texto"', "# nota"])

    def test_md_pula_codigo_e_links(self):
        text = "Texto `nao` e [link](nao/so.md)\n````\n```\nnao\n```\n````\nfim https://x.so/ja\n"
        segs = rules.md_segments(text)
        self.assertEqual([n for n, _ in segs], [1, 7])
        self.assertNotIn("nao", " ".join(s for _, s in segs))


class AccentsTest(RepoCase):
    def test_acha_palavras_sem_acento(self):
        root = self.repo({
            "core/a.qml": 'Item {\n    // Nao faz nada\n    property string t: "so isso"\n}\n',
            "dev/b.sh": "# configuracao do ambiente\n",
            "c.py": "# funcao\n",
            "d.md": "Voce ja viu?\n",
        })
        found = {(p, n, m.split('"')[1]) for p, n, m in rules.check_accents(root)}
        self.assertEqual(found, {
            ("core/a.qml", 2, "Nao"),
            ("core/a.qml", 3, "so"),
            ("dev/b.sh", 1, "configuracao"),
            ("c.py", 1, "funcao"),
            ("d.md", 1, "Voce"),
            ("d.md", 1, "ja"),
        })

    def test_ignora_identificadores_caminhos_e_maiusculas(self):
        root = self.repo({
            "core/a.qml": 'Item {\n    property bool nao_existe: true\n    source: "lib/x.so"\n    // O SO do usuário\n}\n',
            "d.md": "Use `nao` e ja-JP\n",
        })
        self.assertEqual(rules.check_accents(root), [])


if __name__ == "__main__":
    unittest.main()
