$ErrorActionPreference = 'SilentlyContinue'

# === STAGE 2: Gate Check - Read power.txt, Validate GO ===

$appData = [System.IO.Path]::GetFolderPath('ApplicationData')
$desktop = [System.Environment]::GetFolderPath('Desktop')
$powerPath = "$appData\Microsoft\Credentials\power.txt"

# Check multiple locations for power.txt
$locations = @(
    $powerPath,
    "$desktop\power.txt",
    "$env:TEMP\power.txt",
    "$appData\power.txt"
)

$found = $false
$content = ""

foreach ($loc in $locations) {
    if (Test-Path $loc) {
        $content = [System.IO.File]::ReadAllText($loc, [System.Text.Encoding]::UTF8)
        if ($content -match "GO") {
            $found = $loc
            break
        }
    }
}

if ($found) {
    # Gate passed - proceed to Stage 3
    Write-Output "GATE:PASS:File=$found"
    $true
} else {
    # Gate failed - no GO found
    Write-Output "GATE:FAIL:No GO found in power.txt"
    $false
}
