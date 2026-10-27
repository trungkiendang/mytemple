"""Generates the app icon (assets/icon/*.png): a vermilion wooden fish (mõ) inside a ring of
golden lotus petals under a crescent moon. Run: python3 scripts/generate_app_icon.py
(needs Pillow). The PNGs are then turned into platform icons with
`dart run flutter_launcher_icons`."""
import math
import os
from PIL import Image, ImageChops, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'icon')
S = 2048  # supersampled canvas, downscaled to 1024
C = S // 2


def petal(length, width, angle, cx=C, cy=C, start=0.0):
    pts = []
    n = 40
    for i in range(n + 1):  # outline: out along one side, back along the other
        t = i / n
        r = start + (length - start) * t
        w = width * math.sin(math.pi * min(1, t * 1.05)) ** 0.8
        pts.append((r, w))
    for i in range(n, -1, -1):
        t = i / n
        r = start + (length - start) * t
        w = width * math.sin(math.pi * min(1, t * 1.05)) ** 0.8
        pts.append((r, -w))
    a = math.radians(angle)
    return [(cx + r * math.cos(a) - w * math.sin(a), cy + r * math.sin(a) + w * math.cos(a)) for r, w in pts]


def radial(size, center, radius, inner, outer):
    img = Image.new('RGB', (size, size), outer)
    px = img.load()
    for y in range(size):
        for x in range(size):
            d = min(1.0, math.hypot(x - center[0], y - center[1]) / radius)
            px[x, y] = tuple(int(inner[k] + (outer[k] - inner[k]) * d) for k in range(3))
    return img


def blend_gradient(box, inner, outer, mask):
    """Fill `mask` with a radial gradient centred in `box`."""
    cx, cy, r = box
    g = radial(S, (cx, cy), r, inner, outer).convert('RGBA')
    g.putalpha(mask)
    return g


def layer_emblem(with_moon=True):
    """Full moon halo + lotus pedestal + wooden fish + mallet, on a transparent layer."""
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))

    if with_moon:
        halo = Image.new('RGBA', (S, S), (0, 0, 0, 0))
        ImageDraw.Draw(halo).ellipse((C - 700, C - 800, C + 700, C + 600), fill=(255, 214, 120, 90))
        img.alpha_composite(halo.filter(ImageFilter.GaussianBlur(60)))
        m = Image.new('L', (S, S), 0)
        ImageDraw.Draw(m).ellipse((C - 640, C - 740, C + 640, C + 540), fill=255)
        img.alpha_composite(blend_gradient((C, C - 300, 700), (255, 232, 160), (214, 166, 60), m))

    d = ImageDraw.Draw(img, 'RGBA')

    # lotus pedestal: dark-red back petals, ivory front petals
    base = (C, C + 720)
    for ang in [-90 + 20 * k for k in range(-4, 5)]:
        d.polygon(petal(600, 135, ang, cx=base[0], cy=base[1], start=20), fill=(150, 34, 24, 255))
    for ang in [-90 + 24 * k for k in range(-3, 4)]:
        poly = petal(520, 120, ang, cx=base[0], cy=base[1], start=20)
        d.polygon(poly, fill=(250, 236, 200, 255))
        d.line(poly + [poly[0]], fill=(170, 120, 40, 255), width=8)

    # wooden fish: teardrop = round back dome + tapered snout on the right
    body = Image.new('L', (S, S), 0)
    bd = ImageDraw.Draw(body)
    bd.ellipse((C - 470, C - 330, C + 250, C + 400), fill=255)  # dome
    bd.polygon([(C + 120, C - 260), (C + 520, C + 90), (C + 470, C + 230), (C + 140, C + 390)], fill=255)  # snout
    bd.ellipse((C + 330, C + 40, C + 560, C + 250), fill=255)
    body = body.filter(ImageFilter.GaussianBlur(14)).point(lambda v: 255 if v > 128 else 0).filter(ImageFilter.GaussianBlur(1.2))
    img.alpha_composite(blend_gradient((C - 160, C - 120, 760), (232, 98, 60), (104, 24, 14), body))
    d = ImageDraw.Draw(img, 'RGBA')

    # carved fish: scale band along the flank with a gold outline
    band = Image.new('L', (S, S), 0)
    ImageDraw.Draw(band).ellipse((C - 150, C - 215, C + 470, C + 235), fill=255)
    band = ImageChops.multiply(band, body)
    scales = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    sd = ImageDraw.Draw(scales)
    step = 70
    for row in range(-3, 16):
        for col in range(-3, 16):
            x = C - 190 + col * step + (step // 2 if row % 2 else 0)
            y = C - 240 + row * (step * 0.6)
            sd.arc((x - step // 2, y - step // 2, x + step // 2, y + step // 2), 20, 200, fill=(247, 214, 120, 235), width=7)
    scales.putalpha(ImageChops.multiply(scales.getchannel('A'), band))
    img.alpha_composite(scales)
    d = ImageDraw.Draw(img, 'RGBA')
    d.arc((C - 150, C - 215, C + 470, C + 235), 200, 340, fill=(247, 214, 120, 255), width=10)

    # fish eye, mouth line, whisker; round hole on the back
    d.ellipse((C + 300, C - 20, C + 372, C + 52), fill=(36, 8, 5, 255))
    d.ellipse((C + 322, C + 0, C + 344, C + 22), fill=(255, 240, 200, 255))
    d.arc((C + 330, C + 110, C + 540, C + 230), 10, 120, fill=(36, 8, 5, 255), width=14)
    d.line([(C + 470, C + 80), (C + 620, C + 20), (C + 700, C + 70)], fill=(247, 214, 120, 255), width=12, joint='curve')
    for k in range(3):
        d.arc((C + 100 + k * 34, C - 200, C + 220 + k * 34, C + 250), -55, 55, fill=(247, 214, 120, 255), width=9)

    # mallet: handle + ivory ball resting above the dome
    d.line([(C + 700, C - 700), (C + 130, C - 260)], fill=(96, 48, 22, 255), width=56, joint='curve')
    d.line([(C + 560, C - 590), (C + 510, C - 550)], fill=(247, 214, 120, 255), width=60)
    d.ellipse((C + 20, C - 360, C + 220, C - 160), fill=(252, 244, 222, 255), outline=(150, 100, 40, 255), width=8)
    d.ellipse((C + 55, C - 330, C + 115, C - 270), fill=(255, 255, 255, 210))
    return img


def main():
    os.makedirs(OUT, exist_ok=True)
    emblem = layer_emblem()
    emblem_fg = layer_emblem()

    # full-bleed icon: dark wood radial background + gold ring + emblem
    bg = radial(S, (C, C - 120), 1500, (92, 48, 34), (24, 12, 9)).convert('RGBA')
    ring = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(ring).ellipse((C - 940, C - 940, C + 940, C + 940), outline=(201, 162, 39, 110), width=10)
    bg.alpha_composite(ring)
    bg.alpha_composite(emblem)
    bg.convert('RGB').resize((1024, 1024), Image.LANCZOS).save(os.path.join(OUT, 'app_icon.png'))

    # adaptive-icon foreground: emblem in the safe zone (66%) on transparency
    fg = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    small = emblem.resize((int(S * 0.62), int(S * 0.62)), Image.LANCZOS)
    fg.alpha_composite(small, ((S - small.width) // 2, (S - small.height) // 2))
    fg.resize((1024, 1024), Image.LANCZOS).save(os.path.join(OUT, 'app_icon_foreground.png'))
    print('icons written to', os.path.abspath(OUT))


if __name__ == '__main__':
    main()
