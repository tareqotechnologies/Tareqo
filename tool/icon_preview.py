# Contact sheet do ícone (revisão visual): 4 tamanhos sobre fundo
# claro e escuro — como o usuário vê em home screens e docks.
#   python tool/icon_preview.py  →  build/icon_preview.png
# Cores da paleta oficial: #F0F0F0 (superfície), #0C0B0A (preto),
# #F9F9F9 (branco suave).
import os

from PIL import Image, ImageDraw

BASE = 'assets/branding/icon_official.png'
OUT = 'build/icon_preview.png'

LIGHT = (240, 240, 240)  # #F0F0F0
DARK = (12, 11, 10)      # #0C0B0A
SOFT_WHITE = (249, 249, 249)  # #F9F9F9


def main():
    os.makedirs('build', exist_ok=True)
    base = Image.open(BASE).convert('RGBA')
    W, H = 1240, 720
    sheet = Image.new('RGB', (W, H), LIGHT)
    d = ImageDraw.Draw(sheet)

    sizes = [(512, '512px'), (192, '192px'), (48, '48px'), (16, '16px')]
    for i, (size, label) in enumerate(sizes):
        x = 40 + i * 300
        d.text((x, 24), label, fill=DARK)
        # Fundo claro (home screen clara).
        thumb = base.resize((size, size), Image.LANCZOS)
        sheet.paste(thumb, (x, 60), thumb)
        d.rectangle((x, 60, x + size, 60 + size), outline=DARK)
        # Fundo escuro (dock / modo escuro).
        dark = Image.new('RGB', (size, size), DARK)
        dark.paste(thumb, (0, 0), thumb)
        sheet.paste(dark, (x, 110 + size))
        d.rectangle((x, 110 + size, x + size, 110 + 2 * size),
                    outline=SOFT_WHITE)

    sheet.save(OUT)
    print('preview:', OUT, sheet.size)


if __name__ == '__main__':
    main()
