#!/usr/bin/env python3
"""Gera os wallpapers dos temas embutidos em themes/wallpapers/.

Cada wallpaper é um fundo liso com um ou mais brilhos radiais suaves; um
pouco de ruído evita faixas visíveis no degradê. Requer Pillow.
"""
from pathlib import Path
import random

from PIL import Image

W, H = 2560, 1440
OUT = Path(__file__).resolve().parent.parent / "themes" / "wallpapers"


def hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def render(name, base, glows, stars=0, seed=1):
    """glows: (cx, cy, raio, cor, intensidade) com posições em fração da tela."""
    rng = random.Random(seed)
    base = hex_rgb(base)
    glows = [(cx * W, cy * H, r * W, hex_rgb(c), k) for cx, cy, r, c, k in glows]
    # Calcula numa grade reduzida e amplia: o degradê é suave, então não perde nada.
    sw, sh = W // 4, H // 4
    small = Image.new("RGB", (sw, sh))
    px = small.load()
    for y in range(sh):
        for x in range(sw):
            r, g, b = base
            for cx, cy, rad, col, k in glows:
                dx, dy = x * 4 - cx, y * 4 - cy
                t = max(0.0, 1.0 - (dx * dx + dy * dy) ** 0.5 / rad)
                t = t * t * (3 - 2 * t) * k
                r += (col[0] - r) * t
                g += (col[1] - g) * t
                b += (col[2] - b) * t
            px[x, y] = (int(r), int(g), int(b))
    img = small.resize((W, H), Image.BICUBIC)
    big = img.load()
    for y in range(H):
        for x in range(W):
            n = rng.randint(-2, 2)
            r, g, b = big[x, y]
            big[x, y] = (max(0, min(255, r + n)), max(0, min(255, g + n)), max(0, min(255, b + n)))
    for _ in range(stars):
        x, y = rng.randrange(W), rng.randrange(int(H * 0.7))
        v = rng.randint(90, 200)
        big[x, y] = (v, v, min(255, v + 20))
    img.save(OUT / f"{name}.jpg", quality=90, optimize=True)
    print("ok", name)


render("lamparina", "#0c0a08", [
    (0.50, 1.10, 0.55, "#5a3510", 0.55),
    (0.50, 1.05, 0.25, "#c77a22", 0.35),
])
render("luar", "#080b11", [
    (0.80, 0.18, 0.45, "#1c2a44", 0.7),
    (0.80, 0.18, 0.06, "#cfdcf5", 0.35),
], stars=260, seed=7)
render("brasa", "#0b0706", [
    (0.20, 1.05, 0.50, "#5a160a", 0.6),
    (0.75, 1.10, 0.45, "#7a2a0c", 0.45),
    (0.45, 1.08, 0.20, "#e0551f", 0.25),
])
render("pergaminho", "#e9dfcc", [
    (0.50, 0.45, 0.75, "#f7f1e6", 0.8),
    (0.50, 1.20, 0.60, "#d9a766", 0.18),
])
