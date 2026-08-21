#!/usr/bin/env python3
"""
Gera o ícone oficial D Monograma — monograma geométrico "D" branco
sobre fundo verde da marca (#15803D).

  python tool/gen_icon_d_monogram.py

Design:
- Fundo: #15803D (primary green do app)
- "D": branco puro (#FFFFFF), construído geometricamente
- Silhueta forte, planar, sem gloss/sombra/3D
"""

import math
import os

from PIL import Image, ImageDraw

S = 4096          # supersample 4×
SS = S // 1024
OUT = 'assets/branding/icon_official.png'

GREEN = (0, 118, 246)     # #0076F6 — primary blue (matching login screen)
WHITE = (255, 255, 255)


def sc(v):
    return int(v * SS)


def draw_right_half_ellipse(draw_ctx, cx, cy, rx, ry, fill):
    """Metade direita de uma ellipse preenchida (coordenadas escaladas)."""
    points = []
    for deg in range(-90, 91):
        rad = math.radians(deg)
        x = cx + rx * math.cos(rad)
        y = cy + ry * math.sin(rad)
        points.append((x, y))
    draw_ctx.polygon(points, fill=fill)


def draw_d_mask(draw_ctx):
    """
    Máscara do "D" em duas camadas:
    1. OUTER: haste (rect) + bojo (semiellipse direita) = branco
    2. COUNTER: haste interna (rect) + bojo interno (semiellipse direita) = preto
    """
    # ── Proporções (unidades 0–1024) ────────────────────────────────
    L = 152       # outer left
    T = 112       # outer top
    R = 872       # outer right  (1024-152)
    B = 912       # outer bottom (1024-112)

    cy = (T + B) / 2   # 512

    # Haste (poste): retângulo vertical de L até stem_r
    stem_r = 362
    # Bojo: semielipse direita centrada em (stem_r, cy)
    # O bojo estende-se da haste até R
    bowl_rx = R - stem_r   # 510
    bowl_ry = (B - T) / 2  # 400

    # ── Counter ─────────────────────────────────────────────────────
    c_inset = 110          # inset uniforme → D robusto
    c_left   = L + c_inset  # 262
    c_top    = T + c_inset  # 222
    c_bottom = B - c_inset  # 802
    c_cy     = (c_top + c_bottom) / 2  # 512
    c_bowl_rx = bowl_rx - c_inset       # 400
    c_bowl_ry = (c_bottom - c_top) / 2  # 290

    # ─────────────────────────────────────────────────────────────────
    # PASSO 1: OUTER D — haste (rect) + bojo (semiellipse direita)
    # ─────────────────────────────────────────────────────────────────
    # Haste: rectângulo vertical
    draw_ctx.rectangle(
        [sc(L), sc(T), sc(stem_r), sc(B)],
        fill=255,
    )
    # Bojo: APENAS a metade direita da ellipse
    draw_right_half_ellipse(
        draw_ctx,
        sc(stem_r), sc(cy),
        sc(bowl_rx), sc(bowl_ry),
        fill=255,
    )

    # ─────────────────────────────────────────────────────────────────
    # PASSO 2: COUNTER — recorta o interior
    # ─────────────────────────────────────────────────────────────────
    # Rectânculo interno (parte do counter dentro da haste)
    draw_ctx.rectangle(
        [sc(c_left), sc(c_top), sc(stem_r), sc(c_bottom)],
        fill=0,
    )
    # Semiesquerda interna (parte do counter dentro do bojo)
    draw_right_half_ellipse(
        draw_ctx,
        sc(stem_r), sc(c_cy),
        sc(c_bowl_rx), sc(c_bowl_ry),
        fill=0,
    )


def main():
    os.makedirs(os.path.dirname(OUT) or '.', exist_ok=True)

    mask = Image.new('L', (S, S), 0)
    draw = ImageDraw.Draw(mask)
    draw_d_mask(draw)

    canvas = Image.new('RGBA', (S, S), GREEN + (255,))
    white_layer = Image.new('RGBA', (S, S), WHITE + (0,))
    white_layer.putalpha(mask)
    canvas = Image.alpha_composite(canvas, white_layer)

    icon = canvas.resize((1024, 1024), Image.LANCZOS)
    icon.save(OUT)
    print(f'gerado: {OUT} ({icon.size[0]}×{icon.size[1]})')

    # ── Verificação ─────────────────────────────────────────────────
    px = icon.load()
    checks = [
        ('haste esquerda',   200, 512),
        ('haste topo',       250, 180),
        ('haste fundo',      250, 840),
        ('bojo direita',     800, 512),
        ('bojo topo',        500, 180),
        ('bojo fundo',       500, 840),
        ('counter centro',   500, 512),
        ('counter topo',     400, 300),
        ('counter fundo',    400, 720),
        ('fundo topo-esq',   50,  50),
        ('fundo dir',        970, 512),
        ('fundo topo-dir',   970, 50),
        ('stema ext esq',    10,  512),
    ]
    for label, x, y in checks:
        rgba = px[x, y]
        is_green = rgba[1] > rgba[0] + 20 and rgba[1] > 100
        is_white = all(c > 240 for c in rgba[:3])
        tag = 'GREEN' if is_green else ('WHITE' if is_white else '??')
        print(f'  {label:20s} ({x:4d},{y:4d}): rgba{rgba} [{tag}]')

    # ── Preview ─────────────────────────────────────────────────────
    os.makedirs('build', exist_ok=True)
    preview = Image.new('RGB', (800, 200), (243, 244, 247))
    dp = ImageDraw.Draw(preview)
    sizes = [192, 96, 48, 24, 16]
    x_off = 20
    for sz in sizes:
        thumb = icon.resize((sz, sz), Image.LANCZOS)
        dp.rectangle([x_off - 2, 98 - sz // 2 - 2, x_off + sz + 2, 98 + sz // 2 + 2],
                     outline=(180, 180, 190))
        preview.paste(thumb, (x_off, 98 - sz // 2), thumb)
        dp.text((x_off, 98 + sz // 2 + 6), f'{sz}', fill=(90, 92, 100))
        x_off += max(sz + 30, 80)
    preview.save('build/icon_preview_d.png')
    print(f'preview: build/icon_preview_d.png')


if __name__ == '__main__':
    main()
