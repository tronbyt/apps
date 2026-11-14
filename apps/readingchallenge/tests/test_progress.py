"""Run the app's progress parser in Pixlet without contacting Goodreads."""

import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


class ProgressTests(unittest.TestCase):
    def render_progress(self, body):
        with tempfile.TemporaryDirectory() as directory:
            app = Path(directory)
            shutil.copy(Path(__file__).resolve().parents[1] / "progress.star", app)
            script = app / "test.star"
            script.write_text(
                'load("progress.star", "parse_progress")\n'
                'load("render.star", "render")\n'
                'def main(config):\n'
                f'    progress, goal = parse_progress({json.dumps(body)})\n'
                '    print("PROGRESS|{}|{}".format(progress, goal))\n'
                '    return render.Root(child = render.Text(content = "PASS"))\n'
            )
            return subprocess.run(
                ["pixlet", "render", str(script), "-o", str(app / "test.webp")],
                capture_output=True, text=True, timeout=30,
            )

    def test_supported_formats(self):
        cases = [
            ("legacy", "<div class='progressText'>55 books read of 75</div>", "55", "75"),
            ("current", 'window.urcData = {"readingProgress":"55","readingGoal":"75"};', "55", "75"),
            ("zero", 'window.urcData = {"readingProgress":"0","readingGoal":"75"};', "0", "75"),
            ("numbers", 'window.urcData = {\n"readingProgress":55,"readingGoal":75\n};', "55", "75"),
            ("over goal", 'window.urcData = {"readingProgress":"80","readingGoal":"75"};', "80", "75"),
            ("embedded JSON", 'window.urcData = {"readingProgress":"55","readingGoal":"75","booksRead":"[{\\"asin\\":\\"123\\"}]"};', "55", "75"),
        ]
        for name, body, progress, goal in cases:
            with self.subTest(name=name):
                result = self.render_progress(body)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn(f"PROGRESS|{progress}|{goal}", result.stdout)

    def test_missing_or_invalid_progress(self):
        cases = [
            ("unrelated page", "<html>Sign in</html>", "No challenge progress found"),
            ("missing goal", 'window.urcData = {"readingProgress":"55"};', "Invalid Goodreads reading progress or goal"),
            ("negative progress", 'window.urcData = {"readingProgress":"-1","readingGoal":"75"};', "Invalid Goodreads reading progress or goal"),
            ("incomplete legacy", "<div class='progressText'>55 books read</div>", "Invalid Goodreads reading progress or goal"),
        ]
        for name, body, error in cases:
            with self.subTest(name=name):
                result = self.render_progress(body)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(error, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
