# Contact sheet do ícone (revisão visual): 4 tamanhos sobre fundo
# claro e escuro — como o usuário vê em home screens e docks.
#   python tool/icon_preview.py  →  build/icon_preview.png
# Cores da paleta oficial: #E7E5E5 (superfície), #232323 (tinta),
# #F9F9F9 (branco suave).
import os

from PIL import Image, ImageDraw

BASE = 'assets/branding/icon_official.png'
OUT = 'build/icon_preview.png'

LIGHT = (231, 229, 229)  # #E7E5E5
DARK = (35, 35, 35)      # #232323
SOFT_WHITE = (249, 249, 249)  # #F9F9F9


def main():
    os.makedirs('build', exist_ok=True)
    base = Image.open(BASE).convert('RGBA')
    sizes = [(512, '512px'), (192, '192px'), (48, '48px'), (16, '16px')]
    gap = 60
    W = sum(s for s, _ in sizes) + gap * (len(sizes) + 1)
    dark_y = 60 + 512 + 50
    H = dark_y + 512 + 40
    sheet = Image.new('RGB', (W, H), LIGHT)
    d = ImageDraw.Draw(sheet)

    x = gap
    for size, label in sizes:
        d.text((x, 24), label, fill=DARK)
        # Fundo claro (home screen clara).
        thumb = base.resize((size, size), Image.LANCZOS)
        sheet.paste(thumb, (x, 60), thumb)
        d.rectangle((x, 60, x + size, 60 + size), outline=DARK)
        # Fundo escuro (dock / modo escuro).
        dark = Image.new('RGB', (size, size), DARK)
        dark.paste(thumb, (0, 0), thumb)
        sheet.paste(dark, (x, dark_y))
        d.rectangle((x, dark_y, x + size, dark_y + size), outline=SOFT_WHITE)
        x += size + gap

    sheet.save(OUT)
    print('preview:', OUT, sheet.size)


if __name__ == '__main__':
    main()
