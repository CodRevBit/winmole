"""
WinMole - Python CLI Entrypoint & Runner
Bridges uv / pip execution to WinMole's native PowerShell core engine.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


def main() -> None:
    # Resolve root directory of winmole
    root_dir = Path(__file__).resolve().parent
    ps_script = root_dir / "winmole.ps1"

    if not ps_script.exists():
        candidates = list(root_dir.glob("**/winmole.ps1"))
        if candidates:
            ps_script = candidates[0]
        else:
            sys.stderr.write(
                f"[winmole] Error: Could not locate 'winmole.ps1' relative to {root_dir}\n"
            )
            sys.exit(1)

    cmd = [
        "powershell.exe",
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        str(ps_script),
        *sys.argv[1:],
    ]

    try:
        proc = subprocess.run(cmd)
        sys.exit(proc.returncode)
    except KeyboardInterrupt:
        sys.exit(130)
    except Exception as exc:
        sys.stderr.write(f"[winmole] Execution error: {exc}\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
