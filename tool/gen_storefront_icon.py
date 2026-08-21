#!/usr/bin/env python3
"""
Gera os ícones do app com fundo azul gradiente e design simplificado
estilo storefront (corresponde ao login screen — Icons.storefront_rounded).

  python tool/gen_storefront_icon.py

Design:
- Fundo: gradiente azul #0076F6 → #005BBB (matching login squircle)
- Desenho: silhueta branca simplificada (barraca/storefront planar)
"""

import math
import os

from PIL import Image, ImageDraw

S = 4096  # supersample
SS = S // 1024

BLUE_TOP = (0, 118, 246)     # #0076F6
BLUE_BOT = (0, 91, 187)      # #005BBB
WHITE = (255, 255, 255)

# Output paths
OUT_DIR = 'assets/branding'
OUT_OFFICIAL = os.path.join(OUT_DIR, 'icon_official.png')
OUT_LEGACY = os.path.join(OUT_DIR, 'icon_legacy.png')
OUT_FG = os.path.join(OUT_DIR, 'icon_fg.png')
OUT_MONO = os.path.join(OUT_DIR, 'icon_mono.png')
OUT_SPLASH = os.path.join(OUT_DIR, 'splash_logo.png')


def sc(v):
    """Scale from 1024-unit coords to actual pixel coords."""
    return int(v * SS)


def make_gradient(w, h, top_color, bot_color):
    """Create a vertical gradient image."""
    img = Image.new('RGB', (w, h))
    pixels = img.load()
    for y in range(h):
        ratio = y / max(h - 1, 1)
        r = int(top_color[0] + (bot_color[0] - top_color[0]) * ratio)
        g = int(top_color[1] + (bot_color[1] - top_color[1]) * ratio)
        b = int(top_color[2] + (bot_color[2] - top_color[2]) * ratio)
        for x in range(w):
            pixels[x, y] = (r, g, b)
    return img


def draw_storefront_mask(draw_ctx):
    """
    Storefront silhouette — simplified geometric shape:
    - A rectangular body (shop front)
    - A triangular/rounded roof
    - Two vertical pillars
    - A door opening in the center
    All in 1024-unit coordinates.
    """
    # Body of the shop (main rectangle)
    # Centered horizontally, in lower 60% of canvas
    body_left = 200
    body_right = 824
    body_top = 360
    body_bottom = 800

    # Draw main body
    draw_ctx.rectangle(
        [sc(body_left), sc(body_top), sc(body_right), sc(body_bottom)],
        fill=255,
    )

    # Roof — a wide trapezoid / awning shape
    # Top of roof at y=180, bottom at body_top
    roof_top = 170
    roof_top_left = 160
    roof_top_right = 864
    roof_bottom_left = body_left - 30
    roof_bottom_right = body_right + 30

    draw_ctx.polygon([
        (sc(roof_top_left), sc(roof_top)),
        (sc(roof_top_right), sc(roof_top)),
        (sc(roof_bottom_right), sc(body_top)),
        (sc(roof_bottom_left), sc(body_top)),
    ], fill=255)

    # Pillars — two vertical rectangles
    pillar_width = 55
    # Left pillar
    draw_ctx.rectangle(
        [sc(body_left), sc(body_top), sc(body_left + pillar_width), sc(body_bottom)],
        fill=255,
    )
    # Right pillar
    draw_ctx.rectangle(
        [sc(body_right - pillar_width), sc(body_top), sc(body_right), sc(body_bottom)],
        fill=255,
    )

    # Door opening — cut out (black) in center-bottom
    door_left = 390
    door_right = 634
    door_top = 500
    door_bottom = body_bottom
    draw_ctx.rectangle(
        [sc(door_left), sc(door_top), sc(door_right), sc(door_bottom)],
        fill=0,
    )

    # Door arch — semicircle on top of door opening
    door_cx = (door_left + door_right) // 2
    door_rx = (door_right - door_left) // 2
    door_ry = door_rx  # perfect semicircle
    draw_ctx.ellipse(
        [sc(door_cx - door_rx), sc(door_top - door_ry),
         sc(door_cx + door_rx), sc(door_top + door_ry)],
        fill=0,
    )

    # Window cutouts — two rectangular windows on either side of door
    win_top = 400
    win_bottom = 470
    # Left window
    draw_ctx.rectangle(
        [sc(250), sc(win_top), sc(360), sc(win_bottom)],
        fill=0,
    )
    # Right window
    draw_ctx.rectangle(
        [sc(664), sc(win_top), sc(774), sc(win_bottom)],
        fill=0,
    )


