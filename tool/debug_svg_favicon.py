# Diagnóstico do favicon SVG: isola se o problema é o gradiente (url(#bg))
# e gera a versão com offsets PERCENTUAIS (universalmente suportado).
import re
import subprocess
import os

ROOT = 'C:/Users/emili/Desktop/c'
SVG = os.path.join(ROOT, 'web/icons/favicon.svg')
TEST = os.path.join(ROOT, 'build/svgtest')
CHROME = 'C:/Program Files/Google/Chrome/Application/chrome.exe'

svg = open(SVG, encoding='utf-8').read()

# 1) Variante com fill sólido (isola o gradiente)
solid = svg.replace('fill="url(#bg)"', 'fill="#1234FE"')
open(os.path.join(TEST, 'test_solid.svg'), 'w', encoding='utf-8').write(solid)

# 2) Variante com offsets percentuais (0-100% ao longo do gradiente 0..1024)
def pct(m):
    return 'offset="%.2f%%"' % (int(m.group(1)) / 1024 * 100)
pct_svg = re.sub(r'offset="(\d+)px"', pct, svg)
open(os.path.join(TEST, 'test_pct.svg'), 'w', encoding='utf-8').write(pct_svg)

def render(name):
    page = os.path.join(TEST, name + '.html')
    with open(page, 'w', encoding='utf-8') as f:
        f.write('<!DOCTYPE html><html><head><style>html,body{margin:0;padding:0;background:#fff}'
                'svg{width:1024px;height:1024px;display:block}</style></head><body>')
        f.write(open(os.path.join(TEST, name + '.svg'), encoding='utf-8').read())
        f.write('</body></html>')
    out = os.path.join(TEST, name + '.png')
    subprocess.run([CHROME, '--headless=new', '--disable-gpu',
                    '--screenshot=' + out, '--window-size=1024,1024',
                    '--default-background-color=FFFFFFFF',
                    'file:///' + page.replace('\\', '/')],
                   capture_output=True)
    return out

for name in ('test_solid', 'test_pct'):
    out = render(name)
    print(name, '->', out)

# Comparação dos renders com o mestre
from PIL import Image, ImageChops, ImageStat
master = Image.open(os.path.join(ROOT, 'assets/branding/icon_official.png')).convert('RGB')
for name in ('test_solid', 'test_pct'):
    im = Image.open(os.path.join(TEST, name + '.png')).convert('RGB')
    mae = sum(ImageStat.Stat(ImageChops.difference(im, master)).mean) / 3
    # bbox dos azuis
    px = im.load()
    xs = [x for y in range(1024) for x in range(1024)
          if (lambda r, g, b: b > 150 and b > r + 30)(*px[x, y][:3])]
    ys = [y for y in range(1024) for x in range(1024)
          if (lambda r, g, b: b > 150 and b > r + 30)(*px[x, y][:3])]
    print('%s: MAE=%.1f | azuis bbox x %d-%d y %d-%d' % (
        name, mae, min(xs), max(xs), min(ys), max(ys)))
