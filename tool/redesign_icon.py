# Redesign do ícone da marca (nível Apple) — sacola de compras premium.
#
#   python tool/redesign_icon.py
#
# Gera `assets/branding/icon_official.png` (1024x1024) com desenho
# VETORIAL supersample 4x (4096px → LANCZOS): cantos e curvas com
# anti-aliasing suave (nível Apple), gradiente azul-céu → índigo rico,
# gloss translúcido no topo, sombra suave e a letra "D" desenhada com a
# fonte INTER do próprio app (consistência total da identidade).
#
# Depois de gerar, rode o pipeline de recortes e ícones nativos:
#   flutter test tool/generate_icons_test.dart
#   dart run flutter_launcher_icons
#
# O desenho usa PIL puro (sem numpy): gradientes por linha e máscaras
# multiplicadas com ImageChops.
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageChops

S = 4096  # supersample (4x do canvas final 1024)
SS = S // 1024  # escala por unidade de design (4)

OUT = 'assets/branding/icon_official.png'
FONT = 'assets/fonts/Inter-Variable.ttf'


def scale(vals):
    return [v * SS for v in vals]


def lerp_color(c1, c2, t):
    return tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))


def vertical_gradient(size, top, bottom):
    """Imagem RGBA com gradiente linear vertical top→bottom."""
    grad = Image.new('RGB', size)
    d = ImageDraw.Draw(grad)
    h = size[1]
    for y in range(h):
        d.line([(0, y), (size[0], y)], fill=lerp_color(top, bottom, y / h))
    return grad


