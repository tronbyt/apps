# Copyright 2026 cptntrps
# SPDX-License-Identifier: Apache-2.0

"""Run with python3 test_baby_size.py; requires Pillow and the pinned Pixlet."""
import ast
import base64
import io
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

from PIL import Image


APP = Path(__file__).resolve().parent
PIXLET = os.environ.get("PIXLET", "pixlet")


class BabySizeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = (APP / "baby_size.star").read_text()
        cls.catalog = {}
        for node in ast.parse(cls.source).body:
            if isinstance(node, ast.Assign) and isinstance(node.targets[0], ast.Name):
                name = node.targets[0].id
                if name in {"SIZES", "CHOICES", "NAMES", "POKEMON_HEIGHTS", "S1", "S2", "DEVELOPMENT", "TIPS", "WEEK_TIPS"}:
                    cls.catalog[name] = ast.literal_eval(node.value)
            elif isinstance(node, ast.FunctionDef) and node.name in {"comparison_choices", "valid_date", "development_lines", "tip_id"}:
                exec(compile(ast.Module(body=[node], type_ignores=[]), "baby_size.star", "exec"), cls.catalog)

    def test_curated_selection(self):
        heights = self.catalog["POKEMON_HEIGHTS"]
        self.assertEqual(len(heights), 25)
        self.assertEqual(heights["eevee"], 30)
        self.assertEqual(heights["mew"], 40)
        self.assertEqual(heights["squirtle"], 50)
        excluded = {"cubone", "exeggcute", "diglett"}
        for key in ("POKEMON_HEIGHTS", "S1", "S2"):
            self.assertFalse(excluded & self.catalog[key].keys())
        for picks in self.catalog["CHOICES"].values():
            self.assertFalse(excluded.intersection(picks))

    def test_every_pregnancy_day(self):
        seen = set()
        for week in range(4, 41):
            for day in range(7):
                start = self.catalog["SIZES"][str(week)][0]
                end = self.catalog["SIZES"].get(str(week + 1), (start, 0))[0]
                length = start if week in (19, 40) else start + (end - start) * day / 7
                picks = self.catalog["comparison_choices"](week, length)
                self.assertGreaterEqual(len(picks), 3)
                self.assertEqual(len(picks), len(set(picks)))
                for obj in picks:
                    if obj in self.catalog["POKEMON_HEIGHTS"]:
                        height = self.catalog["POKEMON_HEIGHTS"][obj]
                        self.assertGreaterEqual(week, 20)
                        self.assertLessEqual(abs(length - height) / height, 0.10000001)
                        seen.add(obj)
        self.assertEqual(seen, self.catalog["POKEMON_HEIGHTS"].keys())

    def test_daily_height_boundaries(self):
        choices = self.catalog["comparison_choices"]
        self.assertNotIn("eevee", choices(21, 26.99))
        self.assertIn("eevee", choices(21, 27.0))
        self.assertIn("eevee", choices(24, 33.0))
        self.assertNotIn("eevee", choices(24, 33.01))

    def test_names_and_sprites(self):
        used = {o for picks in self.catalog["CHOICES"].values() for o in picks}
        self.assertEqual(len(used), 95)
        for obj in used:
            self.assertTrue(all(0 < len(name) <= 11 for name in self.catalog["NAMES"][obj]))
            for key, size in [("S1", 16), ("S2", 32)]:
                im = Image.open(io.BytesIO(base64.b64decode(self.catalog[key][obj])))
                self.assertEqual(im.size, (size, size))
                self.assertIsNotNone(im.convert("RGBA").getchannel("A").getbbox())

    def test_date_validation(self):
        valid = self.catalog["valid_date"]
        for value in ["2028-02-29", "2026-12-31", "2000-02-29T00:00:00Z"]:
            self.assertTrue(valid(value), value)
        for value in ["", "invalid", "2026-02-29", "2100-02-29", "2026-04-31", "2026-00-10", "0000-01-01", "2026-01-00", "2026-13-01", "2026-1-01", "2026-01-01junk"]:
            self.assertFalse(valid(value), value)

    def render(self, source, *config):
        with tempfile.TemporaryDirectory() as temp:
            fixture = Path(temp) / "fixture.star"
            fixture.write_text(source)
            output = Path(temp) / "preview.webp"
            result = subprocess.run([PIXLET, "render", str(fixture), *config, "-o", str(output)], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            with Image.open(output) as im:
                self.assertEqual(im.size, (64, 32))
            return result.stdout + result.stderr

    def test_default_and_invalid_config_render(self):
        self.render(self.source)
        self.render(self.source, "lang=pt")
        self.render(self.source, "due_date=not-a-date")
        self.render(self.source, "due_date=2026-02-30", "lang=pt")
        self.render(self.source, "due_date=2000-01-01T00:00:00Z")

    def test_daylight_saving_calendar_boundaries(self):
        for now, due in [("2026-03-07T23:30:00-05:00", "2026-03-09"), ("2026-10-31T23:30:00-04:00", "2026-11-02")]:
            source = self.source.replace("now = time.now().in_location(tz)", "now = time.parse_time(" + repr(now) + ").in_location(tz)")
            source = source.replace("gest = 280 - days_left", 'print("CALENDAR_DAYS", days_left)\n    gest = 280 - days_left')
            result = self.render(source, "due_date=" + due, "$tz=America/New_York")
            self.assertRegex(result, r"CALENDAR_DAYS\s+2")

    def test_generated_artifact_matches_sources(self):
        with tempfile.TemporaryDirectory() as temp:
            for name in ("build.py", "sprites.py", "pokemon.py", "development.py", "tips.py"):
                shutil.copyfile(APP / name, Path(temp) / name)
            subprocess.run([sys.executable, str(Path(temp) / "build.py")], check=True, capture_output=True)
            self.assertEqual((Path(temp) / "baby_size.star").read_bytes(), (APP / "baby_size.star").read_bytes())

    def test_development_week_boundaries_and_text(self):
        self.assertEqual(set(self.catalog["DEVELOPMENT"]), {str(w) for w in range(4, 41)})
        for week in range(4, 41):
            for index, lang in enumerate(("en", "pt")):
                expected = self.catalog["DEVELOPMENT"][str(week)][index]
                self.assertEqual(len(expected), 3)
                self.assertTrue(all(line.isascii() and 0 < len(line) <= 15 for line in expected))
                for day in range(7):
                    self.assertEqual(self.catalog["development_lines"](week * 7 + day, lang), expected)
        for gest in (-1, 0, 27, 287, 300):
            self.assertEqual(self.catalog["development_lines"](gest, "en"), ["DEVELOPMENT", "TIMING VARIES", "FOR EACH BABY"])

    def test_every_development_and_tip_card_renders(self):
        before_main, after_main = self.source.split("def main(config):", 1)
        _, schema = after_main.split("def get_schema():", 1)
        for week in (3, *range(4, 41), 41):
            for lang in ("en", "pt"):
                for page in ("page_development", "page_tip"):
                    source = (before_main + "def main(config):\n"
                              f"    return render.Root(child = {page}({week * 7}, {min(40, max(4, week))}, 0, {lang!r}))\n"
                              + "def get_schema():" + schema)
                    with self.subTest(week=week, lang=lang, page=page):
                        self.render(source)

    def test_tip_coverage_sources_and_hearing_timing(self):
        from tips import TIPS, WEEK_TIPS
        self.assertEqual(set(WEEK_TIPS), set(range(4, 41)))
        self.assertEqual(set(WEEK_TIPS.values()), set(TIPS))
        for tip in TIPS.values():
            self.assertTrue(tip["reason"])
            self.assertTrue(tip["sources"])
            self.assertTrue(all(url.startswith("https://") for url in tip["sources"]))
            for lines in tip["lines"]:
                self.assertEqual(len(lines), 3)
                self.assertTrue(all(line.isascii() and 0 < len(line) <= 15 for line in lines))
        for week in range(4, 41):
            for day in range(7):
                key = self.catalog["tip_id"](week * 7 + day)
                self.assertEqual(key, WEEK_TIPS[week])
                self.assertEqual(self.catalog["TIPS"][key], (*TIPS[key]["lines"], TIPS[key]["badge"]))
                if key == "voice":
                    self.assertGreaterEqual(week, 21)
        for gest in (-1, 27, 287, 300):
            self.assertEqual(self.catalog["tip_id"](gest), "prenatal")


if __name__ == "__main__":
    unittest.main()
