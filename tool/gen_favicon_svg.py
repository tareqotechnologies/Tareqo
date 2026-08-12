# Gera `web/icons/favicon.svg` — réplica VETORIAL EXATA do ícone oficial.
#
#   python tool/gen_favicon_svg.py
#
# Usa a MESMA geometria de `tool/redesign_icon.py` (unidades 0–1024) e o
# glifo "D" REAL extraído da fonte Inter-Variable (eixo wght 700) via
# fontTools — o favicon fica nítido em QUALQUER tamanho (16px na aba do
# navegador até 512px+), idêntico ao ícone oficial.
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.boundsPen import BoundsPen

from PIL import Image

FONT = 'assets/fonts/Inter-Variable.ttf'
ICON = 'assets/branding/icon_official.png'
OUT = 'web/icons/favicon.svg'

# ── Geometria (idêntica ao redesign_icon.py) ─────────────────────────
BODY = (270, 320, 754, 830)   # corpo (rounded rect)
BODY_R = 96
GRAD_TOP = '#54AFFF'          # 84,175,255
GRAD_BOTTOM = '#1A48B0'       # 26,72,176
GLOSS_H = 150
GLOSS_R = 60
GLOSS_ALPHA = '0.24'          # 60/255
HANDLE_CY = 320
HANDLE_R = 76  # raio do CAMINHO do arco (o stroke de 48 fica centrado:
               # borda externa em 100 e interna em 52 — igual ao anel do PNG)
HANDLE_W = 48
HANDLE_COLOR = '#2E70D4'      # 46,112,212
ILHOS = [(412, 322), (612, 322)]  # (cx, cy) do ilhó (centro real: cy+2)
ILHOS_R = 12
ILHOS_COLOR = '#1E4696'       # 30,70,150
D_CY = 578                    # centro vertical do "D" (mesmo do PNG)
SHADOW = (300, 838, 724, 902)  # elipse da sombra (mesmo do PNG)


def measure_d_in_png(path):
    """Bbox do 'D' branco DENTRO da sacola no PNG oficial.

    O fundo do ícone também é branco — a varredura é restrita ao corpo da
    sacola (onde o "D" vive), evitando contaminar a medida com o canvas.
    """
    im = Image.open(path).convert('RGBA')
    w, h = im.size
    px = im.load()
    xs, ys = [], []
    # Região CENTRAL (o "D" vive no centro; evita o fundo branco que
    # vaza nos cantos arredondados do corpo da sacola).
    for y in range(430, min(h, 750)):
        for x in range(380, min(w, 650)):
            r, g, b, a = px[x, y]
            if a > 200 and r > 230 and g > 230 and b > 230:
                xs.append(x)
                ys.append(y)
    if not xs:
        raise SystemExit('D não encontrado no PNG (região central da sacola)')
    return min(xs), min(ys), max(xs), max(ys)


