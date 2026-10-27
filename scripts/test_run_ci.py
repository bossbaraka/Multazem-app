"""Regression tests for the CI command runner (no Flutter installation required)."""
import os
from pathlib import Path
import subprocess
import sys
import unittest

RUNNER = Path(__file__).with_name('run_ci.py')


class RunCiTests(unittest.TestCase):
    def run_command(self, code, github=False):
        env = dict(os.environ, GITHUB_ACTIONS='true' if github else 'false')
        return subprocess.run(
            [sys.executable, str(RUNNER), sys.executable, '-c', code],
            capture_output=True, text=True, env=env, check=False,
        )

    def test_success_streams_output_without_annotation(self):
        result = self.run_command("print('passed')", github=True)
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout, 'passed\n')

    def test_failure_preserves_status_and_escapes_annotation(self):
        result = self.run_command(
            "import sys; print('error 50%'); print('details', file=sys.stderr); sys.exit(7)",
            github=True,
        )
        self.assertEqual(result.returncode, 7)
        self.assertIn('::error title=CI command failed::', result.stdout)
        self.assertIn('50%25%0A', result.stdout)
        self.assertIn('details', result.stdout)

    def test_failure_outside_github_does_not_emit_annotations(self):
        result = self.run_command("import sys; print('failed'); sys.exit(1)")
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout, 'failed\n')


if __name__ == '__main__':
    unittest.main()
