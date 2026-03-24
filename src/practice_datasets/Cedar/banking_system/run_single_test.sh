#!/usr/bin/env sh
# Usage: bash run_single_test.sh "test_method_name_substring"
python3 -m unittest discover -s tests -p "*.py" -k "$1" 2>&1
