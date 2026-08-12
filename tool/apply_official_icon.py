#!/usr/bin/env python3
# Aplica o ÍCONE OFICIAL (anexo do utilizador, 12/ago/2026) como mestre da
# marca e regenera o favicon SVG vetorial com a MESMA geometria.
#
#   python tool/apply_official_icon.py
#
# 1) Lê o PNG anexado (457x524): fundo branco + design azul (arco no topo,
#    quadrado arredondado com gradiente, "D" branco recortado e ponto azul
#    ao centro). Remove o fundo por INUNDAÇÃO a partir das bordas (o "D"
#    branco, ENCERRADO pelo azul, sobrevive), escala UNIFORMEMENTE para
#    caber em 1024x1024 com fundo branco puro e grava
#    assets/branding/icon_official.png — o mestre que alimenta
#    tool/generate_icons_test.dart e o flutter_launcher_icons.
# 2) Traça os contornos (Moore) do desenho, do "D" e do ponto e gera
#    web/icons/favicon.svg — vetor nítido em qualquer tamanho, com o mesmo
#    gradiente e as mesmas proporções do anexo.
#
# Depois (pipeline nativo):
#   flutter test tool/generate_icons_test.dart
#   dart run flutter_launcher_icons
import glob
import os

from PIL import Image

SIZE = 1024
SRC = (
    'C:/Users/emili/AppData/Local/Temp/codebuff-clipboard-images/'
    'clipboard-2026-08-12T22-36-14-812Z.png'
)
MASTER = 'assets/branding/icon_official.png'
FAVICON_SVG = 'web/icons/favicon.svg'


def find_src():
    if os.path.exists(SRC):
        return SRC
    candidates = sorted(
        glob.glob(os.path.dirname(SRC) + '/clipboard-*.png'), reverse=True
    )
    if candidates:
        print('anexo original ausente — usando o mais recente:', candidates[0])
        return candidates[0]
    raise SystemExit('anexo não encontrado: %s' % SRC)


def flood_bg(im):
    """Marca True nos pixels do FUNDO: claros (>=200) e de baixa saturação
    (<=30), CONECTADOS às bordas do canvas por inundação 4-vizinhos — a
    mesma lógica do key do generate_icons_test. O "D" branco encerrado
    pelo azul NÃO é alcançado e sobrevive."""
    w, h = im.size
    px = im.load()
    bg = [[False] * w for _ in range(h)]
    stack = []

    def is_bg(x, y):
        r, g, b, a = px[x, y]
        mx = max(r, g, b)
        mn = min(r, g, b)
        return a >= 128 and mx >= 200 and (mx - mn) <= 30

    def push(x, y):
        if 0 <= x < w and 0 <= y < h and not bg[y][x] and is_bg(x, y):
            bg[y][x] = True
            stack.append((x, y))

    for x in range(w):
        push(x, 0)
        push(x, h - 1)
    for y in range(h):
        push(0, y)
        push(w - 1, y)
    while stack:
        x, y = stack.pop()
        push(x + 1, y)
        push(x - 1, y)
        push(x, y + 1)
        push(x, y - 1)
    return bg


def design_mask(im, bg):
    """Conjunto de pixels do DESENHO (tudo que não é fundo inundado)."""
    w, h = im.size
    px = im.load()
    mask = set()
    for y in range(h):
        for x in range(w):
            if not bg[y][x]:
                mask.add((x, y))
    return mask


def enclosed_whites(im, bg):
    """Brancos ENCERRADOS pelo desenho (o "D"): claros e não-fundo."""
    w, h = im.size
    px = im.load()
    out = set()
    for y in range(h):
        for x in range(w):
            if bg[y][x]:
                continue
            r, g, b, _ = px[x, y]
            if r >= 200 and g >= 200 and b >= 200:
                out.add((x, y))
    return out


def flood_component(im, seed, is_target):
    """Componente 4-conexo a partir de [seed] onde is_target(x, y)."""
    w, h = im.size
    comp = set()
    stack = [seed]
    comp.add(seed)
    while stack:
        x, y = stack.pop()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if (
                0 <= nx < w and 0 <= ny < h
                and (nx, ny) not in comp
                and is_target(nx, ny)
            ):
                comp.add((nx, ny))
                stack.append((nx, ny))
    return comp


