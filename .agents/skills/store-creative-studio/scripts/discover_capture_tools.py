#!/usr/bin/env python3
"""Report local capture capabilities without starting simulators or emulators."""

from __future__ import annotations

import json
import shutil
import subprocess


def run(*args: str) -> str:
    try:
        return subprocess.run(args, check=False, capture_output=True, text=True, timeout=8).stdout
    except (OSError, subprocess.TimeoutExpired):
        return ""


def main() -> None:
    xcrun = shutil.which("xcrun")
    adb = shutil.which("adb")
    screencapture = shutil.which("screencapture")
    simulators = run(xcrun, "simctl", "list", "devices", "available") if xcrun else ""
    devices = run(adb, "devices", "-l") if adb else ""
    print(json.dumps({
        "ios": {"xcrun": bool(xcrun), "available_simulators": [line.strip() for line in simulators.splitlines() if "(" in line and ")" in line]},
        "android": {"adb": bool(adb), "connected_devices": [line.strip() for line in devices.splitlines()[1:] if line.strip()]},
        "macos": {"screencapture": bool(screencapture), "note": "Window capture is manual unless the target app exposes an automation path."},
        "manual_input": True,
        "note": "This is capability discovery only; no capture proves a released build or store state."
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
