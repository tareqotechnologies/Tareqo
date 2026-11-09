# Verificacao pos-build do icone oficial (monograma TQ, paleta oficial:
# preto #0C0B0A + branco suave #F9F9F9).
# Uso: python tool/check_apk_icon.py build/app/outputs/flutter-apk/app-dev-debug.apk
import io
import sys
import zipfile

from PIL import Image

# Paleta oficial — pixel "claro" e "escuro" (tolerância cobre antialiasing).
_DARK_MAX = 40
_LIGHT_MIN = 200


def logo_stats(path):
    im = Image.open(path).convert('RGBA')
    w, h = im.size
    px = im.load()
    light_xs, light_ys = [], []
    dark = light = blue = 0
    for y in range(0, h, 2):
        for x in range(0, w, 2):
            r, g, b, a = px[x, y]
            if a <= 60:
                continue
            if r >= _LIGHT_MIN and g >= _LIGHT_MIN and b >= _LIGHT_MIN:
                light += 1
                light_xs.append(x)
                light_ys.append(y)
            elif r <= _DARK_MAX and g <= _DARK_MAX and b <= _DARK_MAX:
                dark += 1
            # Qualquer azul indica asset antigo fora da paleta.
            if b > r + 25 and b > g + 10:
                blue += 1
    if not light_xs:
        return None
    bw = 100 * (max(light_xs) - min(light_xs)) / w
    bh = 100 * (max(light_ys) - min(light_ys)) / h
    return bw, bh, dark, light, blue


def report(name, stats):
    if stats is None:
        print('%s: sem desenho claro — verificar asset' % name)
        return
    bw, bh, dark, light, blue = stats
    warning = ' | AVISO: azul fora da paleta' if blue else ''
    print(
        '%s: monograma %.0f%%x%.0f%% | preto %d claro %d%s'
        % (name, bw, bh, dark, light, warning)
    )


def main():
    apk = sys.argv[1]
    z = zipfile.ZipFile(apk)
    found = 0
    for n in z.namelist():
        if not n.startswith('res/'):
            continue
        base = n.split('/')[-1]
        if base in ('ic_launcher.png', 'ic_launcher_foreground.png') and 'xxxhdpi' in n:
            report(n, logo_stats(io.BytesIO(z.read(n))))
            found += 1
    for n in z.namelist():
        if 'splash_logo' in n:
            report('splash_logo', logo_stats(io.BytesIO(z.read(n))))
            found += 1
    print('verificados:', found, 'entradas')


if __name__ == '__main__':
    main()
