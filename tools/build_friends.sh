#!/usr/bin/env bash
# Exports the Windows build and zips it with the tester readme for friends.
# Usage: bash tools/build_friends.sh "$G"
set -e
G="$1"
cd "$(dirname "$0")/.."
"$G" --headless --path . --import >/dev/null 2>&1
"$G" --headless --path . --export-release "Windows" builds/CatSurvivors.exe >/dev/null 2>&1
cp tools/PRECITAJ_MA.txt builds/PRECITAJ_MA.txt
ZIP="CatSurvivors-test-$(date +%Y-%m-%d).zip"
rm -f "builds/$ZIP"
powershell -NoProfile -Command "Compress-Archive -Path builds/CatSurvivors.exe, builds/PRECITAJ_MA.txt -DestinationPath builds/$ZIP -Force"
echo "builds/$ZIP"