def generate_icons():
    os.makedirs(OUT_DIR, exist_ok=True)

    # 1. Create the white mask
    mask = Image.new('L', (S, S), 0)
    draw = ImageDraw.Draw(mask)
    draw_storefront_mask(draw)

    # 2. Create gradient canvas
    canvas = make_gradient(S, S, BLUE_TOP, BLUE_BOT).convert('RGBA')

    # 3. Apply white silhouette
    white_layer = Image.new('RGBA', (S, S), WHITE + (0,))
    white_layer.putalpha(mask)
    canvas = Image.alpha_composite(canvas, white_layer)

    # 4. Resize to 1024 for the master
    icon = canvas.resize((1024, 1024), Image.LANCZOS)
    icon.save(OUT_OFFICIAL)
    print(f'gerado: {OUT_OFFICIAL} ({icon.size[0]}×{icon.size[1]})')

    # 5. Legacy: full image (opaque, for Android <8, iOS, web)
    legacy = icon.copy()
    legacy.save(OUT_LEGACY)
    print(f'gerado: {OUT_LEGACY}')

    # 6. Foreground adaptive: full icon (blue bg + white shape) at ~92%
    #    with transparent corners — the adaptive bg color fills behind.
    fg_size = int(1024 * 0.92)
    fg_icon = icon.resize((fg_size, fg_size), Image.LANCZOS)
    fg_canvas = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
    fg_offset = (1024 - fg_size) // 2
    fg_canvas.paste(fg_icon, (fg_offset, fg_offset), fg_icon)
    fg_canvas.save(OUT_FG)
    print(f'gerado: {OUT_FG}')

    # 7. Monochrome: white storefront shape on transparent
    #    (for Android 13+ themed icons — only the alpha channel matters)
    mono_fg = mask.resize((1024, 1024), Image.LANCZOS)
    white_mono = Image.new('RGBA', (1024, 1024), WHITE + (0,))
    white_mono.putalpha(mono_fg)
    white_mono.save(OUT_MONO)
    print(f'gerado: {OUT_MONO}')

    # 8. Splash: full icon at ~88% centered on transparent
    splash_size = int(1024 * 0.88)
    splash_icon = icon.resize((splash_size, splash_size), Image.LANCZOS)
    splash = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
    splash_offset = (1024 - splash_size) // 2
    splash.paste(splash_icon, (splash_offset, splash_offset), splash_icon)
    splash.save(OUT_SPLASH)
    print(f'gerado: {OUT_SPLASH}')

    # 9. Web favicons
    web_dir = 'web/icons'
    os.makedirs(web_dir, exist_ok=True)
    for size, name in [(192, 'icon-192.png'), (512, 'icon-512.png')]:
        resized = icon.resize((size, size), Image.LANCZOS)
        resized.save(os.path.join(web_dir, name))
        print(f'gerado: {web_dir}/{name}')

    # Favicon (32x32)
    favicon = icon.resize((32, 32), Image.LANCZOS)
    favicon.save(os.path.join(web_dir, 'favicon.png'))
    print(f'gerado: {web_dir}/favicon.png')

    # 10. Android launch images
    android_dir = 'android/app/src/main/res/drawable-nodpi'
    os.makedirs(android_dir, exist_ok=True)
    launch = icon.resize((384, 384), Image.LANCZOS)
    launch.save(os.path.join(android_dir, 'launch_image.png'))
    print(f'gerado: {android_dir}/launch_image.png')

    # 11. iOS LaunchImage 1x/2x/3x
    ios_dir = 'ios/Runner/Assets.xcassets/LaunchImage.imageset'
    os.makedirs(ios_dir, exist_ok=True)
    for scale, name in [(1, 'LaunchImage.png'),
                        (2, 'LaunchImage@2x.png'),
                        (3, 'LaunchImage@3x.png')]:
        sz = 168 * scale  # standard iOS launch image size
        img = icon.resize((sz, sz), Image.LANCZOS)
        img.save(os.path.join(ios_dir, name))
        print(f'gerado: {ios_dir}/{name}')

    print('\n✅ Todos os ícones gerados com o design storefront azul!')


if __name__ == '__main__':
    generate_icons()
