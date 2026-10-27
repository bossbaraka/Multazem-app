#!/usr/bin/env python3
"""Stream a CI command and expose failed-command output in GitHub annotations.

The command's exit status is preserved, including analyzer warnings and infos.
"""
import os
import subprocess
import sys
from collections import deque


def main():
    if len(sys.argv) < 2:
        print('Usage: python3 scripts/run_ci.py COMMAND [ARGS...]', file=sys.stderr)
        return 2
    tail = deque(maxlen=100)
    with subprocess.Popen(
        sys.argv[1:], stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        text=True, bufsize=1,
    ) as process:
        for line in process.stdout:
            print(line, end='', flush=True)
            tail.append(line)
        status = process.wait()
    if status and os.environ.get('GITHUB_ACTIONS') == 'true':
        output = ''.join(tail)
        for start in range(0, len(output), 2500):
            message = output[start:start + 2500].replace('%', '%25').replace('\r', '%0D').replace('\n', '%0A')
            print(f'::error title=CI command failed::{message}')
    return status


if __name__ == '__main__':
    sys.exit(main())
