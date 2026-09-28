"""Testes do ci/coverage.py."""

import contextlib
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import coverage  # noqa: E402

QML = """pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    function open(name: string): void {
        opened = [name];
    }

    component Tokens: QtObject {
        property int a
    }

    IpcHandler {
        target: "panels"

        function open(name: string): void {
            root.open(name);
        }
    }

    Connections {
        function onRawEvent(event) {
        }
    }

    Connections {
        function onRawEvent(event) {
        }
    }
}
"""

SCOPE = {
    "escopo": "core/",
    "fora": {"core/widgets/": "interface"},
    "serviços": {"services/S.qml": ["parse"]},
    "exceções": {"core/p/P.qml:IpcHandler.open": "IPC"},
}


def functions(*keys):
    return [{"key": k, "name": k.split(":")[1], "line": 1, "indent": 4} for k in keys]


class ParseTest(unittest.TestCase):
    def test_chaves_com_objeto_em_volta_e_repetidas(self):
        found, errors = coverage.parse_functions("core/p/P.qml", QML)
        self.assertEqual(errors, [])
        self.assertEqual(
            [f["key"] for f in found],
            [
                "core/p/P.qml:open",
                "core/p/P.qml:IpcHandler.open",
                "core/p/P.qml:Connections.onRawEvent",
                "core/p/P.qml:Connections.onRawEvent#2",
            ],
        )

    def test_comentario_fora_da_indentacao_nao_muda_o_objeto(self):
        text = "Item {\n    IpcHandler {\n// solto na coluna 0\n        function get(): string {\n        }\n    }\n}\n"
        found, errors = coverage.parse_functions("a.qml", text)
        self.assertEqual((errors, [f["key"] for f in found]), ([], ["a.qml:IpcHandler.get"]))

    def test_funcao_fora_do_padrao_e_erro(self):
        _, errors = coverage.parse_functions("a.qml", "Item {\n    function x() { return 1; }\n}\n")
        self.assertEqual(len(errors), 1)
        self.assertIn("a.qml:2", errors[0])
        self.assertIn("fora do padrão", errors[0])


class InstrumentTest(unittest.TestCase):
    def test_hit_na_primeira_linha_e_import(self):
        text, found, errors = coverage.instrument_text("core/p/P.qml", QML)
        lines = text.split("\n")
        self.assertEqual(errors, [])
        self.assertEqual(lines[4], "import qs.cov")
        i = lines.index("    function open(name: string): void {")
        self.assertEqual(lines[i + 1], '        Cov.hit("core/p/P.qml:open");')
        self.assertIn('            Cov.hit("core/p/P.qml:IpcHandler.open");', lines)
        self.assertEqual(len(found), 4)

    def test_arquivo_sem_funcao_fica_igual(self):
        text = "import QtQuick\n\nItem {}\n"
        self.assertEqual(coverage.instrument_text("a.qml", text)[0], text)

    def test_runner_ganha_o_dump(self):
        runner = "import QtQuick\n\nItem {\n    Component.onCompleted: {\n        // @cov-dump\n    }\n}\n"
        text, found, errors = coverage.instrument_text("tests/runner.qml", runner, hits=False, runner=True)
        self.assertEqual((found, errors), ([], []))
        self.assertIn("        Cov.dump();", text)
        self.assertIn("import qs.cov", text)
        _, _, errors = coverage.instrument_text("tests/runner.qml", "import QtQuick\n", hits=False, runner=True)
        self.assertEqual(len(errors), 1)

    def test_recusa_o_repositorio(self):
        with tempfile.TemporaryDirectory() as tmp:
            (Path(tmp) / ".git").mkdir()
            with contextlib.redirect_stderr(io.StringIO()):
                self.assertEqual(coverage.instrument(Path(tmp), False), 1)


