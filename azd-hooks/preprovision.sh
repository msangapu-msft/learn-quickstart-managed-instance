#!/bin/bash
set -e

echo "=================================================="
echo "Creating installation package with fonts..."
echo "=================================================="

# Create temp directory for install package
mkdir -p temp-install

# Create Install.ps1
cat > temp-install/Install.ps1 <<'EOF'
# Install.ps1 - Copy and register fonts on Managed Instance
Write-Host "Installing custom fonts on Managed Instance..." -ForegroundColor Green

Get-ChildItem -Recurse -Include *.ttf, *.otf | ForEach-Object {
    $FontFullName = $_.FullName
    $FontName = $_.BaseName + " (TrueType)"
    $Destination = "$env:windir\Fonts\$($_.Name)"

    Write-Host "Installing font: $($_.Name)"
    Copy-Item $FontFullName -Destination $Destination -Force
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" -Name $FontName -PropertyType String -Value $_.Name -Force | Out-Null
}

Write-Host "Font installation completed." -ForegroundColor Green
EOF

# Copy fonts from the app's fonts directory to the install package
echo "Adding fonts to installation package..."
if [ -d "src/AptosImageDemo/fonts" ]; then
    cp src/AptosImageDemo/fonts/*.ttf temp-install/ 2>/dev/null || true
    cp src/AptosImageDemo/fonts/*.otf temp-install/ 2>/dev/null || true
    echo "Added fonts from src/AptosImageDemo/fonts"
fi

# If you have additional custom fonts directory
if [ -d "custom-fonts" ]; then
    cp custom-fonts/*.ttf temp-install/ 2>/dev/null || true
    cp custom-fonts/*.otf temp-install/ 2>/dev/null || true
    echo "Added fonts from custom-fonts"
fi

# Create the ZIP file with Install.ps1 AND fonts
cd temp-install
echo "Files to be zipped:"
ls -la
zip -r ../configuration-scripts.zip *
cd ..

# Clean up
rm -rf temp-install

echo "✓ configuration-scripts.zip created ($(ls -lh configuration-scripts.zip | awk '{print $5}'))"