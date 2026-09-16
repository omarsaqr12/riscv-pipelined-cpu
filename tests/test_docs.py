"""Validate first-time reader navigation; does not test CPU function."""

from pathlib import Path
import re
import unittest
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]
DOCS = (
    ROOT / "README.md",
    ROOT / "ArchProject" / "README.md",
    ROOT / "Test_cases" / "README.md",
    ROOT / "docs" / "ARCHITECTURE.md",
    ROOT / "docs" / "VERIFICATION.md",
)
LINK = re.compile(r"\[[^\]\n]+\]\(([^)\n]+)\)")


class DocumentationLinkTests(unittest.TestCase):
    def test_local_markdown_targets_exist(self):
        for document in DOCS:
            with self.subTest(document=str(document.relative_to(ROOT))):
                self.assertTrue(document.is_file())
                for target in LINK.findall(document.read_text(encoding="utf-8")):
                    target = target.split("#", 1)[0].split("?", 1)[0]
                    if not target or target.startswith(("http://", "https://", "mailto:")):
                        continue
                    resolved = (document.parent / unquote(target)).resolve()
                    with self.subTest(target=target):
                        self.assertTrue(resolved.is_relative_to(ROOT), "link escapes repository")
                        self.assertTrue(resolved.exists(), f"missing local link: {target}")


if __name__ == "__main__":
    unittest.main()
