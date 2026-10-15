import json
import subprocess
import tempfile
import unittest
from pathlib import Path

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / ".agents" / "skills" / "store-creative-studio" / "scripts" / "nico_creative.py"


class NicoCreativeTests(unittest.TestCase):
    def make_manifest(self, directory: Path) -> Path:
        source = directory / "source.png"
        Image.new("RGB", (400, 800), "#15181E").save(source)
        manifest = {
            "product": "Demo",
            "store": "app-store",
            "locale": "pt-BR",
            "profile": "appstore-iphone-6.3-portrait",
            "brand": {"style": "minimal-premium"},
            "screens": [
                {"order": 1, "source": "source.png", "source_platform": "ios", "source_evidence": "manual_input", "output": "final/a.png", "headline": "Benefício direto", "supporting_copy": "Texto curto.", "objective": "Valor.", "feature": "Tela real fornecida.", "variant": "benefit", "hypothesis": "A comunica valor."},
                {"order": 2, "source": "source.png", "source_platform": "ios", "source_evidence": "manual_input", "output": "final/b.png", "headline": "Problema evitado", "supporting_copy": "Texto curto.", "objective": "Valor.", "feature": "Tela real fornecida.", "variant": "problem", "hypothesis": "B comunica incerteza."}
            ]
        }
        path = directory / "manifest.json"
        path.write_text(json.dumps(manifest), encoding="utf-8")
        return path

    def run_tool(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(["python3", str(SCRIPT), *args], text=True, capture_output=True, check=False)

    def test_renders_two_opaque_store_pngs_and_gallery(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            manifest = self.make_manifest(base)
            result = self.run_tool("render", "--manifest", str(manifest))
            self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
            first, second = base / "final/a.png", base / "final/b.png"
            for export in (first, second):
                with Image.open(export) as image:
                    self.assertEqual(image.size, (1206, 2622))
                    self.assertEqual(image.mode, "RGB")
            self.assertIsNotNone(ImageChops.difference(Image.open(first), Image.open(second)).getbbox())
            gallery = base / "preview/index.html"
            self.assertEqual(self.run_tool("gallery", "--manifest", str(manifest), "--output", str(gallery)).returncode, 0)
            self.assertIn("Nico", gallery.read_text(encoding="utf-8"))

    def test_rejects_invalid_dimension(self):
        with tempfile.TemporaryDirectory() as temporary:
            bad = Path(temporary) / "bad.png"
            Image.new("RGB", (100, 100), "black").save(bad)
            result = self.run_tool("validate-image", "--profile", "appstore-iphone-6.3-portrait", "--image", str(bad))
            self.assertEqual(result.returncode, 1)
            self.assertIn("expected 1206x2622", result.stdout)

    def test_rejects_ios_capture_for_google_play(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            manifest = self.make_manifest(base)
            data = json.loads(manifest.read_text(encoding="utf-8"))
            data["store"] = "google-play"
            data["profile"] = "google-play-phone-portrait"
            manifest.write_text(json.dumps(data), encoding="utf-8")
            result = self.run_tool("render", "--manifest", str(manifest))
            self.assertEqual(result.returncode, 1)
            self.assertIn("requires a android capture", result.stdout)


if __name__ == "__main__":
    unittest.main()
