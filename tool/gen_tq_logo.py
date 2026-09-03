#!/usr/bin/env python3
"""Generate TQ monogram logo from the user's design specifications.

The TQ monogram:
- T: horizontal bar + vertical stem
- Q: thick circle + vertical bar extending below
- White on black (icon_official), Black on white (foreground)
"""

import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BRANDING_DIR = os.path.join(ROOT, 'assets', 'branding')

SIZE = 1024


def draw_tq_monogram(draw, cx, cy, scale, fill):
    """Draw TQ monogram centered at (cx, cy) with given scale and fill color.
    
    Based on the user's reference images:
    - T: horizontal bar at top, vertical stem below
    - Q: circle with vertical bar extending through bottom
    """
    # T dimensions
    t_bar_w = int(160 * scale)   # horizontal bar width
    t_bar_h = int(32 * scale)    # horizontal bar height
    t_stem_w = int(40 * scale)   # vertical stem width
    t_stem_h = int(130 * scale)  # vertical stem height
    
    # Q dimensions
    q_radius = int(95 * scale)    # circle outer radius
    q_thickness = int(32 * scale) # ring thickness
    q_bar_w = int(40 * scale)    # vertical bar width  
    q_bar_h = int(170 * scale)   # total bar height (extends below circle)
    
    # Spacing between T and Q
    gap = int(20 * scale)
    
    # Calculate positions
    # T center X
    t_cx = cx - (q_radius + gap/2 + t_bar_w/2 - q_radius) / 2 + (t_bar_w/2 - q_radius) / 2
    # Simpler approach: place T and Q side by side centered
    total_w = t_bar_w + gap + q_radius * 2
    start_x = cx - total_w / 2
    
    # T position
    t_left = start_x
    t_top = cy - max(t_bar_h, q_radius) - int(10 * scale)
    
    # Draw T - horizontal bar
    t_bar_left = t_left
    t_bar_top = t_top
    draw.rectangle(
        [t_bar_left, t_bar_top, t_bar_left + t_bar_w, t_bar_top + t_bar_h],
        fill=fill
    )
    
    # Draw T - vertical stem (centered on bar)
    t_stem_left = t_bar_left + (t_bar_w - t_stem_w) / 2
    t_stem_top = t_bar_top + t_bar_h + int(8 * scale)
    draw.rectangle(
        [t_stem_left, t_stem_top, t_stem_left + t_stem_w, t_stem_top + t_stem_h],
        fill=fill
    )
    
    # Q position
    q_cx = start_x + t_bar_w + gap + q_radius
    q_cy = cy - int(10 * scale)  # slight offset to align with T
    
    # Draw Q - thick circle (ring)
    outer_box = [q_cx - q_radius, q_cy - q_radius, q_cx + q_radius, q_cy + q_radius]
    inner_r = q_radius - q_thickness
    inner_box = [q_cx - inner_r, q_cy - inner_r, q_cx + inner_r, q_cy + inner_r]
    
    draw.ellipse(outer_box, fill=fill)
    # Cut out inner circle (use background color or draw with bg)
    draw.ellipse(inner_box, fill=(0, 0, 0) if fill == (255, 255, 255) else (255, 255, 255))
    
    # Draw Q - vertical bar extending through bottom
    q_bar_left = q_cx - q_bar_w / 2
    q_bar_top = q_cy - q_radius + int(10 * scale)
    q_bar_bottom = q_cy + q_radius + int(60 * scale)
    draw.rectangle(
        [q_bar_left, q_bar_top, q_bar_left + q_bar_w, q_bar_bottom],
        fill=fill
    )
    
    # Cut the inner circle hole in the vertical bar
    # Find where the bar intersects the inner circle
    inner_top = q_cy - inner_r
    inner_bottom = q_cy + inner_r
    bar_center_x = q_cx
    
    # The bar passes through the inner circle - we need to NOT draw the bar
    # inside the inner circle. But since we already drew the inner circle cutout,
    # the bar was drawn after the cutout, so we need to re-cut it.
    # Actually, we drew the bar after the inner circle, so we need to cut it.
    bg = (0, 0, 0) if fill == (255, 255, 255) else (255, 255, 255)
    
    # Re-draw inner circle to cut the bar
    draw.ellipse(inner_box, fill=bg)
    
    # But now we lost the ring parts that don't overlap with the bar.
    # Redraw the ring
    draw.ellipse(outer_box, fill=fill)
    draw.ellipse(inner_box, fill=bg)
    
    # Now draw the vertical bar, but ONLY the parts outside the inner circle
    # Top part of bar (above inner circle)
    if q_bar_top < inner_top:
        draw.rectangle(
            [q_bar_left, q_bar_top, q_bar_left + q_bar_w, inner_top],
            fill=fill
        )
    # Bottom part of bar (below inner circle)
    draw.rectangle(
        [q_bar_left, inner_bottom, q_bar_left + q_bar_w, q_bar_bottom],
        fill=fill
    )


