import base64
import os
from PIL import Image

PROJECT_ROOT = "/Users/giammattey/Projetos/buildea/lagcheck"
SCRATCH_DIR = "/Users/giammattey/.gemini/antigravity/brain/357b8009-f996-4a74-84ec-a06b9ecd0965/scratch"

icon_path = os.path.join(SCRATCH_DIR, "icon_approved_exact.png")
wordmark_trans_path = os.path.join(SCRATCH_DIR, "wordmark_approved_transparent.png")

img_icon = Image.open(icon_path).convert("RGBA")
img_wm = Image.open(wordmark_trans_path).convert("RGBA")

# 1. Gerar todos os ícones para Sources/NolaggyApp/Assets.xcassets/AppIcon.appiconset/
appicon_dir = os.path.join(PROJECT_ROOT, "Sources/NolaggyApp/Assets.xcassets/AppIcon.appiconset")

icon_sizes = [
    ("icon-1024.png", 1024, 1024),
    ("appicon-1024-master.png", 1024, 1024),
    ("icon-60@3x.png", 180, 180),
    ("icon-60@2x.png", 120, 120),
    ("icon-40@3x.png", 120, 120),
    ("icon-40@2x.png", 80, 80),
    ("icon-29@3x.png", 87, 87),
    ("icon-29@2x.png", 58, 58),
    ("icon-20@3x.png", 60, 60),
    ("icon-20@2x.png", 40, 40),
    ("icon-thumbnail-256.png", 256, 256)
]

for name, w, h in icon_sizes:
    resized = img_icon.resize((w, h), Image.Resampling.LANCZOS)
    target = os.path.join(appicon_dir, name)
    resized.save(target, format="PNG")
    print(f"Saved {name} ({w}x{h})")

# Master do AppIcon em design-system
ds_icon_master = os.path.join(PROJECT_ROOT, "design-system/assets/app-icon/appicon-1024-master.png")
img_icon.save(ds_icon_master, format="PNG")
print("Saved design-system appicon master")

# 2. Gerar WordmarkPrimary em Sources/NolaggyApp/Assets.xcassets/WordmarkPrimary.imageset/
wm_dir = os.path.join(PROJECT_ROOT, "Sources/NolaggyApp/Assets.xcassets/WordmarkPrimary.imageset")
wm_w, wm_h = img_wm.size
# Base 1x: altura 40pt
scale_1x_h = 40
scale_1x_w = int(wm_w * (scale_1x_h / wm_h))

wm_1x = img_wm.resize((scale_1x_w, scale_1x_h), Image.Resampling.LANCZOS)
wm_2x = img_wm.resize((scale_1x_w * 2, scale_1x_h * 2), Image.Resampling.LANCZOS)
wm_3x = img_wm.resize((scale_1x_w * 3, scale_1x_h * 3), Image.Resampling.LANCZOS)

wm_1x.save(os.path.join(wm_dir, "wordmark-primary.png"), format="PNG")
wm_2x.save(os.path.join(wm_dir, "wordmark-primary@2x.png"), format="PNG")
wm_3x.save(os.path.join(wm_dir, "wordmark-primary@3x.png"), format="PNG")
print(f"Saved WordmarkPrimary scales: 1x={scale_1x_w}x{scale_1x_h}, 2x={scale_1x_w*2}x{scale_1x_h*2}, 3x={scale_1x_w*3}x{scale_1x_h*3}")

# 3. Gerar SVGs canônicos que contêm e preservam a imagem original exata em base64
with open(icon_path, "rb") as f:
    icon_b64 = base64.b64encode(f.read()).decode("utf-8")

with open(wordmark_trans_path, "rb") as f:
    wm_b64 = base64.b64encode(f.read()).decode("utf-8")

svg_icon_exact = f'''<svg viewBox="0 0 1024 1024" width="1024" height="1024" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" role="img" aria-labelledby="icon-title">
  <title id="icon-title">LagCheck App Icon — Dual-Node Vector</title>
  <image width="1024" height="1024" xlink:href="data:image/png;base64,{icon_b64}" />
</svg>
'''

svg_wm_exact = f'''<svg viewBox="0 0 {wm_w} {wm_h}" width="{wm_w}" height="{wm_h}" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" role="img" aria-labelledby="wm-title">
  <title id="wm-title">LagCheck Wordmark — Kinetic Speed Slant</title>
  <image width="{wm_w}" height="{wm_h}" xlink:href="data:image/png;base64,{wm_b64}" />
</svg>
'''

brand_dirs = [
    os.path.join(PROJECT_ROOT, "design-system/assets/brand"),
    os.path.join(PROJECT_ROOT, "web/assets/brand")
]

for d in brand_dirs:
    with open(os.path.join(d, "app-icon-source.svg"), "w") as f:
        f.write(svg_icon_exact)
    with open(os.path.join(d, "wordmark-primary.svg"), "w") as f:
        f.write(svg_wm_exact)
    print(f"Updated exact SVGs in {d}")

print("Exact asset deployment complete!")
