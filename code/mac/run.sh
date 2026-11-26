#!/bin/bash
# CampusCare - run the whole project on this Mac with one command:
#
#     bash code/mac/run.sh
#
# The first run downloads what it needs (about 3 GB) into code/.tools.
# Nothing is installed on the Mac itself. Later runs start in about a minute.
set -euo pipefail
cd "$(dirname "$0")/.."

TOOLS="$PWD/.tools"
PY="$TOOLS/python/bin/python3"

if [ ! -x "$PY" ]; then
  if [ "$(uname -s)" != "Darwin" ]; then
    echo "This script is for macOS. On Windows use code\\windows\\run.bat"; exit 1
  fi
  # sysctl, not uname: a Terminal running under Rosetta would report x86_64.
  if [ "$(sysctl -n hw.optional.arm64 2>/dev/null || echo 0)" = "1" ]; then
    ARCH=aarch64
  else
    ARCH=x86_64
  fi
  echo
  echo "  CampusCare - first run."
  echo "  Downloading what it needs (about 3 GB) into this folder."
  echo "  Nothing is installed on your Mac. Please keep this window open."
  echo
  mkdir -p "$TOOLS"
  curl -fL -# --retry 5 --connect-timeout 30 -C - -o "$TOOLS/python.tar.gz" \
    "https://github.com/astral-sh/python-build-standalone/releases/download/20261123/cpython-3.12.16%2B20261123-${ARCH}-apple-darwin-install_only_stripped.tar.gz"
  rm -rf "$TOOLS/python"
  tar -xf "$TOOLS/python.tar.gz" -C "$TOOLS"
  rm -f "$TOOLS/python.tar.gz"
fi

exec "$PY" -E -s launcher/run.py "$@"