def draw_tq_clean(draw, size, fill):
    """Draw a clean TQ monogram matching the reference images exactly.
    
    Reference: The T has a wide horizontal bar and short vertical stem.
    The Q is a thick ring with a vertical bar extending below.
    """
    cx, cy = size // 2, size // 2
    scale = size / 1024.0
    
    # Padding
    pad = int(180 * scale)
    
    # Available drawing area
    area_w = size - 2 * pad
    area_h = size - 2 * pad
    
    # T parameters
    t_bar_w = int(area_w * 0.38)   # wide horizontal bar
    t_bar_h = int(area_h * 0.075)  # thin bar
    t_stem_w = int(area_w * 0.10)  # narrow stem
    t_stem_h = int(area_h * 0.28)  # stem height
    
    # Q parameters
    q_outer = int(area_h * 0.37)   # outer radius
    q_inner = int(area_h * 0.22)   # inner radius (ring thickness)
    q_bar_w = int(area_w * 0.10)  # bar width
    q_bar_ext = int(area_h * 0.28) # extension below circle
    
    # Gap between T and Q
    gap = int(area_w * 0.06)
    
    # Vertical alignment
    top_y = pad + int(area_h * 0.12)
    
    # === Draw T ===
    t_x = pad + int(area_w * 0.05)
    
    # Horizontal bar
    draw.rectangle(
        [t_x, top_y, t_x + t_bar_w, top_y + t_bar_h],
        fill=fill
    )
    
    # Vertical stem (centered on bar)
    stem_x = t_x + (t_bar_w - t_stem_w) // 2
    stem_top = top_y + t_bar_h + int(4 * scale)
    draw.rectangle(
        [stem_x, stem_top, stem_x + t_stem_w, stem_top + t_stem_h],
        fill=fill
    )
    
    # === Draw Q ===
    q_cx = t_x + t_bar_w + gap + q_outer
    q_cy = top_y + t_bar_h + int(4 * scale) + t_stem_h * 0.45
    
    # Outer circle
    draw.ellipse(
        [q_cx - q_outer, q_cy - q_outer, q_cx + q_outer, q_cy + q_outer],
        fill=fill
    )
    # Inner cutout
    draw.ellipse(
        [q_cx - q_inner, q_cy - q_inner, q_cx + q_inner, q_cy + q_inner],
        fill=(0, 0, 0)
    )
    
    # Vertical bar through Q (only below and above the inner hole)
    bar_x = q_cx - q_bar_w // 2
    
    # Part below inner circle
    bar_below_top = q_cy + q_inner
    bar_below_bottom = q_cy + q_outer + q_bar_ext
    draw.rectangle(
        [bar_x, bar_below_top, bar_x + q_bar_w, bar_below_bottom],
        fill=fill
    )
    
    # Part above inner circle (from top of outer to top of inner)
    bar_above_top = q_cy - q_outer
    bar_above_bottom = q_cy - q_inner
    draw.rectangle(
        [bar_x, bar_above_top, bar_x + q_bar_w, bar_above_bottom],
        fill=fill
    )


def generate_all():
    """Generate all logo assets."""
    os.makedirs(BRANDING_DIR, exist_ok=True)
    
    # 1. icon_official.png — white TQ on black background (master)
    img = Image.new('RGB', (SIZE, SIZE), (0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_tq_clean(draw, SIZE, (255, 255, 255))
    img.save(os.path.join(BRANDING_DIR, 'icon_official.png'), 'PNG')
    print(f"✓ icon_official.png ({SIZE}x{SIZE})")
    
    # 2. splash_logo.png — white TQ on transparent (for dark splash)
    img_splash = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw_splash = ImageDraw.Draw(img_splash)
    draw_tq_clean(draw_splash, SIZE, (255, 255, 255, 255))
    img_splash.save(os.path.join(BRANDING_DIR, 'splash_logo.png'), 'PNG')
    print(f"✓ splash_logo.png ({SIZE}x{SIZE}, RGBA)")
    
    # 3. icon_fg.png — white TQ on transparent (adaptive foreground)
    img_fg = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw_fg = ImageDraw.Draw(img_fg)
    draw_tq_clean(draw_fg, SIZE, (255, 255, 255, 255))
    img_fg.save(os.path.join(BRANDING_DIR, 'icon_fg.png'), 'PNG')
    print(f"✓ icon_fg.png ({SIZE}x{SIZE}, RGBA)")
    
    # 4. icon_mono.png — white TQ on transparent (monochrome/themed)
    img_mono = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw_mono = ImageDraw.Draw(img_mono)
    draw_tq_clean(draw_mono, SIZE, (255, 255, 255, 255))
    img_mono.save(os.path.join(BRANDING_DIR, 'icon_mono.png'), 'PNG')
    print(f"✓ icon_mono.png ({SIZE}x{SIZE}, RGBA)")
    
    # 5. icon_legacy.png — white TQ on black (legacy icon)
    img_legacy = Image.new('RGB', (SIZE, SIZE), (0, 0, 0))
    draw_legacy = ImageDraw.Draw(img_legacy)
    draw_tq_clean(draw_legacy, SIZE, (255, 255, 255))
    img_legacy.save(os.path.join(BRANDING_DIR, 'icon_legacy.png'), 'PNG')
    print(f"✓ icon_legacy.png ({SIZE}x{SIZE})")
    
    print("\nAll branding assets generated!")


if __name__ == '__main__':
    generate_all()
