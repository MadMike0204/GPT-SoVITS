$ErrorActionPreference = "Stop"
chcp 65001
Set-Location $PSScriptRoot
$runtimePath = Join-Path $PSScriptRoot ".venv\Scripts"
if (-not (Test-Path (Join-Path $runtimePath "python.exe"))) {
    $runtimePath = Join-Path $PSScriptRoot "runtime"
}
$env:PATH = "$runtimePath;$env:PATH"
& "$runtimePath\python.exe" -I "$PSScriptRoot\webui.py" zh_CN
pause
