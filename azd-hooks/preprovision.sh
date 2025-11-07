#!/bin/bash
set -e

echo "=================================================="
echo "Creating installation package with fonts..."
echo "=================================================="

# Create temp directory for install package
mkdir -p temp-install

# Copy fonts from the app's fonts directory to the install package
echo "Adding fonts to installation package..."
if [ -d "scripts/fonts" ]; then
    cp scripts/fonts/*.ttf temp-install/ 2>/dev/null || true
    echo "Added fonts from scripts/fonts"

    cp scripts/Install.ps1 temp-install/ 2>/dev/null || true
    echo "Added Install.ps1"
fi

# Create the ZIP file with Install.ps1 AND fonts
cd temp-install
echo "Files to be zipped:"
ls -la
zip -r ../scripts.zip *
cd ..

# Clean up
rm -rf temp-install

echo "✓ scripts.zip created ($(ls -lh scripts.zip | awk '{print $5}'))"
