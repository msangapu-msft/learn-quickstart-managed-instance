#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"

ZIP_NAME="configuration-scripts.zip"
STAGE_DIR="${REPO_ROOT}/_install_stage"

INSTALL_PS1_SRC="${REPO_ROOT}/scripts/Install.ps1"
FONTS_DIR_SRC="${REPO_ROOT}/scripts/fonts"

echo "== Preparing configuration-scripts.zip =="
echo "REPO_ROOT: $REPO_ROOT"
echo "FONTS_DIR: $FONTS_DIR_SRC"

rm -f "${REPO_ROOT}/${ZIP_NAME}"
rm -rf "${STAGE_DIR}"
mkdir -p "${STAGE_DIR}/fonts"

# Validate sources
if [ ! -f "$INSTALL_PS1_SRC" ]; then
  echo "ERROR: Install.ps1 not found at $INSTALL_PS1_SRC"
  exit 1
fi

if [ ! -d "$FONTS_DIR_SRC" ]; then
  echo "ERROR: fonts directory not found at $FONTS_DIR_SRC"
  exit 1
fi

# Copy Install.ps1
cp "$INSTALL_PS1_SRC" "${STAGE_DIR}/Install.ps1"

# Copy fonts (ttf and otf)
shopt -s nullglob
fonts=( "$FONTS_DIR_SRC"/*.ttf "$FONTS_DIR_SRC"/*.otf )
shopt -u nullglob

if [ ${#fonts[@]} -eq 0 ]; then
  echo "ERROR: No .ttf or .otf font files found in $FONTS_DIR_SRC"
  echo "Contents of $FONTS_DIR_SRC:"
  ls -la "$FONTS_DIR_SRC" || true
  exit 1
fi

echo "Copying ${#fonts[@]} font files..."
cp "${fonts[@]}" "${STAGE_DIR}/fonts/"

echo ""
echo "Staged files:"
find "${STAGE_DIR}" -type f -print
echo ""

# Create zip
(
  cd "${STAGE_DIR}"
  zip -q -r "${REPO_ROOT}/${ZIP_NAME}" . -x '*.DS_Store'
)

echo "✓ ${ZIP_NAME} created"
echo ""
echo "Font files in ZIP:"
unzip -l "${REPO_ROOT}/${ZIP_NAME}" | grep -i '\.ttf' | head -20 || echo "No fonts found in ZIP!"
echo ""

# Verify fonts exist
FONT_COUNT=$(unzip -l "${REPO_ROOT}/${ZIP_NAME}" 2>/dev/null | grep -ic '\.ttf' || echo "0")
if [ "$FONT_COUNT" -eq 0 ]; then
  echo "ERROR: ZIP created but contains no TTF fonts."
  exit 1
fi

echo "✓ Verified: $FONT_COUNT font files packaged."

# Cleanup
rm -rf "${STAGE_DIR}"