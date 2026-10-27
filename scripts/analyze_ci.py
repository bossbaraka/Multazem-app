#!/usr/bin/env python3
"""Run the Dart analyzer without hiding failures; expose diagnostics in CI checks."""
import subprocess
import sys
from pathlib import Path


def main():
    result = subprocess.run(
        ['dart', 'analyze', '--format=machine'],
        capture_output=True, text=True, check=False,
    )
    print(result.stdout, end='')
    print(result.stderr, end='', file=sys.stderr)
    # GitHub's annotations API remains readable even when raw build logs aren't.
    import os
    if os.environ.get('GITHUB_ACTIONS') == 'true':
        for line in result.stdout.splitlines():
            parts = line.split('|', 7)
            if len(parts) != 8:
                continue
            severity, _, code, filename, row, column, _, message = parts
            level = {'ERROR': 'error', 'WARNING': 'warning'}.get(severity, 'notice')
            try:
                filename = str(Path(filename).relative_to(Path.cwd()))
            except ValueError:
                pass
            message = message.replace('%', '%25').replace('\r', '%0D').replace('\n', '%0A')
            print(f'::{level} file={filename},line={row},col={column},title={code}::{message}')
    return result.returncode


if __name__ == '__main__':
    sys.exit(main())