class InstrumentFolderTest(unittest.TestCase):
    RUNNER = "import QtQuick\n\nItem {\n    Component.onCompleted: {\n        // @cov-dump\n    }\n}\n"
    BAD = "import QtQuick\n\nItem {\n    function x() { return 1; }\n}\n"

    def copy(self, files):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        files = dict({"tests/coverage.json": json.dumps(SCOPE), "tests/runner.qml": self.RUNNER}, **files)
        for rel, content in files.items():
            (root / rel).parent.mkdir(parents=True, exist_ok=True)
            (root / rel).write_text(content, encoding="utf-8")
        return root

    def run_instrument(self, root, everything):
        err, out = io.StringIO(), io.StringIO()
        with contextlib.redirect_stderr(err), contextlib.redirect_stdout(out):
            code = coverage.instrument(root, everything)
        return code, err.getvalue(), out.getvalue()

    def test_escopo_instrumenta_so_o_escopo(self):
        root = self.copy({"core/p/P.qml": QML, "features/x/X.qml": self.BAD, "services/T.qml": QML})
        code, err, _ = self.run_instrument(root, False)
        self.assertEqual((code, err), (0, ""))
        self.assertEqual((root / "features/x/X.qml").read_text(encoding="utf-8"), self.BAD)
        self.assertEqual((root / "services/T.qml").read_text(encoding="utf-8"), QML)
        self.assertIn('Cov.hit("core/p/P.qml:open");', (root / "core/p/P.qml").read_text(encoding="utf-8"))
        keys = [f["key"] for f in json.loads((root / "cov/functions.json").read_text(encoding="utf-8"))]
        self.assertEqual(len(keys), 4)
        self.assertEqual((root / "cov/Cov.qml").read_text(encoding="utf-8"), coverage.COV_QML)

    def test_all_aponta_funcao_fora_do_padrao_em_features(self):
        root = self.copy({"core/p/P.qml": QML, "features/x/X.qml": self.BAD})
        code, err, _ = self.run_instrument(root, True)
        self.assertEqual(code, 1)
        self.assertIn("ERRO: features/x/X.qml:4: função fora do padrão", err)

    def test_funcao_fora_do_padrao_no_escopo_falha(self):
        root = self.copy({"core/p/P.qml": self.BAD})
        code, err, _ = self.run_instrument(root, False)
        self.assertEqual(code, 1)
        self.assertIn("ERRO: core/p/P.qml:4: função fora do padrão", err)

    def test_sem_coverage_json_falha_com_mensagem(self):
        root = self.copy({"core/p/P.qml": QML})
        (root / "tests/coverage.json").unlink()
        code, err, _ = self.run_instrument(root, False)
        self.assertEqual(code, 1)
        self.assertIn("tests/coverage.json", err)

    def test_coverage_json_sem_chave_falha_com_mensagem(self):
        root = self.copy({"core/p/P.qml": QML, "tests/coverage.json": json.dumps({"escopo": "core/"})})
        code, err, _ = self.run_instrument(root, False)
        self.assertEqual(code, 1)
        self.assertIn('tests/coverage.json: falta a chave "fora"', err)


class BlockingTest(unittest.TestCase):
    def test_escopo_fora_servicos_e_excecoes(self):
        found = functions(
            "core/p/P.qml:open", "core/p/P.qml:IpcHandler.open", "core/widgets/W.qml:click",
            "services/S.qml:parse", "services/S.qml:run",
        )  # fmt: skip
        wanted, errors = coverage.blocking(found, SCOPE)
        self.assertEqual(errors, [])
        self.assertEqual(wanted, {"core/p/P.qml:open", "services/S.qml:parse"})

    def test_entradas_desatualizadas_sao_erro(self):
        scope = dict(SCOPE, **{"serviços": {"services/S.qml": ["sumiu"]}, "exceções": {"core/p/P.qml:velha": "x"}})
        _, errors = coverage.blocking(functions("core/p/P.qml:open", "services/S.qml:parse"), scope)
        self.assertEqual(len(errors), 2)
        self.assertIn("services/S.qml:sumiu", errors[0])
        self.assertIn("core/p/P.qml:velha", errors[1])

    def test_excecao_sem_motivo_e_erro(self):
        scope = dict(SCOPE, **{"serviços": {}, "exceções": {"core/p/P.qml:IpcHandler.open": " "}})
        _, errors = coverage.blocking(functions("core/p/P.qml:IpcHandler.open"), scope)
        self.assertEqual(len(errors), 1)


