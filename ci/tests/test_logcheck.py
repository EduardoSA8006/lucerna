"""Testes do ci/logcheck.py, inclusive contra o ci/tolerated.txt de verdade."""

import re
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import logcheck  # noqa: E402

TOLERATED = Path(__file__).resolve().parents[1] / "tolerated.txt"

# Linhas medidas na sonda (sway headless, sem D-Bus do sistema, sem PipeWire).
ENVIRONMENT = [
    "  WARN: $HYPRLAND_INSTANCE_SIGNATURE is unset. Cannot connect to hyprland.",
    "  WARN quickshell.network.networkmanager: Could not connect to DBus. NetworkManager backend will not work.",
    " ERROR quickshell.network: Network will not work. Could not find an available backend.",
    "  WARN quickshell.service.upower: Could not connect to DBus. UPower service will not work.",
    "  WARN quickshell.service.powerprofiles: Could not connect to DBus. PowerProfiles services will not work.",
    " ERROR quickshell.service.pipewire.loop: Failed to connect pipewire context. Errno: 112",
    "  WARN: The active compositor does not support the hyprland_focus_grab_v1 protocol. HyprlandFocusGrab will not work.",
    "  WARN: ** Learn why $XDG_CURRENT_DESKTOP sucks and download a better compositor today at https://hyprland.org",
    "MESA: error: ZINK: failed to choose pdev",
    "00:00:00.120 [ERROR] [sway/main.c:120] failed to execute 'swaybg': No such file or directory",
]

# Erros do shell de verdade: nunca podem passar.
REAL_ERRORS = [
    "  WARN scene: @features/bar/ui/Bar.qml[12:5]: TypeError: Cannot read property 'x' of null",
    "  WARN scene: @core/widgets/Icon.qml[3:1]: ReferenceError: foo is not defined",
    "  WARN qt.qml: file:///x/Osd.qml:3: Unable to assign [undefined] to QString",
    " ERROR quickshell.dbus.properties: Error updating property in DBus while connecting",
]


class LoadTest(unittest.TestCase):
    def test_bloco_com_motivo(self):
        patterns, errors = logcheck.load_tolerated("# cabeçalho\n\n# motivo\nabc\ndef\n")
        self.assertEqual((len(patterns), errors), (2, []))

    def test_padrao_sem_motivo_e_erro(self):
        _, errors = logcheck.load_tolerated("# cabeçalho\n\nsem motivo\n")
        self.assertEqual(errors, ["padrão sem motivo: sem motivo"])

    def test_padrao_invalido_e_erro(self):
        _, errors = logcheck.load_tolerated("# motivo\n(\n")
        self.assertEqual(len(errors), 1)
        self.assertIn("padrão inválido", errors[0])


class ProblemsTest(unittest.TestCase):
    def test_so_aviso_e_erro_contam_e_ansi_sai(self):
        log = "  INFO: Configuration Loaded\n\x1b[33m  WARN\x1b[0m x: algo\n DEBUG y\n"
        self.assertEqual(logcheck.problems(log, []), [(2, "WARN x: algo")])

    def test_erro_sem_nivel_e_pego_por_xyzerror(self):
        # Sem WARN/ERROR nenhum: só o "ReferenceError:" já classifica a linha.
        log = "algo: ReferenceError: foo is not defined\n"
        self.assertEqual(logcheck.problems(log, []), [(1, "algo: ReferenceError: foo is not defined")])

    def test_erro_sem_nivel_e_pego_por_referencia_qml(self):
        # Sem WARN/ERROR nem "Error:": só a referência a arquivo.qml:NN classifica.
        log = "INFO qml: @X.qml:42: parou de responder\n"
        self.assertEqual(logcheck.problems(log, []), [(1, "INFO qml: @X.qml:42: parou de responder")])

    def test_padrao_tolerado_nao_bate_so_parte_da_linha(self):
        # Um padrão que bateria com um pedaço da linha (busca livre) não deve
        # tolerar quando a linha inteira é outra coisa: fullmatch, não search.
        log = "WARN: prefixo $HYPRLAND_INSTANCE_SIGNATURE is unset. Cannot connect to hyprland. sufixo\n"
        patterns = [re.compile(r"\$HYPRLAND_INSTANCE_SIGNATURE is unset")]
        self.assertEqual(logcheck.problems(log, patterns), [(1, log.strip())])


class ToleratedFileTest(unittest.TestCase):
    def setUp(self):
        self.patterns, errors = logcheck.load_tolerated(TOLERATED.read_text(encoding="utf-8"))
        self.assertEqual(errors, [])

    def test_avisos_de_ambiente_passam(self):
        self.assertEqual(logcheck.problems("\n".join(ENVIRONMENT), self.patterns), [])

    def test_erros_reais_nao_passam_nem_misturados(self):
        log = "\n".join(ENVIRONMENT + REAL_ERRORS)
        found = [text for _, text in logcheck.problems(log, self.patterns)]
        self.assertEqual(found, [line.strip() for line in REAL_ERRORS])

    def test_aviso_tolerado_com_typeerror_emendado_reprova(self):
        # A linha inteira não é o aviso de ambiente puro: tem um TypeError
        # emendado no meio. Um padrão largo (busca livre) engoliria; o
        # fullmatch + NEVER_TOLERATE têm de reprovar.
        log = "WARN scene: @X.qml[1:1]: TypeError: foo $HYPRLAND_INSTANCE_SIGNATURE is unset"
        found = [text for _, text in logcheck.problems(log, self.patterns)]
        self.assertEqual(found, [log.strip()])

    def test_mesa_com_referenceerror_emendado_reprova(self):
        log = "MESA: error: something unrelated ReferenceError"
        found = [text for _, text in logcheck.problems(log, self.patterns)]
        self.assertEqual(found, [log.strip()])


if __name__ == "__main__":
    unittest.main()