def components(mask):
    """Componentes 4-conexos do conjunto de pixels [mask]."""
    comps = []
    seen = set()
    for seed in mask:
        if seed in seen:
            continue
        comp = set()
        stack = [seed]
        seen.add(seed)
        comp.add(seed)
        while stack:
            x, y = stack.pop()
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nb = (x + dx, y + dy)
                if nb in mask and nb not in seen:
                    seen.add(nb)
                    comp.add(nb)
                    stack.append(nb)
        comps.append(comp)
    return comps


def trace(mask):
    """Moore boundary tracing -> contorno externo ordenado (lista de tuplas).

    Caminha a borda do componente que contém o pixel mais à esquerda-topo
    do conjunto, em 8-vizinhança, sentido anti-horário (consistente —
    qualquer sentido serve para o fill do SVG)."""
    if not mask:
        return []
    sx = min(x for x, _ in mask)
    start = (sx, min(y for x, y in mask if x == sx))
    boundary = []
    b = start
    c = (b[0] - 1, b[1])  # vizinho oeste (fora da região)
    dirs = [(-1, -1), (-1, 0), (-1, 1), (0, 1), (1, 1), (1, 0), (1, -1), (0, -1)]
    guard = 0
    while guard < max(len(mask) * 4, 64):
        guard += 1
        boundary.append(b)
        dx, dy = c[0] - b[0], c[1] - b[1]
        try:
            idx0 = dirs.index((dx, dy))
        except ValueError:
            idx0 = 4
        found = None
        nxt_c = None
        for k in range(8):
            d = dirs[(idx0 + k) % 8]
            nb = (b[0] + d[0], b[1] + d[1])
            if nb in mask:
                found = nb
                dp = dirs[(idx0 + k - 1) % 8]
                nxt_c = (b[0] + dp[0], b[1] + dp[1])
                break
        if found is None:
            break
        b, c = found, nxt_c
        if b == start:
            break
    return boundary


def to_path(boundary, step=2):
    pts = boundary[::step]
    if not pts:
        return ''
    d = 'M %d %d' % pts[0]
    for x, y in pts[1:]:
        d += ' L %d %d' % (x, y)
    return d + ' Z'