def main():
    # ── 1. Extrai o glifo 'D' da Inter como path SVG ──────────────────
    # O PNG oficial renderiza o 'D' na INSTÂNCIA DEFAULT da variável:
    # o FreeType do PIL (ImageFont.truetype + set_variation_by_axes)
    # ignora o eixo wght para esta fonte (poste idêntico em w400–w700).
    # Para o favicon ser EXATAMENTE igual ao ícone aprovado, usa-se o
    # glifo default (sem instantiateVariableFont).
    font = TTFont(FONT)
    gs = font.getGlyphSet()
    glyph = gs['D']
    pen = SVGPathPen(gs)
    glyph.draw(pen)
    d_path = pen.getCommands()

    # bbox do glifo em unidades de fonte + centro (BoundsPen)
    bp = BoundsPen(gs)
    glyph.draw(bp)
    gx0, gy0, gx1, gy1 = bp.bounds
    gw, gh = gx1 - gx0, gy1 - gy0
    gcx, gcy = (gx0 + gx1) / 2, (gy0 + gy1) / 2

    # ── 2. Escala alvo: casar com o 'D' medido no PNG oficial ─────────
    dx0, dy0, dx1, dy1 = measure_d_in_png(ICON)
    dw, dh = dx1 - dx0, dy1 - dy0
    dcx, dcy = (dx0 + dx1) / 2, (dy0 + dy1) / 2
    # Escala NÃO-uniforme: casa o ink bbox do glifo com o do PNG (o PNG é
    # rasterizado via FreeType+hinting, o bbox do contorno difere ~3%).
    sx = dw / gw
    sy = dh / gh
    print('D no PNG: bbox=(%d,%d,%d,%d) centro=(%.0f,%.0f)' % (dx0, dy0, dx1, dy1, dcx, dcy))
    print('glifo Inter w700: bbox=(%d,%d,%d,%d) centro=(%.0f,%.0f) sx=%.4f sy=%.4f' % (gx0, gy0, gx1, gy1, gcx, gcy, sx, sy))

    # ── 3. Monta o SVG ────────────────────────────────────────────────
    body_w = BODY[2] - BODY[0]
    body_h = BODY[3] - BODY[1]
    cx1, cx2 = 412, 612
    handles = ''.join(
        '<path d="M %d %d A %d %d 0 0 1 %d %d"/>' % (cx - HANDLE_R, HANDLE_CY,
                                                     HANDLE_R, HANDLE_R,
                                                     cx + HANDLE_R, HANDLE_CY)
        for cx in (cx1, cx2)
    )
    ilhos = ''.join(
        '<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="%s"/>' % (cx, cy, ILHOS_R, ILHOS_R, ILHOS_COLOR)
        for cx, cy in ILHOS
    )
    # O glifo vem em unidades de FONTE (Y para CIMA); o SVG tem Y para
    # BAIXO → scale Y negativo vira o 'D' para o lado certo. Reposiciona o
    # centro em (512, 578), como no PNG oficial.
    d_transform = (
        'translate(%d %d) scale(%.6f -%.6f) translate(%.6f %.6f)'
        % (round(dcx), D_CY, sx, sy, -gcx, -gcy)
    )

    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <!-- userSpaceOnUse: a rampa cobre o CANVAS INTEIRO (0–1024), tal como
         no PNG oficial (o gradiente de redesign_icon.py é desenhado por
         linha em todo o canvas e só depois recortado pela sacola). -->
    <linearGradient id="bag" x1="0" y1="0" x2="0" y2="1024" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="{GRAD_TOP}"/>
      <stop offset="1" stop-color="{GRAD_BOTTOM}"/>
    </linearGradient>
    <clipPath id="bodyClip"><rect x="{BODY[0]}" y="{BODY[1]}" width="{body_w}" height="{body_h}" rx="{BODY_R}"/></clipPath>
    <clipPath id="upperHalf"><rect x="0" y="0" width="1024" height="{HANDLE_CY}"/></clipPath>
    <filter id="soft" x="-40%" y="-40%" width="180%" height="180%">
      <feGaussianBlur stdDeviation="26"/>
    </filter>
  </defs>
  <rect x="0" y="0" width="1024" height="1024" fill="#FFFFFF"/>
  <ellipse cx="512" cy="870" rx="212" ry="32" fill="#1E3A6C" opacity="0.10" filter="url(#soft)"/>
  <g clip-path="url(#upperHalf)" fill="none" stroke="{HANDLE_COLOR}" stroke-width="{HANDLE_W}">
    {handles}
  </g>
  {ilhos}
  <rect x="{BODY[0]}" y="{BODY[1]}" width="{body_w}" height="{body_h}" rx="{BODY_R}" fill="url(#bag)"/>
  <rect x="{BODY[0]}" y="{BODY[1]}" width="{body_w}" height="{GLOSS_H}" rx="{GLOSS_R}" fill="#FFFFFF" opacity="{GLOSS_ALPHA}" clip-path="url(#bodyClip)"/>
  <path d="{d_path}" fill="#FFFFFF" transform="{d_transform}"/>
</svg>
'''
    with open(OUT, 'w', encoding='utf-8') as fh:
        fh.write(svg)
    print('gerado:', OUT, '(%d bytes)' % len(svg))


if __name__ == '__main__':
    main()
