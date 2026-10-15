#!/usr/bin/env python3
"""Local PNG composer, validator and gallery generator for Nico creative manifests."""

from __future__ import annotations

import argparse
import html
import json
import math
import os
import sys
from datetime import date
from pathlib import Path
from typing import Any

try:
    from PIL import Image, ImageDraw, ImageFilter, ImageFont
except ImportError as error:  # pragma: no cover - environment diagnostic
    raise SystemExit("Pillow is required. Use an approved local Python environment with Pillow installed.") from error


PROFILES: dict[str, dict[str, Any]] = {
    "appstore-iphone-6.3-portrait": {"size": (1206, 2622), "store": "app-store", "orientation": "portrait", "source_platform": "ios"},
    "appstore-iphone-6.9-portrait": {"size": (1290, 2796), "store": "app-store", "orientation": "portrait", "source_platform": "ios"},
    "appstore-product-page-header": {"size": (3840, 1646), "store": "app-store", "orientation": "landscape", "source_platform": "ios"},
    "google-play-phone-portrait": {"size": (1080, 1920), "store": "google-play", "orientation": "portrait", "source_platform": "android"},
    "google-play-feature-graphic": {"size": (1024, 500), "store": "google-play", "orientation": "landscape", "source_platform": "android"},
}
EVIDENCE_TYPES = {"simulator_capture", "emulator_capture", "manual_input"}
STYLE_PALETTES = {
    "minimal-premium": ("#0B0D10", (110, 88, 150, 70)),
    "technology-connectivity": ("#09121A", (35, 145, 185, 75)),
    "gamer": ("#0B0D10", (124, 58, 237, 115)),
    "productivity": ("#101318", (86, 106, 135, 70)),
    "lifestyle": ("#17120F", (174, 102, 72, 70)),
    "corporate": ("#0D1724", (41, 101, 170, 65)),
    "editorial": ("#151117", (133, 79, 156, 65)),
}
FONT_BOLD = ["/System/Library/Fonts/Supplemental/Arial Bold.ttf", "/System/Library/Fonts/Supplemental/Arial.ttf"]
FONT_REGULAR = ["/System/Library/Fonts/Supplemental/Arial.ttf", "/System/Library/Fonts/Supplemental/Helvetica.ttf"]


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    candidates = FONT_BOLD if bold else FONT_REGULAR
    for candidate in candidates:
        if Path(candidate).exists():
            return ImageFont.truetype(candidate, size=size)
    return ImageFont.load_default()


def resolve_input(value: str, base: Path) -> Path:
    candidate = Path(value)
    if candidate.is_absolute():
        return candidate
    local = base / candidate
    return local if local.exists() else Path.cwd() / candidate


def resolve_output(value: str, base: Path) -> Path:
    candidate = Path(value)
    return candidate if candidate.is_absolute() else base / candidate


def load_manifest(path: Path) -> tuple[dict[str, Any], Path]:
    try:
        manifest = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError(f"invalid manifest: {error}") from error
    if not isinstance(manifest, dict):
        raise ValueError("manifest must be a JSON object")
    return manifest, path.parent.resolve()


def image_details(path: Path) -> dict[str, Any]:
    with Image.open(path) as image:
        width, height = image.size
        bands = image.getbands()
        return {"path": str(path), "format": image.format, "width": width, "height": height, "has_alpha": "A" in bands}


def validate_image(path: Path, profile_name: str) -> dict[str, Any]:
    if profile_name not in PROFILES:
        return {"valid": False, "errors": [f"unknown profile: {profile_name}"], "warnings": []}
    if not path.exists():
        return {"valid": False, "errors": [f"missing image: {path}"], "warnings": []}
    profile = PROFILES[profile_name]
    details = image_details(path)
    errors: list[str] = []
    if details["format"] not in {"PNG", "JPEG"}:
        errors.append("format must be PNG or JPEG")
    if details["has_alpha"]:
        errors.append("image must not contain alpha")
    width, height = details["width"], details["height"]
    expected = profile["size"]
    if profile_name == "google-play-phone-portrait":
        if not (320 <= width <= 3840 and 320 <= height <= 3840):
            errors.append("Google Play screenshot dimensions must be between 320 and 3840 pixels")
        if max(width, height) > min(width, height) * 2:
            errors.append("Google Play screenshot longest side cannot exceed twice the shortest")
    elif (width, height) != expected:
        errors.append(f"expected {expected[0]}x{expected[1]}, got {width}x{height}")
    return {"valid": not errors, "profile": profile_name, "details": details, "errors": errors, "warnings": []}


