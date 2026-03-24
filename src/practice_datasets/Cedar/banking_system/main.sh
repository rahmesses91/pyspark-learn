#!/usr/bin/env bash
# CodeSignal uses a path like /usercode/FILESYSTEM/tests — locally, run from this directory.
echo "> python3 -m unittest discover -s tests -p '*.py' 2>&1"
python3 -m unittest discover -s tests -p '*.py' 2>&1
