#!/usr/bin/env python3
"""Gera ícones e wordmark dos apps a partir da logo oficial (Decisão 123).

Fontes (não editar à mão, vêm do site):
  shared/design-system/assets/brand/lagcheck-mark.svg    símbolo "L + check" com órbita
  shared/design-system/assets/brand/wordmark-primary.svg wordmark "Lagcheck"

A composição do ícone só posiciona o símbolo oficial, sem redesenhá-lo, sobre o
mesmo fundo grafite do ícone anterior (gradiente #1E232B → #0B0D10 com brilho
Roxo Gamer embaixo). Requer `rsvg-convert` (librsvg).

Uso: python3 shared/scripts/generate-brand-icons.py
"""
from __future__ import annotations

import re
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BRAND = ROOT / "shared/design-system/assets/brand"
MARK_SVG = BRAND / "lagcheck-mark.svg"
WORDMARK_SVG = BRAND / "wordmark-primary.svg"

IOS_APP_ICONS = [
    ROOT / "apps/ios/Sources/NolaggyApp/Assets.xcassets/AppIcon.appiconset",
    ROOT / "apps/ios/Sources/LagCheckClip/Assets.xcassets/AppIcon.appiconset",
]
IOS_WORDMARK = ROOT / "apps/ios/Sources/NolaggyApp/Assets.xcassets/WordmarkPrimary.imageset"
IOS_BRAND_PNG = ROOT / "apps/ios/Sources/NolaggyApp/Resources/Brand/nolaggy-wordmark-primary.png"
ANDROID_RES = ROOT / "apps/android/app/src/main/res"
DS_APP_ICON = ROOT / "shared/design-system/assets/app-icon"
STORE = ROOT / "shared/distribution/store"

BACKGROUND_DEFS = (
    '<radialGradient id="bg" cx="50%" cy="34%" r="80%">'
    '<stop offset="0" stop-color="#1E232B"/><stop offset=".55" stop-color="#15181E"/>'
    '<stop offset="1" stop-color="#0B0D10"/></radialGradient>'
    '<radialGradient id="glow" gradientUnits="objectBoundingBox" cx=".5" cy="1.0" r=".72" fx=".5" fy="1.0">'
    '<stop offset="0" stop-color="#7C3AED" stop-opacity="0.44"/>'
    '<stop offset=".55" stop-color="#7C3AED" stop-opacity="0.132"/>'
    '<stop offset="1" stop-color="#7C3AED" stop-opacity="0"/></radialGradient>'
)
WHITE_MATRIX = "0 0 0 0 1  0 0 0 0 1  0 0 0 0 1  0 0 0 1 0"
GRAY_MATRIX = ".3 .59 .11 0 0  .3 .59 .11 0 0  .3 .59 .11 0 0  0 0 0 1 0"


def mark_body() -> tuple[str, str]:
    """Conteúdo interno do símbolo oficial e seu viewBox, sem título/descrição."""
    text = MARK_SVG.read_text(encoding="utf-8")
    view_box = re.search(r'viewBox="([^"]+)"', text).group(1)
    inner = re.search(r"<svg[^>]*>(.*)</svg>", text, re.S).group(1)
    inner = re.sub(r"<title[^>]*>.*?</title>|<desc[^>]*>.*?</desc>", "", inner, flags=re.S)
    return inner, view_box


def mark(size: int, width_ratio: float, filter_matrix: str | None = None) -> str:
    """Símbolo centralizado num quadrado `size`, ocupando `width_ratio` da largura."""
    inner, view_box = mark_body()
    _, _, vb_w, vb_h = (float(v) for v in view_box.split())
    width = size * width_ratio
    height = width * vb_h / vb_w
    x = (size - width) / 2
    y = (size - height) / 2
    attrs = ""
    defs = ""
    if filter_matrix:
        defs = (f'<filter id="tint" color-interpolation-filters="sRGB">'
                f'<feColorMatrix type="matrix" values="{filter_matrix}"/></filter>')
        attrs = ' filter="url(#tint)"'
    return (f"<defs>{defs}</defs><g{attrs}><svg x=\"{x:.2f}\" y=\"{y:.2f}\" width=\"{width:.2f}\" "
            f"height=\"{height:.2f}\" viewBox=\"{view_box}\">{inner}</svg></g>")


def svg(size: int, body: str, extra_defs: str = "") -> str:
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {size} {size}" width="{size}" height="{size}">'
            f"<defs>{extra_defs}</defs>{body}</svg>")


def full_icon(size: int = 1024, glow: bool = True, ratio: float = 0.74) -> str:
    background = f'<rect width="{size}" height="{size}" fill="url(#bg)"/>'
    if glow:
        background += f'<rect width="{size}" height="{size}" fill="url(#glow)"/>'
    return svg(size, background + mark(size, ratio), BACKGROUND_DEFS)


def tinted_icon(size: int = 1024) -> str:
    return svg(size, f'<rect width="{size}" height="{size}" fill="#000"/>' + mark(size, 0.74, GRAY_MATRIX))


