import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[2] / "tools" / "nico_validate.py"
SPEC = importlib.util.spec_from_file_location("nico_validate", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class NicoValidateTests(unittest.TestCase):
    def test_ios_keyword_limit_uses_utf8_bytes(self):
        result = MODULE.validate({"platform": "ios", "metadata": {"keywords": "á" * 51}})
        self.assertFalse(result["valid"])
        self.assertEqual(result["checks"][0]["unit"], "utf8_bytes")

    def test_android_short_description_limit(self):
        result = MODULE.validate({"platform": "android", "metadata": {"short_description": "a" * 81}})
        self.assertFalse(result["valid"])
        self.assertEqual(result["errors"][0]["field"], "short_description")

    def test_unknown_platform_fails_closed(self):
        result = MODULE.validate({"platform": "web", "metadata": {}})
        self.assertFalse(result["valid"])

    def test_discovery_marks_external_state_unverified(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "App.xcodeproj").mkdir()
            (root / "android" / "app").mkdir(parents=True)
            (root / "android" / "app" / "build.gradle.kts").write_text("", encoding="utf-8")
            (root / "docs").mkdir()
            (root / "docs" / "ASO_METADATA.md").write_text("LagCheck", encoding="utf-8")
            result = MODULE.discover(root)
        self.assertEqual(result["platforms"], ["ios", "android"])
        self.assertEqual(result["distribution_state"], "not_verified")

    def test_guard_blocks_publication_without_authorization(self):
        result = MODULE.operation_guard("publish", authorized=False)
        self.assertFalse(result["allowed"])
        self.assertTrue(MODULE.operation_guard("audit", authorized=False)["allowed"])

    def test_json_contract_is_serializable(self):
        result = MODULE.validate({"platform": "ios", "locale": "pt-BR", "metadata": {"name": "LagCheck"}})
        json.dumps(result)


if __name__ == "__main__":
    unittest.main()
