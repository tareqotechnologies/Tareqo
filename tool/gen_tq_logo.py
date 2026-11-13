#!/usr/bin/env python3
"""Masters Tareqo: monograma T dentro de Q, geometria vetorial própria.

Paleta atual: Preto 100 #0A0E15, Branco 100 #FFFFFF e Branco 90 #F0F1F5.
Sem sombras ou degradês. PNGs com supersampling, SVGs com contornos.

python tool/gen_tq_logo.py
flutter test tool/generate_icons_test.dart
dart run flutter_launcher_icons
"""

import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BRANDING_DIR = os.path.join(ROOT, 'assets', 'branding')

SIZE = 1024

# Paleta monocromática atual — mesmas cores de AppColors.
INK = (10, 14, 21)       # #0A0E15
SOFT = (255, 255, 255)   # #FFFFFF
PAPER = (240, 241, 245)  # #F0F1F5
TRANSPARENT = (0, 0, 0, 0)
AA = 4
FONT_PATH = Path(ROOT) / 'assets' / 'fonts' / 'Inter-Regular.ttf'

Q_PATH = (
    'M396 180H628C736 180 824 268 824 376V608'
    'C824 716 736 804 628 804H396C288 804 200 716 200 608V376'
    'C200 268 288 180 396 180Z '
    'M396 268H628C688 268 736 316 736 376V608'
    'C736 668 688 716 628 716H396C336 716 288 668 288 608V376'
    'C288 316 336 268 396 268Z'
)
MARK_ELEMENTS = (
    f'<path d="{Q_PATH}" fill-rule="evenodd"/>'
    '<rect x="342" y="330" width="340" height="84" rx="12"/>'
    '<rect x="468" y="386" width="88" height="264" rx="10"/>'
    '<path d="M634 638L694 578L856 740L796 800Z"/>'
)


def draw_tq_clean(draw, size, fill, bg):
    """T interior e Q de espessura óptica comum; terminal diagonal a 45°."""
    scale = size / 1024.0

    def box(values):
        return tuple(round(value * scale) for value in values)

    draw.rounded_rectangle(box((200, 180, 824, 804)), radius=196 * scale, fill=fill)
    draw.rounded_rectangle(box((288, 268, 736, 716)), radius=108 * scale, fill=bg)
    draw.rounded_rectangle(box((342, 330, 682, 414)), radius=12 * scale, fill=fill)
    draw.rounded_rectangle(box((468, 386, 556, 650)), radius=10 * scale, fill=fill)
    draw.polygon([box(point) for point in ((634, 638), (694, 578), (856, 740), (796, 800))], fill=fill)


def tile(size):
    """Ícone opaco; a plataforma aplica a sua própria máscara de cantos."""
    img = Image.new('RGBA', (size, size), (*INK, 255))
    img.alpha_composite(transparent_logo(size, SOFT, 0.64))
    return img.convert('RGB')


def transparent_logo(size, fill, max_extent):
    """Marca AA centrada com respiro igual, escala pela maior dimensão."""
    scratch = Image.new('RGBA', (SIZE * AA, SIZE * AA), TRANSPARENT)
    draw_tq_clean(ImageDraw.Draw(scratch), SIZE * AA, fill, TRANSPARENT)
    drawing = scratch.crop(scratch.getbbox())
    scale = size * max_extent / max(drawing.size)
    target_w = round(drawing.width * scale)
    target_h = round(drawing.height * scale)
    drawing = drawing.resize((target_w, target_h), Image.Resampling.LANCZOS)
    out = Image.new('RGBA', (size, size), TRANSPARENT)
    out.alpha_composite(drawing, ((size - target_w) // 2, (size - target_h) // 2))
    return out


def save(img, name):
    img.save(os.path.join(BRANDING_DIR, name), 'PNG')
    print(f'ok {name} ({img.size[0]}x{img.size[1]})')


def svg_mark(fill='#0A0E15', tile_background=None):
    background = (
        f'<rect width="1024" height="1024" rx="224" fill="{tile_background}"/>'
        if tile_background else ''
    )
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" '
        'role="img" aria-labelledby="title">'
        '<title id="title">Tareqo — monograma TQ</title>'
        f'{background}<g fill="{fill}" transform="translate(-16 20)">'
        f'{MARK_ELEMENTS}</g></svg>\n'
    )


def wordmark_svg():
    """Inter convertida em contornos: o master não depende de fontes instaladas."""
    with TTFont(FONT_PATH) as font:
        glyphs = font.getGlyphSet()
        cmap = font.getBestCmap()
        scale = 96 / font['head'].unitsPerEm
        x = 0
        paths = []
        for char in 'TAREQO':
            glyph_name = cmap[ord(char)]
            pen = SVGPathPen(glyphs)
            glyphs[glyph_name].draw(TransformPen(pen, (scale, 0, 0, -scale, x, 106)))
            paths.append(f'<path d="{pen.getCommands()}"/>')
            x += font['hmtx'][glyph_name][0] * scale + 14
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" '
        f'viewBox="0 0 {x - 14:.2f} 144" role="img" aria-labelledby="title">'
        '<title id="title">TAREQO</title><g fill="#0A0E15">'
        + ''.join(paths) + '</g></svg>\n'
    )


