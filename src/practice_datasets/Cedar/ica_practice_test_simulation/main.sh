#!/usr/bin/env bash
# CodeSignal uses /usercode/FILESYSTEM/tests — run from this directory locally.
echo "> python3 -m unittest discover -s tests -p '*.py' 2>&1"
python3 -m unittest discover -s tests -p '*.py' 2>&1
