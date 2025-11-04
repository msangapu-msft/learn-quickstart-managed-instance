# Install.ps1 - Copy and register fonts on Managed Instance
Write-Host "Installing custom fonts on Managed Instance..." -ForegroundColor Green

# Copy all TTF and OTF fonts to Windows Fonts folder and register them
Get-ChildItem -Recurse -Include *.ttf, *.otf | ForEach-Object {
    $FontFullName = $_.FullName
    $FontName = $_.BaseName + " (TrueType)"
    $Destination = "$env:windir\Fonts\$($_.Name)"

    Write-Host "Installing font: $($_.Name)"
    Copy-Item $FontFullName -Destination $Destination -Force
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" -Name $FontName -PropertyType String -Value $_.Name -Force | Out-Null
}

Write-Host "Font installation completed." -ForegroundColor Green