#!/usr/bin/env python3
import sys
from pathlib import Path


BACKEND_DIR = Path(__file__).resolve().parent.parent
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from dji_render_relay_worker import main as relay_main


def run_scenario(scenario_id):
    argv = list(sys.argv[1:])
    if "--scenario" not in argv:
        argv = ["--scenario", scenario_id, *argv]
    if "--demo" not in argv:
        argv = ["--demo", *argv]

    previous_argv = sys.argv
    try:
        sys.argv = [previous_argv[0], *argv]
        return relay_main()
    finally:
        sys.argv = previous_argv
