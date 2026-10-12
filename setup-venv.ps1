param(
    [ValidateSet("China", "Overseas")]
    [string]$Source = "China"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
Set-Location $PSScriptRoot

# Python 本体、下载工具和缓存保留在项目内，.venv 引用该 Python。
$bootstrapDir = Join-Path $PSScriptRoot "env\bootstrap"
$downloadDir = Join-Path $PSScriptRoot "env\downloads"
$env:UV_PYTHON_INSTALL_DIR = Join-Path $PSScriptRoot "env\python"
$env:UV_CACHE_DIR = Join-Path $PSScriptRoot "env\uv-cache"
$uvExe = Join-Path $bootstrapDir "uv.exe"
$pythonExe = Join-Path $PSScriptRoot ".venv\Scripts\python.exe"
New-Item -ItemType Directory -Path $bootstrapDir, $downloadDir -Force | Out-Null

if (-not (Test-Path $uvExe)) {
    $uvZip = Join-Path $bootstrapDir "uv.zip"
    Invoke-WebRequest -UseBasicParsing `
        -Uri "https://github.com/astral-sh/uv/releases/download/0.13.0/uv-x86_64-pc-windows-msvc.zip" `
        -OutFile $uvZip
    Expand-Archive -LiteralPath $uvZip -DestinationPath $bootstrapDir -Force
}

function Invoke-Uv {
    & $uvExe @args
    if ($LASTEXITCODE -ne 0) { throw "uv failed (exit $LASTEXITCODE)" }
}

if (-not (Test-Path $pythonExe)) {
    Invoke-Uv python install 3.12 --no-bin
    Invoke-Uv venv .venv --python 3.12 --seed
}
& $pythonExe -c "import sys; assert sys.version_info[:2] == (3, 12), 'This environment requires Python 3.12'"
if ($LASTEXITCODE -ne 0) { throw "Existing .venv is not Python 3.12; it was not replaced." }

# 约束后续依赖解析，避免 torchaudio 隐式升级并更换 CUDA 版本。
$constraints = Join-Path $PSScriptRoot ".venv\cu118-constraints.txt"
@("torch==2.7.1+cu118", "torchaudio==2.7.1+cu118") |
    Set-Content $constraints -Encoding ascii
Invoke-Uv pip install --python $pythonExe torch==2.7.1+cu118 torchaudio==2.7.1+cu118 `
    --index-url https://download.pytorch.org/whl/cu118

$variant = if ($Source -eq "China") { "china" } else { "overseas" }
Invoke-Uv pip install --python $pythonExe --constraint $constraints `
    --requirement "requirements-py312-win-flash_attention\requirements_py312_win_cu118_$variant.txt"

# 中文处理和英文混合文本所需的数据，与 Python 依赖分开存放。
$modelHost = if ($Source -eq "China") {
    "https://www.modelscope.cn/models/XXXXRT/GPT-SoVITS-Pretrained/resolve/master"
} else {
    "https://huggingface.co/XXXXRT/GPT-SoVITS-Pretrained/resolve/main"
}
if (-not (Test-Path "GPT_SoVITS\text\G2PWModel")) {
    $g2pwZip = Join-Path $downloadDir "G2PWModel.zip"
    Invoke-WebRequest -UseBasicParsing -Uri "$modelHost/G2PWModel.zip" -OutFile $g2pwZip
    Expand-Archive -LiteralPath $g2pwZip -DestinationPath "GPT_SoVITS\text" -Force
}
if (-not (Test-Path ".venv\nltk_data")) {
    $nltkZip = Join-Path $downloadDir "nltk_data.zip"
    Invoke-WebRequest -UseBasicParsing -Uri "$modelHost/nltk_data.zip" -OutFile $nltkZip
    Expand-Archive -LiteralPath $nltkZip -DestinationPath ".venv" -Force
}

# 中英混合文本的语言分段也需要 fastText 模型。
$langDir = Join-Path $PSScriptRoot "GPT_SoVITS\pretrained_models\fast_langdetect"
New-Item -ItemType Directory -Path $langDir -Force | Out-Null
foreach ($filename in @("lid.176.bin", "lid.176.ftz")) {
    $modelFile = Join-Path $langDir $filename
    if (-not (Test-Path $modelFile)) {
        Invoke-WebRequest -UseBasicParsing `
            -Uri "https://dl.fbaipublicfiles.com/fasttext/supervised-models/$filename" `
            -OutFile $modelFile
    }
}

& $pythonExe -m pip check
if ($LASTEXITCODE -ne 0) { throw "Dependency check failed" }
& $pythonExe -c "import torch; assert torch.cuda.is_available(); print(torch.__version__, torch.version.cuda, torch.cuda.get_device_name(0)); print((torch.ones(1, device='cuda') + 1).item())"
if ($LASTEXITCODE -ne 0) { throw "CUDA check failed" }
Write-Host "Ready. Start WebUI: .\go-webui.ps1"