def validate_manifest(manifest: dict[str, Any], base: Path, require_outputs: bool = False) -> dict[str, Any]:
    errors: list[str] = []
    warnings: list[str] = []
    profile_name = manifest.get("profile")
    if profile_name not in PROFILES:
        errors.append("profile must name a supported Nico profile")
        return {"valid": False, "errors": errors, "warnings": warnings, "screens": []}
    if manifest.get("store") != PROFILES[profile_name]["store"]:
        errors.append("store does not match profile")
    brand = manifest.get("brand")
    if not isinstance(brand, dict) or brand.get("style") not in STYLE_PALETTES:
        errors.append("brand.style must select a supported art direction")
    screens = manifest.get("screens")
    if not isinstance(screens, list) or not screens:
        errors.append("screens must contain at least one creative")
        return {"valid": False, "errors": errors, "warnings": warnings, "screens": []}
    if len(screens) > 10 and manifest.get("store") == "app-store":
        errors.append("Apple screenshot set cannot contain more than 10 images")
    results = []
    for index, screen in enumerate(screens, start=1):
        if not isinstance(screen, dict):
            errors.append(f"screen {index} must be an object")
            continue
        missing = [field for field in ("source", "source_platform", "source_evidence", "output", "headline", "objective", "feature", "variant", "hypothesis") if not screen.get(field)]
        if missing:
            errors.append(f"screen {index} missing: {', '.join(missing)}")
            continue
        source = resolve_input(str(screen["source"]), base)
        if not source.exists():
            errors.append(f"screen {index} source missing: {source}")
        if screen["source_evidence"] not in EVIDENCE_TYPES:
            errors.append(f"screen {index} has unsupported source_evidence")
        expected_platform = PROFILES[profile_name]["source_platform"]
        if screen["source_platform"] != expected_platform:
            errors.append(
                f"screen {index} source_platform {screen['source_platform']!r} is incompatible with "
                f"{profile_name}; this profile requires a {expected_platform} capture"
            )
        if not str(screen["output"]).lower().endswith(".png"):
            errors.append(f"screen {index} output must be PNG")
        result = {
            "order": screen.get("order", index),
            "source": str(source),
            "source_platform": screen["source_platform"],
            "output": str(resolve_output(str(screen["output"]), base)),
            "source_evidence": screen["source_evidence"],
        }
        if screen["source_evidence"] == "manual_input":
            result["status"] = "requires_product_fidelity_confirmation"
            warnings.append(f"screen {index} uses manual input; verify it matches the current app before publication")
        else:
            result["status"] = "captured_controlled_scenario"
        if require_outputs:
            output_validation = validate_image(Path(result["output"]), profile_name)
            result["output_validation"] = output_validation
            if not output_validation["valid"]:
                errors.extend(f"screen {index}: {message}" for message in output_validation["errors"])
        results.append(result)
    return {"valid": not errors, "profile": profile_name, "errors": errors, "warnings": warnings, "screens": results}


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, *size), radius=radius, fill=255)
    return mask


def fit(image: Image.Image, box: tuple[int, int]) -> Image.Image:
    scale = min(box[0] / image.width, box[1] / image.height)
    return image.resize((max(1, round(image.width * scale)), max(1, round(image.height * scale))), Image.Resampling.LANCZOS)


def draw_wrapped(draw: ImageDraw.ImageDraw, text: str, xy: tuple[int, int], max_width: int, text_font: ImageFont.FreeTypeFont, fill: str, spacing: int = 6) -> int:
    words = text.replace("\n", " \n ").split()
    lines: list[str] = []
    line = ""
    for word in words:
        if word == "\\n":
            if line:
                lines.append(line)
                line = ""
            continue
        candidate = word if not line else f"{line} {word}"
        if draw.textbbox((0, 0), candidate, font=text_font)[2] <= max_width:
            line = candidate
        else:
            if line:
                lines.append(line)
            line = word
    if line:
        lines.append(line)
    y = xy[1]
    for line in lines:
        draw.text((xy[0], y), line, font=text_font, fill=fill)
        box = draw.textbbox((xy[0], y), line, font=text_font)
        y = box[3] + spacing
    return y