def render(svg_text: str, out: Path, size: int, *, width: int | None = None, height: int | None = None) -> None:
    out.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile("w", suffix=".svg", delete=False, encoding="utf-8") as handle:
        handle.write(svg_text)
        source = handle.name
    args = ["rsvg-convert", "-w", str(width or size), "-h", str(height or size), source, "-o", str(out)]
    subprocess.run(args, check=True)
    Path(source).unlink()


def flatten(path: Path) -> None:
    """App Store e iOS exigem PNG sem canal alfa (remoção sem perda)."""
    from PIL import Image

    with Image.open(path) as image:
        opaque = Image.new("RGB", image.size, (11, 13, 16))
        opaque.paste(image, mask=image.convert("RGBA").split()[3])
        opaque.save(path, optimize=True)


def ios_icons() -> None:
    for folder in IOS_APP_ICONS:
        for png in sorted(folder.glob("appicon-*.png")) + sorted(folder.glob("icon-thumbnail-*.png")):
            name = png.name
            if name == "appicon-1024-tinted.png":
                render(tinted_icon(), png, 1024)
            elif name == "appicon-1024-dark.png":
                render(full_icon(glow=False), png, 1024)
            else:
                size = int(re.search(r"(\d+)", name.replace("1024-", "1024")).group(1))
                render(full_icon(), png, size)
            flatten(png)


def ios_wordmark() -> None:
    text = WORDMARK_SVG.read_text(encoding="utf-8")
    vb = [float(v) for v in re.search(r'viewBox="([^"]+)"', text).group(1).split()]
    for scale, name in [(1, "wordmark-primary.png"), (2, "wordmark-primary@2x.png"), (3, "wordmark-primary@3x.png")]:
        height = 40 * scale
        width = round(height * vb[2] / vb[3])
        render(text, IOS_WORDMARK / name, 0, width=width, height=height)
    shutil.copy(IOS_WORDMARK / "wordmark-primary@3x.png", IOS_BRAND_PNG)


ANDROID_DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}


def android_icons() -> None:
    # Camada adaptativa: 108 dp. O símbolo cabe no círculo seguro de 66 dp.
    for density, factor in ANDROID_DENSITIES.items():
        folder = ANDROID_RES / f"mipmap-{density}"
        layer = round(108 * factor)
        legacy = round(48 * factor)
        background = svg(108, '<rect width="108" height="108" fill="url(#bg)"/><rect width="108" height="108" fill="url(#glow)"/>',
                         BACKGROUND_DEFS)
        render(background, folder / "ic_launcher_background.png", layer)
        render(svg(108, mark(108, 0.56)), folder / "ic_launcher_foreground.png", layer)
        render(svg(108, mark(108, 0.56, WHITE_MATRIX)), folder / "ic_launcher_monochrome.png", layer)
        render(full_icon(1024, ratio=0.74), folder / "ic_launcher.png", legacy)
        round_icon = full_icon(1024, ratio=0.70).replace(
            "<defs>", '<defs><clipPath id="round"><circle cx="512" cy="512" r="512"/></clipPath>', 1
        ).replace('<rect width="1024"', '<rect clip-path="url(#round)" width="1024"')
        render(round_icon, folder / "ic_launcher_round.png", legacy)


def android_wordmark() -> None:
    text = WORDMARK_SVG.read_text(encoding="utf-8")
    vb = [float(v) for v in re.search(r'viewBox="([^"]+)"', text).group(1).split()]
    for density, factor in {"mdpi": 1, "xhdpi": 2, "xxhdpi": 3}.items():
        height = round(40 * factor)
        render(text, ANDROID_RES / f"drawable-{density}/wordmark_primary.png", 0,
               width=round(height * vb[2] / vb[3]), height=height)
    # Usado nos cards de compartilhamento (precisa de resolução maior).
    render(text, ANDROID_RES / "drawable/lagcheck_wordmark_official.png", 0,
           width=1240, height=round(1240 * vb[3] / vb[2]))


def shared_assets() -> None:
    (BRAND / "app-icon-source.svg").write_text(full_icon(), encoding="utf-8")
    (BRAND / "app-icon-foreground-only.svg").write_text(svg(1024, mark(1024, 0.74)), encoding="utf-8")
    for png in DS_APP_ICON.glob("*.png"):
        name = png.name
        if "tinted" in name:
            render(tinted_icon(), png, 1024)
        elif "dark" in name:
            render(full_icon(glow=False), png, 1024)
        else:
            match = re.search(r"(\d+(?:\.\d+)?)(?:@(\d)x)?", name.replace("1024-", "1024"))
            base, scale = float(match.group(1)), int(match.group(2) or 1)
            render(full_icon(), png, round(base * scale))
        flatten(png)
    # Ícones de loja: App Store 1024 (sem alfa) e Google Play 512.
    render(full_icon(), STORE / "app-store/icon-1024.png", 1024)
    flatten(STORE / "app-store/icon-1024.png")
    render(full_icon(), STORE / "google-play/icon-512.png", 512)


if __name__ == "__main__":
    ios_icons()
    ios_wordmark()
    android_icons()
    android_wordmark()
    shared_assets()
    print("ok")
