# Verificacao pos-build do icone oficial v4.2 (sacola azul 3D + "D" branco).
# Uso: python tool/check_apk_icon.py build/app/outputs/flutter-apk/app-dev-debug.apk
import sys
import zipfile
import io

from PIL import Image


def logo_stats(path):
    im = Image.open(path).convert('RGBA')
    w, h = im.size
    px = im.load()
    blue_xs, blue_ys = [], []
    white_inside = white_outside = 0
    for y in range(0, h, 2):
        for x in range(0, w, 2):
            r, g, b, a = px[x, y]
            if a > 60 and b > r + 25 and b > g + 10:
                blue_xs.append(x)
                blue_ys.append(y)
    if not blue_xs:
        return None, None, 0, 0
    bx0, bx1 = min(blue_xs), max(blue_xs)
    by0, by1 = min(blue_ys), max(blue_ys)
    for y in range(0, h, 2):
        for x in range(0, w, 2):
            r, g, b, a = px[x, y]
            if a > 200 and r > 230 and g > 230 and b > 230:
                if bx0 <= x <= bx1 and by0 <= y <= by1:
                    white_inside += 1
                else:
                    white_outside += 1
    bw = 100 * (bx1 - bx0) / w
    bh = 100 * (by1 - by0) / h
    return bw, bh, white_inside, white_outside


def main():
    apk = sys.argv[1]
    z = zipfile.ZipFile(apk)
    found = 0
    for n in z.namelist():
        if n.startswith('res/'):
            base = n.split('/')[-1]
            if base == 'ic_launcher.png' and 'xxxhdpi' in n:
                bw, bh, wi, wo = logo_stats(io.BytesIO(z.read(n)))
                print('launcher %s: sacola %.0f%%x%.0f%% | brancos dentro: %d fora: %d' % (n, bw, bh, wi, wo))
                found += 1
            elif base == 'ic_launcher_foreground.png' and 'xxxhdpi' in n:
                bw, bh, wi, wo = logo_stats(io.BytesIO(z.read(n)))
                print('foreground %s: sacola %.0f%%x%.0f%% | D/ilhos dentro: %d fora: %d' % (n, bw, bh, wi, wo))
                found += 1
    # splash asset bundlado
    for n in z.namelist():
        if 'splash_logo' in n:
            bw, bh, wi, wo = logo_stats(io.BytesIO(z.read(n)))
            print('splash_logo: sacola %.0f%%x%.0f%% | D/ilhos dentro: %d fora: %d' % (bw, bh, wi, wo))
            found += 1
    print('verificados:', found, 'entradas')


if __name__ == '__main__':
    main()
