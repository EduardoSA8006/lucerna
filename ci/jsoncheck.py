#!/usr/bin/env python3
"""Confere os JSON de tema: cada themes/*.json tem as chaves obrigatórias
(nome, cores completas, fontes, papel de parede, hyprland) e só aponta para
arquivos que existem; themes/shaders/effects.json só aponta para .qsb que
existem. Uso: ci/jsoncheck.py [PASTA_DOS_TEMAS]"""

import json
import re
import sys
from pathlib import Path

COLORS = [
    "base", "surface", "raised", "border", "text", "textMuted", "textFaint",
    "accent", "accentText", "danger", "success", "warning",
]  # fmt: skip
FONT = ["sans", "mono", "icon"]
FONT_SIZES = ["small", "normal", "large", "huge"]
HYPRLAND = ["activeBorder", "inactiveBorder", "borderSize", "rounding", "blurSize", "blurPasses"]
HEX = re.compile(r"^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$")


def check_theme(data, themes):
    """Problemas de um tema, em texto; `themes` é a pasta themes/ (base dos caminhos)."""
    if not isinstance(data, dict):
        return ["não é um objeto JSON"]
    errors, paths = [], []
    if not isinstance(data.get("name"), str) or not data["name"].strip():
        errors.append('falta "name"')
    colors = data.get("colors")
    if not isinstance(colors, dict):
        errors.append('falta "colors"')
    else:
        missing = [c for c in COLORS if c not in colors]
        if missing:
            errors.append(f"faltam as cores {', '.join(missing)}")
        bad = [c for c, v in colors.items() if not isinstance(v, str) or not HEX.match(v)]
        if bad:
            errors.append(f"cores fora do formato #rrggbb: {', '.join(bad)}")
    font = data.get("font")
    if not isinstance(font, dict):
        errors.append('falta "font"')
    else:
        missing = [k for k in FONT if not isinstance(font.get(k), str)]
        sizes = font.get("size")
        if isinstance(sizes, dict):
            missing += [f"size.{k}" for k in FONT_SIZES if not isinstance(sizes.get(k), int)]
        else:
            missing.append("size")
        if missing:
            errors.append(f"faltam em font: {', '.join(missing)}")
    wallpaper = data.get("wallpaper")
    if isinstance(wallpaper, str):
        paths.append(wallpaper)
    elif isinstance(wallpaper, dict) and isinstance(wallpaper.get("static"), str):
        paths.append(wallpaper["static"])
        if wallpaper.get("shader"):
            paths.append(wallpaper["shader"])
    else:
        errors.append('falta "wallpaper" (um caminho ou { "static", "shader" })')
    hyprland = data.get("hyprland")
    if not isinstance(hyprland, dict):
        errors.append('falta "hyprland"')
    else:
        missing = [k for k in HYPRLAND if k not in hyprland]
        if missing:
            errors.append(f"faltam em hyprland: {', '.join(missing)}")
    fonts = data.get("fonts", [])
    if isinstance(fonts, list):
        paths += [f for f in fonts if isinstance(f, str)]
    else:
        errors.append('"fonts" não é uma lista')
    for rel in paths:
        if not rel.startswith(("/", "~")) and not (themes / rel).exists():
            errors.append(f"aponta para um arquivo que não existe: {rel}")
    return errors


def check_effects(data, themes):
    """Problemas do catálogo de efeitos (themes/shaders/effects.json)."""
    if not isinstance(data, list):
        return ["não é uma lista"]
    errors, seen = [], set()
    for i, effect in enumerate(data):
        if not isinstance(effect, dict) or not all(isinstance(effect.get(k), str) for k in ("id", "name", "shader")):
            errors.append(f"efeito {i}: precisa de id, name e shader")
            continue
        eid, shader = effect["id"], effect["shader"]
        if eid in seen:
            errors.append(f'efeito "{eid}" repetido')
            continue
        seen.add(eid)
        if not shader.endswith(".qsb"):
            errors.append(f'efeito "{eid}": o shader precisa ser um .qsb ({shader})')
        elif not (themes / shader).exists():
            errors.append(f'efeito "{eid}": {shader} não existe')
    return errors


def load(path):
    if not path.exists():
        return None, "não existe"
    try:
        return json.loads(path.read_text(encoding="utf-8")), None
    except json.JSONDecodeError as e:
        return None, f"JSON inválido: {e}"


def main(argv):
    themes = Path(argv[0]) if argv else Path(__file__).resolve().parent.parent / "themes"
    problems = []
    for path in sorted(themes.glob("*.json")):
        data, error = load(path)
        problems += [(path, p) for p in ([error] if error else check_theme(data, themes))]
    effects = themes / "shaders" / "effects.json"
    data, error = load(effects)
    problems += [(effects, p) for p in ([error] if error else check_effects(data, themes))]
    for path, problem in problems:
        print(f"{path.relative_to(themes.parent).as_posix()}: {problem}")
    print(f"json: {len(problems)} problema(s)" if problems else "json: ok")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
