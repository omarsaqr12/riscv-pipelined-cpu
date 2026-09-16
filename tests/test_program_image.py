"""Check the committed example's on-disk contract, not CPU execution.

Run: python3 -m unittest discover -s tests -p 'test_*.py' -v
"""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
IMAGE = ROOT / "Test_cases" / "program.mem"
MEMORY_CAPACITY_BYTES = 4 * 1024  # singleMemory.v declares 4 KiB.


class ProgramImageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.lines = [line.strip() for line in IMAGE.read_text(encoding="ascii").splitlines() if line.strip()]

    def test_every_line_is_one_binary_byte(self):
        self.assertGreater(len(self.lines), 0)
        for line_number, byte in enumerate(self.lines, start=1):
            with self.subTest(line=line_number):
                self.assertEqual(len(byte), 8)
                self.assertTrue(all(ch in "01" for ch in byte))

    def test_image_fits_four_kib_memory_and_contains_whole_words(self):
        self.assertLessEqual(len(self.lines), MEMORY_CAPACITY_BYTES)
        self.assertEqual(len(self.lines) % 4, 0)

    def test_first_word_matches_documented_lw_encoding(self):
        # singleMemory.v composes words little-endian from consecutive bytes.
        word = sum(int(byte, 2) << (8 * position) for position, byte in enumerate(self.lines[:4]))
        self.assertEqual(word, 0x00002083)  # lw x1, 0(x0)
        self.assertEqual(word & 0x7F, 0b0000011)
        self.assertEqual((word >> 7) & 0x1F, 1)
        self.assertEqual((word >> 15) & 0x1F, 0)


if __name__ == "__main__":
    unittest.main()
