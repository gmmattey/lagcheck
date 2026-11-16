#!/usr/bin/env python3
"""Testes unitários para o gerador de notas comerciais de lançamento."""

from __future__ import annotations

from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import generate_release_notes as grn  # noqa: E402


class GenerateReleaseNotesTests(unittest.TestCase):
    def test_ignores_windows_docs_and_ci_commits_for_mobile(self) -> None:
        commits = [
            grn.CommitInfo(
                sha="111",
                subject="winui: integra dados extras das lojas",
                body="",
                files=("apps/windows/LagCheck.WinUI/MainPage.xaml.cs",),
            ),
            grn.CommitInfo(
                sha="222",
                subject="docs(design): alinhar DESIGN.md compartilhado",
                body="",
                files=("shared/design-system/DESIGN.md", "docs/DECISOES.md"),
            ),
            grn.CommitInfo(
                sha="333",
                subject="ci(android): ajustar workflow",
                body="",
                files=(".github/workflows/android-play-alpha.yml",),
            ),
            grn.CommitInfo(
                sha="444",
                subject="feat(ui): redesign HomeScreen e GamesScreen",
                body="",
                files=(
                    "apps/android/app/src/main/kotlin/com/lagcheck/android/ui/HomeScreen.kt",
                    "apps/android/app/src/main/kotlin/com/lagcheck/android/ui/GamesScreen.kt",
                ),
            ),
        ]

        bullets, relevant, ignored = grn.classify_commits_to_bullets(
            commits=commits,
            platform="android",
            ads_enabled=False,
        )

        self.assertEqual(relevant, ["feat(ui): redesign HomeScreen e GamesScreen"])
        self.assertEqual(len(ignored), 3)
        joined = "\n".join(bullets["pt-BR"])
        self.assertIn("Nova tela Início", joined)
        self.assertIn("Aba Jogos em 3 colunas", joined)
        self.assertIsNone(grn.FORBIDDEN_TERMS_RE.search(joined))
        self.assertNotIn("winui", joined.lower())
        self.assertNotIn("admob", joined.lower())

    def test_ads_theme_hidden_when_ads_disabled(self) -> None:
        commits = [
            grn.CommitInfo(
                sha="555",
                subject="feat(ads): faixa compacta no NativeAdSlot",
                body="",
                files=("apps/android/app/src/main/kotlin/com/lagcheck/android/ads/NativeAdCard.kt",),
            )
        ]

        alpha_bullets, _, _ = grn.classify_commits_to_bullets(
            commits=commits,
            platform="android",
            ads_enabled=False,
        )
        apk_bullets, _, _ = grn.classify_commits_to_bullets(
            commits=commits,
            platform="android",
            ads_enabled=True,
        )

        self.assertNotIn("anúncio", "\n".join(alpha_bullets["pt-BR"]).lower())
        self.assertIn("anúncio", "\n".join(apk_bullets["pt-BR"]).lower())

    def test_ios_includes_kmp_domain_but_ignores_android_ui(self) -> None:
        commits = [
            grn.CommitInfo(
                sha="666",
                subject="fix(android): corrige padding na Home",
                body="",
                files=("apps/android/app/src/main/kotlin/com/lagcheck/android/ui/HomeScreen.kt",),
            ),
            grn.CommitInfo(
                sha="777",
                subject="fix(motor): calibra perda de pacotes no KMP",
                body="",
                files=("apps/android/core/domain/src/commonMain/kotlin/Readiness.kt",),
            ),
        ]

        bullets, relevant, ignored = grn.classify_commits_to_bullets(
            commits=commits,
            platform="ios",
            ads_enabled=True,
        )

        self.assertEqual(relevant, ["fix(motor): calibra perda de pacotes no KMP"])
        self.assertEqual(len(ignored), 1)
        self.assertIn("perda de pacotes", "\n".join(bullets["pt-BR"]).lower())

    def test_play_whatsnew_respects_500_char_limit(self) -> None:
        bullets = [f"Melhoria comercial número {i} com texto suficientemente longo para testar o teto." for i in range(15)]
        text = grn.fit_bullets_to_limit("Novidades da versão 1.3 (desde a 1.2 (build 8)):", bullets, 499)
        self.assertLessEqual(len(text + "\n"), 500)
        self.assertTrue(text.startswith("Novidades da versão 1.3"))

    def test_cli_generates_whatsnew_appstore_and_github_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            whatsnew_dir = tmp_path / "whatsnew"
            appstore_dir = tmp_path / "appstore"
            github_md = tmp_path / "release.md"
            summary_json = tmp_path / "summary.json"

            code = grn.main(
                [
                    "--platform",
                    "android",
                    "--channel",
                    "github-apk",
                    "--version",
                    "1.3",
                    "--build",
                    "9",
                    "--base-ref",
                    "android-v1.2-b8",
                    "--ads-enabled",
                    "true",
                    "--apk-name",
                    "LagCheck-Android-1.3-b9-production.apk",
                    "--apk-sha256",
                    "deadbeef",
                    "--out-whatsnew-dir",
                    str(whatsnew_dir),
                    "--out-appstore-dir",
                    str(appstore_dir),
                    "--out-github-md",
                    str(github_md),
                    "--json-summary",
                    str(summary_json),
                    "--repo-root",
                    str(Path(__file__).resolve().parents[3]),
                ]
            )
            self.assertEqual(code, 0)
            for lang in ("pt-BR", "en-US", "es-ES"):
                wn = (whatsnew_dir / f"whatsnew-{lang}").read_text(encoding="utf-8")
                self.assertLessEqual(len(wn), 500)
                self.assertLessEqual(len(wn.encode("utf-8")), 500)
                self.assertIn("1.3", wn)
                appstore_txt = (appstore_dir / f"release-notes-{lang}.txt").read_text(encoding="utf-8")
                self.assertLessEqual(len(appstore_txt), 4000)

            md = github_md.read_text(encoding="utf-8")
            self.assertIn("LagCheck-Android-1.3-b9-production.apk", md)
            self.assertIn("deadbeef", md)
            self.assertIn("1.2 (build 8)", md)
            self.assertNotIn("winui", md.lower())


if __name__ == "__main__":
    unittest.main()