def decorative_background(size: tuple[int, int], variant: str, style: str) -> Image.Image:
    width, height = size
    base, glow_color = STYLE_PALETTES[style]
    background = Image.new("RGB", size, base)
    glow = Image.new("RGBA", size, (0, 0, 0, 0))
    painter = ImageDraw.Draw(glow)
    violet = glow_color if variant != "problem" else (255, 90, 54, 95)
    painter.ellipse((-width // 2, -height // 5, width * 3 // 4, height * 3 // 5), fill=violet)
    painter.ellipse((width // 2, height * 2 // 3, width * 3 // 2, height * 5 // 4), fill=(124, 58, 237, 65))
    glow = glow.filter(ImageFilter.GaussianBlur(max(width, height) // 12))
    background = Image.alpha_composite(background.convert("RGBA"), glow)
    lines = Image.new("RGBA", size, (0, 0, 0, 0))
    line_draw = ImageDraw.Draw(lines)
    for offset in range(-height, width, max(180, width // 7)):
        line_draw.line((offset, 0, offset + height, height), fill=(255, 255, 255, 13), width=max(2, width // 450))
    return Image.alpha_composite(background, lines).convert("RGB")


def paste_wordmark(canvas: Image.Image, path: Path, x: int, y: int, max_width: int) -> None:
    if not path.exists():
        return
    with Image.open(path) as raw:
        logo = raw.convert("RGBA")
    logo = fit(logo, (max_width, max_width // 3))
    canvas.alpha_composite(logo, (x, y))


def compose_screen(manifest: dict[str, Any], screen: dict[str, Any], base: Path) -> Path:
    profile = PROFILES[manifest["profile"]]
    width, height = profile["size"]
    variant = str(screen.get("variant", "benefit"))
    brand = manifest.get("brand", {}) if isinstance(manifest.get("brand"), dict) else {}
    canvas = decorative_background((width, height), variant, str(brand.get("style", "minimal-premium"))).convert("RGBA")
    draw = ImageDraw.Draw(canvas)
    horizontal = profile["orientation"] == "landscape"
    margin = round(width * 0.075)
    wordmark = brand.get("wordmark")
    if wordmark:
        paste_wordmark(canvas, resolve_input(str(wordmark), base), margin, round(height * 0.045), round(width * (0.30 if horizontal else 0.36)))
    else:
        draw.text((margin, round(height * 0.05)), str(manifest.get("product", "")), font=font(round(width * .045), True), fill="#F4F5F7")

    headline_size = round(width * (0.065 if horizontal else 0.075))
    support_size = round(width * (0.028 if horizontal else 0.034))
    if horizontal:
        text_x, text_y = margin, round(height * .27)
        text_width = round(width * .42)
        source_box = (round(width * .44), round(height * .14), round(width * .49), round(height * .76))
    else:
        text_x, text_y = margin, round(height * .17)
        text_width = width - margin * 2
        source_box = (round(width * .105), round(height * .38), round(width * .79), round(height * .53))
    after_headline = draw_wrapped(draw, str(screen["headline"]).upper(), (text_x, text_y), text_width, font(headline_size, True), "#F4F5F7", round(headline_size * .20))
    supporting = str(screen.get("supporting_copy", ""))
    if supporting:
        draw_wrapped(draw, supporting, (text_x, after_headline + round(height * .014)), text_width, font(support_size), "#B9C0CC", round(support_size * .35))

    source_path = resolve_input(str(screen["source"]), base)
    with Image.open(source_path) as opened:
        source = opened.convert("RGB")
    placed = fit(source, (source_box[2], source_box[3]))
    frame_x = source_box[0] + (source_box[2] - placed.width) // 2
    frame_y = source_box[1] + (source_box[3] - placed.height) // 2
    radius = max(28, round(width * .04))
    shadow = Image.new("RGBA", (placed.width + 36, placed.height + 44), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle((18, 18, placed.width + 16, placed.height + 20), radius=radius, fill=(0, 0, 0, 180))
    shadow = shadow.filter(ImageFilter.GaussianBlur(14))
    canvas.alpha_composite(shadow, (frame_x - 18, frame_y - 18))
    clipped = Image.new("RGBA", placed.size, (0, 0, 0, 0))
    clipped.paste(placed, (0, 0))
    clipped.putalpha(rounded_mask(placed.size, radius))
    canvas.alpha_composite(clipped, (frame_x, frame_y))
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle((frame_x, frame_y, frame_x + placed.width, frame_y + placed.height), radius=radius, outline="#5B21B6", width=max(2, width // 450))

    footer_y = round(height * .91) if not horizontal else round(height * .84)
    draw.text((margin, footer_y), str(manifest.get("product", "")), font=font(round(width * .023), True), fill="#B9C0CC")
    evidence = str(screen.get("source_evidence", ""))
    label = "CAPTURA CONTROLADA" if evidence in {"simulator_capture", "emulator_capture"} else "CAPTURA FORNECIDA · REVISAR FIDELIDADE"
    label_width = draw.textbbox((0, 0), label, font=font(round(width * .019), True))[2]
    draw.text((width - margin - label_width, footer_y), label, font=font(round(width * .019), True), fill="#8A93A0")

    output = resolve_output(str(screen["output"]), base)
    output.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(output, "PNG", optimize=True)
    return output


def render(manifest_path: Path) -> int:
    manifest, base = load_manifest(manifest_path)
    checked = validate_manifest(manifest, base)
    if not checked["valid"]:
        print(json.dumps(checked, ensure_ascii=False, indent=2))
        return 1
    exports = []
    for screen in manifest["screens"]:
        output = compose_screen(manifest, screen, base)
        exports.append(validate_image(output, manifest["profile"]))
    report = validate_manifest(manifest, base, require_outputs=True)
    report.update({"generated_on": date.today().isoformat(), "exports": exports, "state": "ready_for_review" if report["valid"] else "invalid"})
    report_path = base / "reports" / f"{manifest_path.stem}-creative-report.json"
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"valid": report["valid"], "report": str(report_path), "exports": [item["details"]["path"] for item in exports]}, ensure_ascii=False, indent=2))
    return 0 if report["valid"] else 1


def gallery(manifest_path: Path, output: Path) -> int:
    manifest, base = load_manifest(manifest_path)
    report = validate_manifest(manifest, base, require_outputs=True)
    cards = []
    for screen, result in zip(manifest.get("screens", []), report.get("screens", [])):
        final = Path(result["output"])
        relative = os.path.relpath(final, output.parent)
        status = result.get("status", "unknown").replace("_", " ")
        cards.append(f"""<article><img src=\"{html.escape(relative)}\" alt=\"{html.escape(str(screen.get('headline', 'Creative')))}\"><div class=\"meta\"><b>{html.escape(str(manifest.get('product', '')))}</b><span>{html.escape(str(manifest.get('store', '')))} · {html.escape(str(manifest.get('locale', '')))} · #{html.escape(str(screen.get('order', '')))}</span><span>Fonte: {html.escape(str(result.get('source_platform', '')))} · {html.escape(str(result.get('source_evidence', '')))}</span><span>Variante: {html.escape(str(screen.get('variant', '')))}</span><span>Estado: {html.escape(status)}</span><p>{html.escape(str(screen.get('hypothesis', '')))}</p></div></article>""")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(f"""<!doctype html><html lang=\"pt-BR\"><meta charset=\"utf-8\"><title>Nico — revisão criativa</title><style>body{{margin:0;background:#0B0D10;color:#F4F5F7;font-family:-apple-system,sans-serif}}header{{padding:36px 5vw;border-bottom:1px solid #2c3038}}h1{{margin:0}}main{{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:24px;padding:32px 5vw}}article{{background:#15181E;border:1px solid #2c3038;border-radius:16px;overflow:hidden}}img{{width:100%;display:block;background:#0B0D10}}.meta{{padding:16px;display:grid;gap:7px;color:#B9C0CC}}.meta b{{color:#F4F5F7}}p{{margin:8px 0 0}}</style><header><h1>Nico · revisão antes de publicação</h1><p>{html.escape(str(manifest.get('product', '')))} · {html.escape(str(manifest.get('store', '')))} · {html.escape(str(manifest.get('profile', '')))}</p></header><main>{''.join(cards)}</main></html>""", encoding="utf-8")
    print(json.dumps({"gallery": str(output), "valid_outputs": report["valid"], "state": "local_preview_only"}, ensure_ascii=False, indent=2))
    return 0 if report["valid"] else 1


def main() -> int:
    parser = argparse.ArgumentParser(description="Nico local creative studio; it never uploads to stores.")
    commands = parser.add_subparsers(dest="command", required=True)
    for name in ("render", "validate-manifest"):
        command = commands.add_parser(name)
        command.add_argument("--manifest", required=True)
    image_command = commands.add_parser("validate-image")
    image_command.add_argument("--profile", required=True)
    image_command.add_argument("--image", required=True)
    gallery_command = commands.add_parser("gallery")
    gallery_command.add_argument("--manifest", required=True)
    gallery_command.add_argument("--output", required=True)
    args = parser.parse_args()
    if args.command == "render":
        return render(Path(args.manifest).resolve())
    if args.command == "validate-manifest":
        manifest, base = load_manifest(Path(args.manifest).resolve())
        result = validate_manifest(manifest, base, require_outputs=True)
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0 if result["valid"] else 1
    if args.command == "validate-image":
        result = validate_image(Path(args.image).resolve(), args.profile)
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0 if result["valid"] else 1
    return gallery(Path(args.manifest).resolve(), Path(args.output).resolve())


if __name__ == "__main__":
    sys.exit(main())