class ReportTest(unittest.TestCase):
    def folder(self, keys, log, scope=SCOPE):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        (root / "cov").mkdir()
        (root / "tests").mkdir()
        (root / "cov" / "functions.json").write_text(json.dumps(functions(*keys)))
        (root / "tests" / "coverage.json").write_text(json.dumps(scope, ensure_ascii=False))
        (root / "unit.log").write_text(log)
        return root

    def run_report(self, root, gate):
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            code = coverage.report(root, [root / "unit.log"], gate, root / "coverage.md")
        return code, out.getvalue()

    # A exceção do SCOPE (IpcHandler.open) precisa existir entre as funções.
    KEYS = ["core/p/P.qml:open", "core/p/P.qml:IpcHandler.open", "services/S.qml:parse"]

    def test_gate_passa_com_tudo_chamado(self):
        root = self.folder(self.KEYS, "COV core/p/P.qml:open 2\nCOV services/S.qml:parse 1\n")
        code, text = self.run_report(root, True)
        self.assertEqual(code, 0, text)
        self.assertIn("2/2", text)
        self.assertIn("| core/p/P.qml |", (root / "coverage.md").read_text())

    def test_gate_falha_com_funcao_sem_chamada(self):
        root = self.folder(self.KEYS, "COV core/p/P.qml:open 2\n")
        code, text = self.run_report(root, True)
        self.assertEqual(code, 1)
        self.assertIn("sem chamada: parse", text)

    def test_informativo_nao_falha(self):
        root = self.folder(["core/p/P.qml:open", "features/x/X.qml:go"], "")
        code, text = self.run_report(root, False)
        self.assertEqual(code, 0)
        self.assertIn("0/2", text)
        self.assertIn("AVISO: nenhuma linha COV", text)

    def test_gate_falha_sem_nenhuma_linha_cov(self):
        root = self.folder(self.KEYS, "RESULT passed=3 failed=0\n")
        code, text = self.run_report(root, True)
        self.assertEqual(code, 1)
        self.assertIn("ERRO: nenhuma linha COV", text)

    def test_gate_falha_com_coverage_json_desatualizado(self):
        # Tudo o que existe foi chamado; mesmo assim, as entradas velhas reprovam.
        scope = dict(
            SCOPE, **{"serviços": {"services/S.qml": ["parse", "renomeada"]}, "exceções": {"core/p/P.qml:foi": "x"}}
        )
        log = "COV core/p/P.qml:open 2\nCOV core/p/P.qml:IpcHandler.open 1\nCOV services/S.qml:parse 1\n"
        root = self.folder(self.KEYS, log, scope)
        code, text = self.run_report(root, True)
        self.assertEqual(code, 1)
        self.assertIn("3/3", text)
        self.assertIn(
            "ERRO: tests/coverage.json: services/S.qml:renomeada não existe (a função mudou de nome ou saiu?)", text
        )
        self.assertIn("ERRO: tests/coverage.json: a exceção core/p/P.qml:foi não corresponde a nenhuma função", text)
        # Nenhuma função ficou sem chamada: a mensagem não pode mandar escrever teste.
        self.assertNotIn("precisa ser chamada por um teste", text)
        md = (root / "coverage.md").read_text(encoding="utf-8")
        self.assertIn("- tests/coverage.json: services/S.qml:renomeada não existe", md)

    def test_linha_cov_no_meio_de_outra_mensagem_nao_conta(self):
        log = "  ERROR qml: FAIL x: esperado COV services/S.qml:parse 1\n  INFO qml: COV core/p/P.qml:open 2\n"
        root = self.folder(self.KEYS, log)
        code, text = self.run_report(root, True)
        self.assertEqual(code, 1)
        self.assertIn("sem chamada: parse", text)

    def test_gate_falha_com_escopo_vazio(self):
        scope = dict(SCOPE, **{"serviços": {}, "exceções": {}})
        root = self.folder(["features/x/X.qml:go"], "COV features/x/X.qml:go 1\n", scope)
        code, text = self.run_report(root, True)
        self.assertEqual(code, 1)
        self.assertIn("0/0", text)
        self.assertIn("o escopo que bloqueia tem 0 funções", text)


if __name__ == "__main__":
    unittest.main()
