# Contact sheet do ícone (revisão visual): 4 tamanhos sobre fundo
# branco e escuro — como o usuário vê em home screens e docks.
#   python tool/icon_preview.py  →  build/icon_preview.png
import os

from PIL import Image, ImageDraw

BASE = 'assets/branding/icon_official.png'
OUT = 'build/icon_preview.png'


def main():
    os.makedirs('build', exist_ok=True)
    base = Image.open(BASE).convert('RGBA')
    W, H = 1240, 720
    sheet = Image.new('RGB', (W, H), (243, 244, 247))
    d = ImageDraw.Draw(sheet)

    sizes = [(512, '512px'), (192, '192px'), (48, '48px'), (16, '16px')]
    for i, (size, label) in enumerate(sizes):
        x = 40 + i * 300
        d.text((x, 24), label, fill=(90, 92, 100))
        # Fundo claro (home screen clara).
        thumb = base.resize((size, size), Image.LANCZOS)
        sheet.paste(thumb, (x, 60), thumb)
        d.rectangle((x, 60, x + size, 60 + size), outline=(208, 210, 218))
        # Fundo escuro (dock / modo escuro).
        dark = Image.new('RGB', (size, size), (22, 24, 30))
        dark.paste(thumb, (0, 0), thumb)
        sheet.paste(dark, (x, 110 + size))
        d.rectangle((x, 110 + size, x + size, 110 + 2 * size),
                    outline=(58, 60, 70))

    sheet.save(OUT)
    print('preview:', OUT, sheet.size)


if __name__ == '__main__':
    main()