def main():
    canvas = Image.new('RGBA', (S, S), (255, 255, 255, 255))
    d = ImageDraw.Draw(canvas)

    # ── Geometria da sacola (unidades de design 0–1024) ──────────────
    # Corpo ~47% x 50% do canvas (com as alças, ~47% x 60% — o mesmo
    # tamanho do design oficial v4.2: sacola ~53% x 62%).
    body = scale([270, 320, 754, 830])  # corpo: retângulo arredondado
    body_radius = 96 * SS
    handle_cy = 320 * SS  # topo do corpo (alças "nascem" aqui)
    handle_r = 100 * SS  # raio do arco da alça
    handle_w = 48 * SS  # espessura da alça

    # ── Sombra suave sob a sacola (antes do corpo, para ficar atrás) ──
    shadow = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    ds = ImageDraw.Draw(shadow)
    ds.ellipse(scale([300, 838, 724, 902]), fill=(30, 58, 108, 70))
    shadow = shadow.filter(ImageFilter.GaussianBlur(42 * SS))
    canvas.alpha_composite(shadow)

    # ── Corpo com gradiente azul-céu → índigo ─────────────────────────
    grad = vertical_gradient((S, S), (84, 175, 255), (26, 72, 176))
    body_mask = Image.new('L', (S, S), 0)
    ImageDraw.Draw(body_mask).rounded_rectangle(body, radius=body_radius, fill=255)
    body_img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    body_img.paste(grad, (0, 0), body_mask)
    canvas.alpha_composite(body_img)

    # ── Gloss: faixa translúcida no terço superior (efeito 3D Apple) ──
    gloss = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    gloss_box = [body[0], body[1], body[2], body[1] + 150 * SS]
    ImageDraw.Draw(gloss).rounded_rectangle(
        gloss_box, radius=60 * SS, fill=(255, 255, 255, 60),
    )
    # Recorta o gloss pela máscara do corpo (não vazar nas laterais).
    gloss_a = ImageChops.multiply(gloss.getchannel('A'), body_mask)
    gloss.putalpha(gloss_a)
    canvas.alpha_composite(gloss)

    # ── Alças: ANÉIS semicirculares grossos (corte Apple) ─────────────
    # Método determinístico (sem depender da convenção de ângulos do
    # arc): círculo externo − círculo interno (anel), recortado pela
    # metade SUPERIOR (y < topo do corpo) com multiplicação de máscaras.
    handle_color = (46, 112, 212, 255)
    # cx em UNIDADES DE DESIGN — escala para pixels antes das contas
    # (handle_r/handle_w/handle_cy já estão escalados; cx cru misturava
    # escalas e desenhava a alça minúscula no canto errado).
    for cx_u in (412, 612):
        cx = cx_u * SS
        outer = [cx - handle_r, handle_cy - handle_r,
                 cx + handle_r, handle_cy + handle_r]
        inner = [cx - handle_r + handle_w, handle_cy - handle_r + handle_w,
                 cx + handle_r - handle_w, handle_cy + handle_r - handle_w]
        ring = Image.new('RGBA', (S, S), (0, 0, 0, 0))
        dr = ImageDraw.Draw(ring)
        dr.ellipse(outer, fill=handle_color)  # disco externo
        # Remove o disco interno do alpha (vira anel).
        inner_mask = Image.new('L', (S, S), 0)
        ImageDraw.Draw(inner_mask).ellipse(inner, fill=255)
        ring_a = ImageChops.subtract(ring.getchannel('A'), inner_mask)
        # Mantém apenas a metade SUPERIOR (y < handle_cy).
        upper = Image.new('L', (S, S), 0)
        ImageDraw.Draw(upper).rectangle([0, 0, S, handle_cy], fill=255)
        ring.putalpha(ImageChops.multiply(ring_a, upper))
        canvas.alpha_composite(ring)
        # Ilhó: pequeno círculo escuro na base da alça (onde ela toca o
        # corpo) — detalhe de construção que dá realismo 3D.
        d.ellipse(
            [cx - 12 * SS, handle_cy - 10 * SS, cx + 12 * SS, handle_cy + 14 * SS],
            fill=(30, 70, 150, 255),
        )

    # ── "D" com a fonte Inter do app (peso Bold via eixo wght) ────────
    try:
        font = ImageFont.truetype(FONT, 330 * SS)
        try:
            font.set_variation_by_axes([700])
        except Exception:
            # Sem eixo wght aplicável: o D sai em w400 (mais fino) — ainda
            # legível; preferível a quebrar o desenho.
            print('aviso: peso Bold não aplicável — D em w400')
    except Exception:
        # Fonte indisponível: DESENHA o D como glifo vetorial simples
        # (anel + poste) em vez de bitmap pixelado (load_default).
        print('aviso: Inter indisponível — D desenhado como glifo')
        font = None
    if font is not None:
        bbox = d.textbbox((0, 0), 'D', font=font)
        tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
        tx = (S - tw) / 2 - bbox[0]
        # Centro da letra no centroide do corpo (~575): o "D" é o símbolo
        # da marca dentro da sacola.
        ty = 578 * SS - th / 2 - bbox[1]
        d.text((tx, ty), 'D', font=font, fill=(255, 255, 255, 255))
    else:
        # Glifo "D" vetorial (anel + poste) — sem depender da fonte.
        dcx, dcy = 512 * SS, 578 * SS
        d.ellipse([dcx - 150 * SS, dcy - 165 * SS, dcx + 150 * SS, dcy + 165 * SS],
                  outline=(255, 255, 255, 255), width=64 * SS)
        d.rectangle([dcx - 150 * SS, dcy - 165 * SS, dcx - 118 * SS, dcy + 165 * SS],
                    fill=(255, 255, 255, 255))
    bbox = d.textbbox((0, 0), 'D', font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    tx = (S - tw) / 2 - bbox[0]
    # Centro da letra no centroide do corpo (~575): o "D" é o símbolo
    # da marca dentro da sacola.
    ty = 578 * SS - th / 2 - bbox[1]
    d.text((tx, ty), 'D', font=font, fill=(255, 255, 255, 255))

    # ── Verificação interna (alpha nos pontos-chave, antes do resize) ──
    for label, x, y in [
        ('alca esq', 452, 340),
        ('alca dir', 572, 340),
        ('corpo topo', 512, 400),
        ('D (centro)', 512, 550),
        ('corpo base', 512, 750),
    ]:
        px = canvas.getpixel((x * SS, y * SS))
        print('check %s (%d,%d): rgba %s' % (label, x, y, px))

    # ── Downscale para 1024 (anti-aliasing final) ─────────────────────
    icon = canvas.resize((1024, 1024), Image.LANCZOS)
    icon.save(OUT)
    print('gerado:', OUT, icon.size)


if __name__ == '__main__':
    main()