def main():
    src = find_src()
    im = Image.open(src).convert('RGBA')
    w, h = im.size
    print('anexo: %dx%d %s' % (w, h, os.path.basename(src)))

    bg = flood_bg(im)
    xs = [x for y in range(h) for x in range(w) if not bg[y][x]]
    ys = [y for y in range(h) for x in range(w) if not bg[y][x]]
    dx0, dx1, dy0, dy1 = min(xs), max(xs), min(ys), max(ys)
    print('desenho no anexo: bbox=(%d,%d,%d,%d) w=%d h=%d'
          % (dx0, dy0, dx1, dy1, dx1 - dx0, dy1 - dy0))

    # Fundo -> branco puro (o "D" branco encerrado fica intacto).
    px = im.load()
    for y in range(h):
        for x in range(w):
            if bg[y][x]:
                px[x, y] = (255, 255, 255, 255)

    # Escala UNIFORME para caber em 1024 (anexo é mais alto que largo —
    # 457x524 — logo a escala é 1024/altura) + margens brancas iguais.
    s = SIZE / h
    nw = int(round(w * s))
    scaled = im.resize((nw, SIZE), Image.LANCZOS)
    canvas = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 255))
    off_x = (SIZE - nw) // 2
    canvas.paste(scaled, (off_x, 0))
    canvas.save(MASTER)
    print('mestre gerado: %s (%dx%d, escala %.3f, offset x %d)'
          % (MASTER, canvas.width, canvas.height, s, off_x))

    # ── favicon SVG vetorial (mesma geometria do anexo) ────────────────
    m = Image.open(MASTER).convert('RGBA')
    mpx = m.load()
    mbg = flood_bg(m)
    design = design_mask(m, mbg)
    outer = trace(design)

    # Brancos ENCERRADOS: o "D" (maior) e o interior do arco — desenhados
    # em branco sobre o corpo. Os resíduos minúsculos de anti-aliasing do
    # anexo (fendas finas no corpo, < 5000 px) são ignorados: invisíveis no
    # favicon e só sujariam o vetor.
    white_paths = [
        to_path(trace(comp), 2)
        for comp in components(enclosed_whites(m, mbg))
        if len(comp) >= 5000
    ]

    def is_blue(x, y):
        r, g, b, a = mpx[x, y]
        return a >= 128 and b > 110 and b > r + 15

    # Corpo = componente azul que contém o pixel mais à esquerda-topo do
    # desenho; o blob é o componente azul RESTANTE (dentro do "D").
    bx0 = min(x for x, _ in design)
    body = flood_component(m, (bx0, min(y for x, y in design if x == bx0)), is_blue)
    blob_px = [p for p in design if is_blue(*p) and p not in body]
    blob_path = ''
    blob_color = '#3D8EFD'
    if blob_px:
        blob = set(blob_px)
        blob_path = to_path(trace(blob), 1)
        bxs = [x for x, _ in blob]
        bys = [y for _, y in blob]
        bcx = min(bxs) + (max(bxs) - min(bxs)) // 2
        bcy = min(bys) + (max(bys) - min(bys)) // 2
        r, g, b, _ = mpx[bcx, bcy]
        blob_color = '#%02X%02X%02X' % (r, g, b)

    # Gradiente vertical: em cada linha de amostra, procura o pixel AZUL
    # MAIS SATURADO (max b−r) varrendo a largura do desenho — evita o "D",
    # o interior do arco e os pixels de borda anti-aliasada (pálidos).
    mx0, my0 = min(x for x, _ in design), min(y for _, y in design)
    mx1, my1 = max(x for x, _ in design), max(y for _, y in design)
    stops = []
    for frac in (0.1, 0.5, 0.9):
        sy = my0 + int((my1 - my0) * frac)
        best = None
        best_score = -1
        for ox in range(mx0 + 20, mx1 - 20):
            r, g, b, a = mpx[ox, sy]
            if a >= 128 and b > 110 and b > r + 15:
                score = b - r
                if score > best_score:
                    best_score = score
                    best = (r, g, b)
        if best is not None:
            stops.append((sy, best))
    if len(stops) < 2:
        stops = [(my0, (50, 188, 254)), (my1, (183, 204, 246))]

    def stop_tag(y, c):
        # Offsets PERCENTUAIS: Chrome rejeita lengths ("147px") em
        # gradientes userSpaceOnUse e o fill cai para none (invisível).
        return ('      <stop offset="%.2f%%" stop-color="#%02X%02X%02X"/>'
                % (y / SIZE * 100, c[0], c[1], c[2]))

    svg = (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">\n'
        '  <defs>\n'
        '    <linearGradient id="bg" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="0" y2="1024">\n'
        + '\n'.join(stop_tag(y, c) for y, c in stops) + '\n'
        '    </linearGradient>\n'
        '  </defs>\n'
        '  <rect width="1024" height="1024" fill="#FFFFFF"/>\n'
        '  <path d="%s" fill="url(#bg)"/>\n' % to_path(outer, 2)
        + ''.join('  <path d="%s" fill="#FFFFFF"/>\n' % p for p in white_paths)
        + ('  <path d="%s" fill="%s"/>\n' % (blob_path, blob_color) if blob_path else '')
        + '</svg>\n'
    )
    with open(FAVICON_SVG, 'w', encoding='utf-8') as f:
        f.write(svg)
    print('favicon svg gerado: %s (%d bytes, %d stops, contorno %d pts, '
          'brancos %d paths, blob %d px)'
          % (FAVICON_SVG, len(svg), len(stops), len(outer),
             len(white_paths), len(blob_px)))

    # ── verificação de fidelidade: mestre downscaled vs anexo normalizado
    back = canvas.resize((w, h), Image.LANCZOS)
    ref = Image.open(src).convert('RGBA')
    rp = ref.load()
    for y in range(h):
        for x in range(w):
            if bg[y][x]:
                rp[x, y] = (255, 255, 255, 255)
    diff = 0
    n = 0
    bp = back.load()
    for y in range(0, h, 2):
        for x in range(0, w, 2):
            r1, g1, b1, _ = rp[x, y]
            r2, g2, b2, _ = bp[x, y]
            diff += abs(r1 - r2) + abs(g1 - g2) + abs(b1 - b2)
            n += 1
    print('fidelidade mestre vs anexo (MAE/255): %.1f' % (diff / (n * 3)))


if __name__ == '__main__':
    main()
