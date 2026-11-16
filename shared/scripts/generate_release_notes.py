#!/usr/bin/env python3
"""Gera notas de lançamento em linguagem comercial (diff entre versões) para lojas e GitHub.

Uso típico:
  python3 shared/scripts/generate_release_notes.py \
    --platform android \
    --channel github-apk \
    --version 1.3 \
    --build 9 \
    --ads-enabled true \
    --out-whatsnew-dir whatsnew \
    --out-github-md release-notes.md
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
import os
from pathlib import Path
import re
import subprocess
import sys
from typing import Iterable


PLAY_WHATSNEW_LIMIT = 500
APP_STORE_NOTES_LIMIT = 4000

NON_MOBILE_PREFIXES = (
    "docs/",
    ".agents/",
    ".codex/",
    ".github/",
    "apps/windows/",
    "apps/android/desktop/",
    "apps/android/engine-host/",
    "apps/worker/",
    "shared/distribution/marketing/",
)

IGNORED_COMMIT_SUBJECT_PREFIXES = (
    "docs:",
    "docs(",
    "ci:",
    "ci(",
    "winui:",
    "feat(winui",
    "fix(winui",
    "style(winui",
    "feat(windows",
    "fix(windows",
    "chore(windows",
)

FORBIDDEN_TERMS_RE = re.compile(
    r"\b(?:winui|kmp|swiftui|jetpack compose|proguard|gradle|buildconfig|"
    r"ads_enabled|admob|ump|request_install_packages|decis[aã]o\s+\d+|pr\s*#\d+)\b",
    re.IGNORECASE,
)


@dataclass(frozen=True)
class ThemeSpec:
    theme_id: str
    priority: int
    file_patterns: tuple[str, ...]
    keyword_patterns: tuple[str, ...]
    pt_br: str
    en_us: str
    es_es: str
    requires_ads_enabled: bool = False


THEMES: tuple[ThemeSpec, ...] = (
    ThemeSpec(
        theme_id="home_redesign",
        priority=10,
        file_patterns=("home", "hero"),
        keyword_patterns=("home", "hero", "populares", "favoritos", "edge-to-edge", "busca"),
        pt_br="Nova tela Início com arte em tela cheia, busca unificada e grade compacta de jogos populares.",
        en_us="Redesigned Home screen with full-bleed game artwork, unified search, and compact popular grid.",
        es_es="Nueva pantalla de Inicio con arte a pantalla completa, búsqueda unificada y cuadrícula compacta.",
    ),
    ThemeSpec(
        theme_id="games_catalog_ui",
        priority=20,
        file_patterns=("games", "catalog", "gamesview", "gamesscreen"),
        keyword_patterns=("jogos", "games", "3 colunas", "catálogo", "catalog"),
        pt_br="Aba Jogos em 3 colunas para encontrar títulos e iniciar sua medição mais rápido.",
        en_us="Games tab organized in a 3-column grid so you can find titles and test faster.",
        es_es="Pestaña Juegos en 3 columnas para encontrar tus títulos y probar tu conexión más rápido.",
    ),
    ThemeSpec(
        theme_id="history_stability",
        priority=30,
        file_patterns=("history", "stability"),
        keyword_patterns=("histórico", "history", "estabilidade", "curva", "anéis", "rings", "7/14/30"),
        pt_br="Histórico com gráfico de estabilidade de rede e comparativo claro em 7, 14 e 30 dias.",
        en_us="History updated with a network stability chart across 7, 14, and 30-day windows.",
        es_es="Historial mejorado con gráfico de estabilidad de red en ventanas de 7, 14 y 30 días.",
    ),
    ThemeSpec(
        theme_id="diagnostic_accuracy",
        priority=40,
        file_patterns=("core/domain", "core/network", "nolaggydomain", "readiness"),
        keyword_patterns=("perda", "jitter", "bufferbloat", "carga", "probe", "guardrail", "motor", "check"),
        pt_br="Medição de perda de pacotes, variação de latência e comportamento sob carga ainda mais precisa.",
        en_us="More accurate packet loss, jitter, and load-stress measurements before entering a match.",
        es_es="Medición más precisa de pérdida de paquetes, jitter y comportamiento bajo carga.",
    ),
    ThemeSpec(
        theme_id="route_map_and_status",
        priority=50,
        file_patterns=("routemap", "platformstatus", "status"),
        keyword_patterns=("mapa", "rota", "route", "api/status", "plataformas", "localização"),
        pt_br="Mapa de rota de medição e consulta ao vivo do status das plataformas atualizados.",
        en_us="Updated measurement route map and platform service status checks.",
        es_es="Mapa de ruta de medición y consulta del estado de plataformas actualizados.",
    ),
    ThemeSpec(
        theme_id="share_cards_video",
        priority=60,
        file_patterns=("share/", "sharemedia", "sharecanvas"),
        keyword_patterns=("compartilh", "share", "card", "vídeo", "video", "tiktok"),
        pt_br="Cartões e vídeos de compartilhamento refinados com os números observados na medição.",
        en_us="Refined share cards and clips showing the real numbers observed in your check.",
        es_es="Tarjetas y videos para compartir mejorados con los datos observados en tu prueba.",
    ),
    ThemeSpec(
        theme_id="in_app_update",
        priority=70,
        file_patterns=("update/", "updatedialog", "releasefeed"),
        keyword_patterns=("atualiz", "update", "apk"),
        pt_br="Aviso e fluxo de atualização do aplicativo mais simples e confiável.",
        en_us="Simpler and more reliable in-app update notifications and download flow.",
        es_es="Avisos y flujo de actualización dentro de la app más simples y confiables.",
    ),
    ThemeSpec(
        theme_id="ads_layout",
        priority=75,
        file_patterns=("ads/", "nativead", "adscontroller"),
        keyword_patterns=("anúncio", "anuncio", "nativead", "faixa"),
        pt_br="Espaço de anúncio mais compacto e discreto para priorizar a leitura dos resultados.",
        en_us="More compact, unobtrusive ad strip to keep connection results front and center.",
        es_es="Espacio de anuncio más compacto y discreto para priorizar la lectura de resultados.",
        requires_ads_enabled=True,
    ),
    ThemeSpec(
        theme_id="localization",
        priority=80,
        file_patterns=("values-", "localizable", "strings.xml"),
        keyword_patterns=("traduç", "idioma", "localiz", "en/es", "pt-br"),
        pt_br="Ajustes nas traduções e textos do aplicativo em português, inglês e espanhol.",
        en_us="Translation and copy refinements in English, Portuguese, and Spanish.",
        es_es="Ajustes de traducción y textos en español, portugués e inglés.",
    ),
    ThemeSpec(
        theme_id="ui_polish",
        priority=85,
        file_patterns=("designsystem", "nolaggydesign", "theme", "ui/"),
        keyword_patterns=("título", "caixa alta", "tipografia", "contraste", "acabamento", "visual"),
        pt_br="Acabamento visual aprimorado, títulos mais legíveis e navegação mais fluida.",
        en_us="Refined visual finish, clearer screen headers, and smoother navigation.",
        es_es="Mejor acabado visual, títulos más legibles y navegación más fluida.",
    ),
    ThemeSpec(
        theme_id="stability_fixes",
        priority=95,
        file_patterns=(),
        keyword_patterns=("fix:", "fix(", "hotfix", "crash", "corrig", "correção", "correções"),
        pt_br="Correções gerais de bugs e melhorias de estabilidade nos testes de conexão.",
        en_us="General bug fixes and stability improvements during connection checks.",
        es_es="Correcciones generales de errores y mejoras de estabilidad en las pruebas.",
    ),
)

FALLBACK_BULLETS = {
    "pt-BR": [
        "Melhorias de estabilidade, desempenho e clareza na leitura da sua conexão antes da partida.",
    ],
    "en-US": [
        "Stability, performance, and clarity improvements for your pre-match connection checks.",
    ],
    "es-ES": [
        "Mejoras de estabilidad, rendimiento y claridad al revisar tu conexión antes de jugar.",
    ],
}


@dataclass(frozen=True)
class CommitInfo:
    sha: str
    subject: str
    body: str
    files: tuple[str, ...]


def run_git(args: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=str(cwd),
        capture_output=True,
        text=True,
        check=False,
    )


def format_tag_label(tag: str) -> str:
    """Converte tag como 'android-v1.2-b8' em '1.2 (build 8)' para leitura humana."""
    match = re.match(
        r"^(?:android-v|ios-v|v)?(\d+\.\d+(?:\.\d+)?)(?:-b(\d+))?$",
        tag.strip(),
        re.IGNORECASE,
    )
    if not match:
        return tag.strip()
    version, build = match.group(1), match.group(2)
    return f"{version} (build {build})" if build else version


def find_previous_tag(
    cwd: Path,
    platform: str,
    exclude_tag: str | None = None,
) -> str | None:
    pattern = "android-v*" if platform == "android" else "ios-v*"
    res = run_git(["tag", "-l", pattern, "--sort=-creatordate"], cwd)
    tags = [t.strip() for t in res.stdout.splitlines() if t.strip()]
    if platform == "ios" and not tags:
        res = run_git(["tag", "-l", "v*", "--sort=-creatordate"], cwd)
        tags = [t.strip() for t in res.stdout.splitlines() if t.strip()]
    for tag in tags:
        if exclude_tag and tag == exclude_tag:
            continue
        return tag
    return None


def is_mobile_relevant_file(path: str, platform: str) -> bool:
    norm = path.strip().replace("\\", "/")
    if not norm:
        return False
    if any(norm.startswith(prefix) for prefix in NON_MOBILE_PREFIXES):
        return False
    if norm.endswith(".md"):
        return False
    if platform == "android":
        return (
            norm.startswith("apps/android/app/")
            or norm.startswith("apps/android/core/")
            or norm.startswith("shared/design-system/assets/brand/")
            or norm.startswith("shared/design-system/assets/games/")
        )
    if platform == "ios":
        return (
            norm.startswith("apps/ios/")
            or norm.startswith("apps/android/core/domain/")
            or norm.startswith("shared/design-system/assets/brand/")
            or norm.startswith("shared/design-system/assets/games/")
        )
    return True


def is_commit_relevant(commit: CommitInfo, platform: str) -> bool:
    subject_lower = commit.subject.strip().lower()
    mobile_files = [f for f in commit.files if is_mobile_relevant_file(f, platform)]
    if commit.files and not mobile_files:
        return False
    if not commit.files and any(subject_lower.startswith(p) for p in IGNORED_COMMIT_SUBJECT_PREFIXES):
        return False
    return True


def fetch_commits(cwd: Path, base_ref: str | None, head_ref: str) -> list[CommitInfo]:
    rev_range = f"{base_ref}..{head_ref}" if base_ref else head_ref
    limit_args = [] if base_ref else ["-n", "20"]
    res = run_git(
        ["log", *limit_args, "--no-merges", "--format=%H%x1f%s%x1f%b%x1e", rev_range],
        cwd,
    )
    if res.returncode != 0:
        return []
    commits: list[CommitInfo] = []
    for raw_record in res.stdout.split("\x1e"):
        record = raw_record.strip()
        if not record:
            continue
        parts = record.split("\x1f")
        sha = parts[0].strip()
        subject = parts[1].strip() if len(parts) > 1 else ""
        body = parts[2].strip() if len(parts) > 2 else ""
        files_res = run_git(
            ["diff-tree", "--no-commit-id", "--name-only", "-r", sha],
            cwd,
        )
        files = tuple(f.strip() for f in files_res.stdout.splitlines() if f.strip())
        commits.append(CommitInfo(sha=sha, subject=subject, body=body, files=files))
    return commits


def extract_custom_trailer_bullets(commit: CommitInfo) -> list[str]:
    """Extrai linhas comerciais explícitas se o commit tiver seção 'Novidades:' / 'Release-Notes:'."""
    bullets: list[str] = []
    capture = False
    for line in commit.body.splitlines():
        stripped = line.strip()
        if re.match(r"^(?:novidades|release-notes|comercial)\s*:\s*(.*)$", stripped, re.IGNORECASE):
            capture = True
            inline = re.sub(r"^(?:novidades|release-notes|comercial)\s*:\s*", "", stripped, flags=re.IGNORECASE).strip()
            if inline:
                bullets.append(inline.lstrip("-•* ").strip())
            continue
        if capture:
            if not stripped:
                capture = False
                continue
            bullets.append(stripped.lstrip("-•* ").strip())
    return [b for b in bullets if b and not FORBIDDEN_TERMS_RE.search(b)]


def sanitize_custom_notes(raw_notes: str) -> list[str]:
    bullets: list[str] = []
    for line in raw_notes.splitlines():
        clean = line.strip().lstrip("-•* ").strip()
        if clean:
            bullets.append(clean)
    return bullets


def classify_commits_to_bullets(
    commits: Iterable[CommitInfo],
    platform: str,
    ads_enabled: bool,
) -> tuple[dict[str, list[str]], list[str], list[str]]:
    relevant = [c for c in commits if is_commit_relevant(c, platform)]
    ignored = [c.subject for c in commits if c not in relevant]

    matched_themes: dict[str, ThemeSpec] = {}
    explicit_pt_bullets: list[str] = []

    for commit in relevant:
        explicit_pt_bullets.extend(extract_custom_trailer_bullets(commit))
        files_blob = " ".join(commit.files).lower()
        text_blob = f"{commit.subject}\n{commit.body}".lower()
        for theme in THEMES:
            if theme.requires_ads_enabled and not ads_enabled:
                continue
            file_hit = any(pat in files_blob for pat in theme.file_patterns)
            text_hit = any(pat in text_blob for pat in theme.keyword_patterns)
            if file_hit or text_hit:
                matched_themes[theme.theme_id] = theme

    ordered_themes = sorted(matched_themes.values(), key=lambda t: t.priority)

    pt_bullets = list(dict.fromkeys(explicit_pt_bullets + [t.pt_br for t in ordered_themes]))
    en_bullets = [t.en_us for t in ordered_themes]
    es_bullets = [t.es_es for t in ordered_themes]

    if not pt_bullets:
        pt_bullets = list(FALLBACK_BULLETS["pt-BR"])
    if not en_bullets:
        en_bullets = list(FALLBACK_BULLETS["en-US"])
    if not es_bullets:
        es_bullets = list(FALLBACK_BULLETS["es-ES"])

    return (
        {
            "pt-BR": pt_bullets,
            "en-US": en_bullets,
            "es-ES": es_bullets,
        },
        [c.subject for c in relevant],
        ignored,
    )


def fit_bullets_to_limit(
    header: str,
    bullets: list[str],
    max_chars: int,
    footer: str = "",
    max_utf8_bytes: int | None = None,
) -> str:
    """Monta texto de notas respeitando limite da loja sem cortar frases no meio."""
    clean_bullets = [f"- {b.lstrip('-•* ').strip()}" for b in bullets if b.strip()]
    prefix = f"{header.strip()}\n" if header.strip() else ""
    suffix = f"\n{footer.strip()}" if footer.strip() else ""

    def within_limits(text: str) -> bool:
        if len(text) > max_chars:
            return False
        if max_utf8_bytes is not None and len(text.encode("utf-8")) > max_utf8_bytes:
            return False
        return True

    selected: list[str] = []
    for bullet in clean_bullets:
        candidate_lines = prefix + "\n".join([*selected, bullet]) + suffix
        if within_limits(candidate_lines):
            selected.append(bullet)
        elif not selected:
            # Garante ao menos 1 item mesmo se o header for longo.
            available = max_chars - len(prefix) - len(suffix)
            if available > 10:
                candidate = bullet[: available - 3].rstrip() + "..."
                while max_utf8_bytes is not None and len((prefix + candidate + suffix).encode("utf-8")) > max_utf8_bytes and len(candidate) > 6:
                    candidate = candidate[:-4].rstrip() + "..."
                selected.append(candidate)
            break

    if not selected:
        base = (prefix + "\n".join(clean_bullets)).strip()
        return base[:max_chars].rstrip()

    result = prefix + "\n".join(selected) + suffix
    return result.rstrip()


def build_version_headers(version: str, previous_label: str | None) -> dict[str, str]:
    if previous_label:
        return {
            "pt-BR": f"Novidades da versão {version} (desde a {previous_label}):",
            "en-US": f"What's new in {version} (from {previous_label}):",
            "es-ES": f"Novedades de la versión {version} (desde la {previous_label}):",
        }
    return {
        "pt-BR": f"Novidades da versão {version}:",
        "en-US": f"What's new in {version}:",
        "es-ES": f"Novedades de la versión {version}:",
    }


def render_github_release_markdown(
    platform: str,
    channel: str,
    version: str,
    build: str | None,
    previous_label: str | None,
    bullets_by_lang: dict[str, list[str]],
    ads_enabled: bool,
    apk_name: str | None,
    apk_sha256: str | None,
) -> str:
    platform_label = "Android" if platform == "android" else "iOS"
    version_label = f"{version} (build {build})" if build else version
    ads_status_pt = "anúncios ativados" if ads_enabled else "anúncios desativados"

    lines: list[str] = []
    if channel == "github-apk":
        lines.append(
            f"APK assinado do LagCheck {version_label} para Android ({ads_status_pt}, canal `production`)."
        )
    else:
        lines.append(
            f"LagCheck {platform_label} {version_label} — canal `{channel}` ({ads_status_pt})."
        )

    lines.append("")
    if previous_label:
        lines.append(f"### Novidades desde a {previous_label}")
    else:
        lines.append(f"### Novidades da versão {version_label}")
    lines.extend(f"- {item}" for item in bullets_by_lang["pt-BR"])

    lines.append("")
    if previous_label:
        lines.append(f"### What's new since {previous_label}")
    else:
        lines.append(f"### What's new in {version_label}")
    lines.extend(f"- {item}" for item in bullets_by_lang["en-US"])

    if channel == "github-apk":
        lines.extend(
            [
                "",
                "### Instalação manual no Android",
                f"1. Baixe o arquivo `{apk_name or 'LagCheck-Android.apk'}` neste release.",
                "2. Abra o arquivo na pasta Downloads do aparelho.",
                "3. Se o Android pedir, autorize a instalação pelo navegador ou gerenciador de arquivos.",
                "4. Abra o LagCheck.",
                "",
                "Compatibilidade: Android 8 (API 26) ou superior.",
            ]
        )
        if apk_sha256:
            lines.append(f"SHA-256: `{apk_sha256}`")

    return "\n".join(lines).strip() + "\n"


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Gerador de diff comercial para lojas e GitHub Releases.")
    parser.add_argument("--platform", required=True, choices=("android", "ios"))
    parser.add_argument(
        "--channel",
        required=True,
        choices=("play-alpha", "play-internal", "play-beta", "play-production", "github-apk", "testflight", "app-store"),
    )
    parser.add_argument("--version", required=True, help="Versão de produto X.Y")
    parser.add_argument("--build", default="", help="Número de build inteiro")
    parser.add_argument("--base-ref", default="", help="Tag ou commit SHA da versão anterior")
    parser.add_argument("--head-ref", default="HEAD", help="Commit/tag alvo (padrão: HEAD)")
    parser.add_argument("--previous-version", default="", help="Rótulo legível da versão anterior")
    parser.add_argument("--custom-notes", default="", help="Notas comerciais manuais (opcional)")
    parser.add_argument("--ads-enabled", default="true", choices=("true", "false"))
    parser.add_argument("--apk-name", default="")
    parser.add_argument("--apk-sha256", default="")
    parser.add_argument("--out-whatsnew-dir", default="")
    parser.add_argument("--out-appstore-dir", default="")
    parser.add_argument("--out-github-md", default="")
    parser.add_argument("--json-summary", default="")
    parser.add_argument("--repo-root", default=".")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    repo_root = Path(args.repo_root).resolve()
    ads_enabled = args.ads_enabled == "true"
    build = args.build.strip() or None

    target_tag = (
        f"{args.platform}-v{args.version}-b{build}"
        if build
        else f"{args.platform}-v{args.version}"
    )

    base_ref = args.base_ref.strip() or find_previous_tag(repo_root, args.platform, exclude_tag=target_tag)
    previous_label = args.previous_version.strip() or (format_tag_label(base_ref) if base_ref else None)

    custom_bullets = sanitize_custom_notes(args.custom_notes)
    relevant_subjects: list[str] = []
    ignored_subjects: list[str] = []

    if custom_bullets:
        bullets_by_lang = {
            "pt-BR": custom_bullets,
            "en-US": custom_bullets,
            "es-ES": custom_bullets,
        }
    else:
        commits = fetch_commits(repo_root, base_ref, args.head_ref)
        bullets_by_lang, relevant_subjects, ignored_subjects = classify_commits_to_bullets(
            commits=commits,
            platform=args.platform,
            ads_enabled=ads_enabled,
        )

    headers = build_version_headers(args.version, previous_label)

    if args.out_whatsnew_dir:
        whatsnew_dir = Path(args.out_whatsnew_dir)
        whatsnew_dir.mkdir(parents=True, exist_ok=True)
        for lang in ("pt-BR", "en-US", "es-ES"):
            content = fit_bullets_to_limit(
                headers[lang],
                bullets_by_lang[lang],
                PLAY_WHATSNEW_LIMIT - 1,
                max_utf8_bytes=PLAY_WHATSNEW_LIMIT - 1,
            )
            (whatsnew_dir / f"whatsnew-{lang}").write_text(content + "\n", encoding="utf-8")

    if args.out_appstore_dir:
        appstore_dir = Path(args.out_appstore_dir)
        appstore_dir.mkdir(parents=True, exist_ok=True)
        appstore_footers = {
            "pt-BR": "Sem conta nem login. Antes de entrar na fila, faça um Check.",
            "en-US": "No account or sign-in needed. Run a Check before you queue.",
            "es-ES": "Sin cuenta ni registro. Antes de entrar a la cola, haz un Check.",
        }
        for lang in ("pt-BR", "en-US", "es-ES"):
            content = fit_bullets_to_limit(
                headers[lang],
                bullets_by_lang[lang],
                APP_STORE_NOTES_LIMIT - 1,
                footer=appstore_footers[lang],
            )
            (appstore_dir / f"release-notes-{lang}.txt").write_text(content + "\n", encoding="utf-8")

    github_md = render_github_release_markdown(
        platform=args.platform,
        channel=args.channel,
        version=args.version,
        build=build,
        previous_label=previous_label,
        bullets_by_lang=bullets_by_lang,
        ads_enabled=ads_enabled,
        apk_name=args.apk_name.strip() or None,
        apk_sha256=args.apk_sha256.strip() or None,
    )

    if args.out_github_md:
        out_md = Path(args.out_github_md)
        out_md.parent.mkdir(parents=True, exist_ok=True)
        out_md.write_text(github_md, encoding="utf-8")

    if args.json_summary:
        summary_path = Path(args.json_summary)
        summary_path.parent.mkdir(parents=True, exist_ok=True)
        payload = {
            "platform": args.platform,
            "channel": args.channel,
            "version": args.version,
            "build": build,
            "ads_enabled": ads_enabled,
            "base_ref": base_ref,
            "previous_label": previous_label,
            "relevant_commits_count": len(relevant_subjects),
            "ignored_commits_count": len(ignored_subjects),
            "bullets": bullets_by_lang,
        }
        summary_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    if not args.out_whatsnew_dir and not args.out_appstore_dir and not args.out_github_md:
        sys.stdout.write(github_md)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