def tracked_text(draw, text, center_x, top, size, fill, tracking=0):
    font = ImageFont.truetype(str(FONT_PATH), size)
    width = sum(draw.textlength(char, font=font) for char in text)
    width += tracking * (len(text) - 1)
    x = center_x - width / 2
    for char in text:
        draw.text((x, top), char, font=font, fill=fill, anchor='lt')
        x += draw.textlength(char, font=font) + tracking


def feature_graphic():
    image = Image.new('RGBA', (1024, 500), (*INK, 255))
    image.alpha_composite(transparent_logo(240, SOFT, 0.80), (100, 130))
    tracked_text(ImageDraw.Draw(image), 'TAREQO', 650, 218, 64, SOFT, 9)
    return image.convert('RGB')


def identity_preview():
    image = Image.new('RGBA', (1600, 1080), (*PAPER, 255))
    draw = ImageDraw.Draw(image)
    draw.rectangle((800, 0, 1600, 1080), fill=(*INK, 255))
    for center, fill, label in ((400, INK, 'POSITIVO'), (1200, SOFT, 'NEGATIVO')):
        tracked_text(draw, label, center, 64, 18, fill, 4)
        image.alpha_composite(transparent_logo(420, fill, 0.80), (center - 210, 220))
        tracked_text(draw, 'TAREQO', center, 680, 68, fill, 12)
        tracked_text(draw, 'MONOGRAMA · INTER · ESCALA NEUTRA', center, 790, 16, fill, 2)
        x = center - 150
        for size in (104, 64, 32):
            icon = tile(size).convert('RGBA')
            mask = Image.new('L', (size, size), 0)
            ImageDraw.Draw(mask).rounded_rectangle(
                (0, 0, size - 1, size - 1), radius=round(size * 0.23), fill=255
            )
            icon.putalpha(mask)
            image.alpha_composite(icon, (x, 898 + (104 - size) // 2))
            x += size + 36
    return image.convert('RGB')


def generate_all():
    os.makedirs(BRANDING_DIR, exist_ok=True)
    save(tile(SIZE), 'icon_official.png')
    save(tile(SIZE), 'icon_legacy.png')
    save(tile(512), 'play_store_icon.png')
    save(feature_graphic(), 'play_store_feature.png')
    save(transparent_logo(SIZE, SOFT, 0.72), 'icon_fg.png')
    save(transparent_logo(SIZE, INK, 0.72), 'icon_fg_ink.png')
    save(transparent_logo(SIZE, SOFT, 0.72), 'icon_mono.png')
    save(transparent_logo(SIZE, SOFT, 0.80), 'splash_logo.png')
    save(transparent_logo(SIZE, INK, 0.80), 'splash_logo_ink.png')
    save(transparent_logo(512, SOFT, 0.72), 'play_store_adaptive_fg.png')
    save(identity_preview(), 'identity_preview.png')
    (Path(BRANDING_DIR) / 'logo_tq.svg').write_text(svg_mark(), encoding='utf-8')
    (Path(BRANDING_DIR) / 'tareqo_wordmark.svg').write_text(wordmark_svg(), encoding='utf-8')
    (Path(ROOT) / 'web' / 'icons' / 'favicon.svg').write_text(
        svg_mark('#FFFFFF', '#0A0E15'), encoding='utf-8'
    )
    print('masters TQ gerados — #0A0E15 / #FFFFFF / #F0F1F5')


if __name__ == '__main__':
    generate_all()
