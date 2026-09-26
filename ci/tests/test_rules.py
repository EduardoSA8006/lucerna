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


if __name__ == "__main__":
    unittest.main()
