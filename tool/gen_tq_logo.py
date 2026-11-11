#!/usr/bin/env python3
"""Gera os masters da marca TQ com a paleta OFICIAL do anexo (Outfit):
tinta #232323 + branco suave #F9F9F9.

- icon_official / icon_legacy / play_store_icon: tile tinta + monograma suave;
- icon_fg / splash_logo / play_store_adaptive_fg: monograma suave sobre
  transparente (adaptive foreground, splash escuro);
- icon_fg_ink: monograma tinta sobre transparente (splash nativo claro);
- icon_mono: silhueta branca (themed icons Android 13+);
- play_store_feature: tile tinta 1024.

Os recortes nativos (Android launch_image claro/escuro, iOS LaunchImage
claro/escuro) e os PNGs web saem de `flutter test tool/generate_icons_test.dart`;
os ícones nativos finais de `dart run flutter_launcher_icons`.
"""

import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BRANDING_DIR = os.path.join(ROOT, 'assets', 'branding')

SIZE = 1024

# Paleta oficial do anexo — únicas cores da marca.
INK = (35, 35, 35)        # #232323
SOFT = (249, 249, 249)    # #F9F9F9
TRANSPARENT = (0, 0, 0, 0)


def draw_tq_clean(draw, size, fill, bg):
    """Monograma TQ: T de barra larga + Q de anel espesso com haste abaixo.
    [bg] é a cor do recorte interno do anel (fundo do tile ou transparente).
    """
    scale = size / 1024.0
    pad = int(180 * scale)
    area_w = size - 2 * pad
    area_h = size - 2 * pad

    t_bar_w = int(area_w * 0.38)
    t_bar_h = int(area_h * 0.075)
    t_stem_w = int(area_w * 0.10)
    t_stem_h = int(area_h * 0.28)

    q_outer = int(area_h * 0.37)
    q_inner = int(area_h * 0.22)
    q_bar_w = int(area_w * 0.10)
    q_bar_ext = int(area_h * 0.28)
    gap = int(area_w * 0.06)

    top_y = pad + int(area_h * 0.12)

    # T — barra horizontal + haste centrada.
    t_x = pad + int(area_w * 0.05)
    draw.rectangle([t_x, top_y, t_x + t_bar_w, top_y + t_bar_h], fill=fill)
    stem_x = t_x + (t_bar_w - t_stem_w) // 2
    stem_top = top_y + t_bar_h + int(4 * scale)
    draw.rectangle(
        [stem_x, stem_top, stem_x + t_stem_w, stem_top + t_stem_h], fill=fill
    )

    # Q — anel + haste acima/abaixo do furo interno.
    q_cx = t_x + t_bar_w + gap + q_outer
    q_cy = top_y + t_bar_h + int(4 * scale) + t_stem_h * 0.45
    draw.ellipse(
        [q_cx - q_outer, q_cy - q_outer, q_cx + q_outer, q_cy + q_outer],
        fill=fill,
    )
    draw.ellipse(
        [q_cx - q_inner, q_cy - q_inner, q_cx + q_inner, q_cy + q_inner],
        fill=bg,
    )
    bar_x = q_cx - q_bar_w // 2
    draw.rectangle(
        [bar_x, q_cy + q_inner, bar_x + q_bar_w, q_cy + q_outer + q_bar_ext],
        fill=fill,
    )
    draw.rectangle(
        [bar_x, q_cy - q_outer, bar_x + q_bar_w, q_cy - q_inner], fill=fill
    )


def tile(size):
    """Tile opaco: fundo tinta + monograma suave."""
    img = Image.new('RGB', (size, size), INK)
    draw_tq_clean(ImageDraw.Draw(img), size, SOFT, INK)
    return img


def transparent_logo(size, fill, height_fraction):
    """Monograma [fill] sobre transparente, centrado, com a altura do
    desenho em [height_fraction] do canvas."""
    scratch = Image.new('RGBA', (SIZE, SIZE), TRANSPARENT)
    draw_tq_clean(ImageDraw.Draw(scratch), SIZE, fill, TRANSPARENT)
    bbox = scratch.getbbox()
    drawing = scratch.crop(bbox)
    target_h = int(size * height_fraction)
    target_w = int(drawing.width * target_h / drawing.height)
    drawing = drawing.resize((target_w, target_h), Image.LANCZOS)
    out = Image.new('RGBA', (size, size), TRANSPARENT)
    out.paste(drawing, ((size - target_w) // 2, (size - target_h) // 2), drawing)
    return out


def save(img, name):
    img.save(os.path.join(BRANDING_DIR, name), 'PNG')
    print(f'ok {name} ({img.size[0]}x{img.size[1]})')


def generate_all():
    os.makedirs(BRANDING_DIR, exist_ok=True)

    save(tile(SIZE), 'icon_official.png')
    save(tile(SIZE), 'icon_legacy.png')
    save(tile(512), 'play_store_icon.png')
    save(tile(SIZE), 'play_store_feature.png')

    save(transparent_logo(SIZE, SOFT, 0.84), 'icon_fg.png')
    save(transparent_logo(SIZE, INK, 0.84), 'icon_fg_ink.png')
    save(transparent_logo(SIZE, (255, 255, 255, 255), 0.84), 'icon_mono.png')
    save(transparent_logo(SIZE, SOFT, 0.80), 'splash_logo.png')
    save(transparent_logo(512, SOFT, 0.84), 'play_store_adaptive_fg.png')

    print('masters da marca gerados (paleta #232323 / #F9F9F9)')


if __name__ == '__main__':
    generate_all()
