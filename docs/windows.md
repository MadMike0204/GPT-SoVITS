# Windows 自用指南：安装、v5 训练与 TTS 服务

本指南适用于本仓库的 Windows x64 自用配置。入口依次为：
[环境安装](#环境安装)、[模型与目录](#模型与目录)、[训练流程](#训练流程)、
[TTS API](#tts-api)、[检查与排障](#检查与排障)、[验证范围](#验证范围)。

日常启动命令和目录速查见 [项目首页](../README.md)。以下命令均在项目根目录执行。

## 环境安装

本项目使用 Python 3.12、PyTorch 2.7.1+cu118、torchaudio 2.7.1+cu118。
需要 NVIDIA 驱动支持 CUDA 11.8，并在 PATH 中安装 FFmpeg 和 ffprobe。
`nvidia-smi` 的 CUDA Version 表示驱动支持上限；PyTorch cu118 自带运行库，
正常运行无需更换本机 CUDA Toolkit。
在项目根目录执行以下命令可创建或补齐环境，不需要 Conda：

```powershell
powershell -ExecutionPolicy Bypass -File .\setup-venv.ps1
```

国外下载源可添加 `-Source Overseas`。已有 `.venv` 会复用，脚本不会覆盖其他 Python 版本的环境。
Python 本体位于 `env/python`，工具和下载缓存位于 `env`；请保留 `env/python`，`.venv` 依赖它。
`env`、`.venv` 均已被 Git 忽略。

脚本安装 Python 依赖，并下载 G2PW、NLTK 和 fastText 语言识别数据，
不下载 v5、GPT、BERT、HuBERT 底模或 FFmpeg。
采用 Windows/Python 3.12/cu118 专用依赖清单，不叠加根目录的
`requirements.txt`、`extra-req.txt` 或 `install.ps1`；后者没有 CU118 选项。
这套清单包含预编译 FlashAttention 和适配 CUDA 11 的 Faster Whisper/CT2。

启动训练 WebUI：

```powershell
.\.venv\Scripts\python.exe webui.py zh_CN
```

打开 `http://127.0.0.1:9874`，选择已经下载的 `v5dev` 或 `v5turbo`。
`go-webui.bat` / `go-webui.ps1` 也会优先使用 `.venv`。
主界面初始默认仍是 v2Pro，未下载该底模会出现提示；切换到 v5 后使用对应底模。
普通推理子界面默认端口为 9872，文本校对为 9871。

## 模型与目录

从 [官方模型仓库](https://huggingface.co/lj1995/GPT-SoVITS/tree/main)
下载并保持以下结构；dev、turbo 可先下载所需的一种：

```text
GPT_SoVITS/pretrained_models/
├─ chinese-roberta-wwm-ext-large/  # 完整文本模型及 tokenizer 文件
├─ chinese-hubert-base/           # 完整语音模型及预处理配置
├─ s1v3.ckpt                      # v5 共用的 GPT 底模
└─ gsv-v5-pretrained/
   ├─ s2Gv5dev.pth
   ├─ s2Gv5turbo.pth
   └─ vocoder.pth                 # v5 声码器，两种版本共用
```

GPT 将文本特征变为语义序列，v5 将语义序列变为声音特征，vocoder 生成音频。
BERT 提取中文文本特征，HuBERT 提取训练录音和参考音频特征。
中文前端使用 `GPT_SoVITS/text/G2PWModel`；当前代码启用 G2PW，
目录缺失时尝试自动下载，不把 `G2PW=0` 当成关闭此模型的开关。
UVR5 是可选工具，ASR 模型首次使用时另行下载；v5 不需要 v2Pro 的 SV 底模。

训练输出统一保存在根目录 `Weights`，推理界面刷新模型列表时也扫描这里：

```text
Weights/
├─ GPT/
│  ├─ v5dev/*.ckpt
│  └─ v5turbo/*.ckpt
└─ SoVITS/
   ├─ v5dev/*.pth
   └─ v5turbo/*.pth
```

其他版本同样按版本名分目录。`config.py` 中的目录映射同时用于保存和扫描，
WebUI 启动会创建这些子目录。`Weights` 已被 Git 忽略。
下载的底模仍放在 `GPT_SoVITS/pretrained_models`，训练中间数据和断点放在 `logs`。
API 切换权重使用准确文件路径，不会仅因训练结束而自动切换。

## 训练流程

以下以自己的中文录音和 `v5dev` 为例。10～30 分钟干净的单人录音可作为
第一轮数据准备目标；这是实践建议，不是最低时长或效果保证。
尽量使用原始 WAV，避免背景音乐、强混响、削波；不必预先降到 16kHz。

1. 将原始录音放入 `output/myvoice/raw`；录音路径也可位于其他磁盘。
2. 在「0-前置数据集获取工具 / 0b-语音切分工具」填入原始目录，
   输出为 `output/myvoice/slices`。参数先用默认值，检查片段完整性，
   多数片段以约 3～10 秒为起点。已经整理成短句的录音可跳过切分。
3. 在「0c-语音识别工具」选择 SenseVoice 或 Fun-ASR-Nano，语言 `zh`，
   输入切片目录，输出 `output/myvoice/asr`；首次使用需要下载模型。
   当前 ASR 初始值可能是旧名称，开始识别前显式选择列表中的有效选项。
4. 在「0d-语音文本校对标注工具」打开生成的 `.list`，逐句校对并保存。
   标注格式为 `音频路径|说话人|语言|录音实际文字`，例如
   `F:/voice/001.wav|myvoice|zh|你好，这是我的录音。`。
5. 在「1-GPT-SoVITS-TTS」设置实验名 `myvoice_v5dev`，版本选 `v5dev`。
   检查 GPT 底模为 `s1v3.ckpt`，SoVITS 底模为 `s2Gv5dev.pth`。
6. 在「1A-训练集格式化工具」填校对后的 `.list` 和切片目录，
   单卡各 GPU 字段先填 `0`，点击「训练集格式化一键三连」，等待三个步骤完成。
   音频目录留空时使用 `.list` 中的绝对路径；填目录时按文件名拼接。
7. 在「1B-微调训练」分别完成 SoVITS 和 GPT 训练，避免同时运行两个训练或推理。
8. 在「1C-推理」刷新模型列表，加载同一实验的两个权重，用未参与训练的句子试听。

RTX 4070 Ti SUPER 16GB 的保守起步参数如下，需根据录音长度、显存和试听调整：

| 参数 | SoVITS | GPT |
| --- | --- | --- |
| Batch size | 1，可逐步尝试 2 | 4 |
| 总轮数 | 2 | 15 |
| 保存频率 | 每 1 轮 | 每 5 轮 |
| LoRA 秩 | 32 | 不适用 |
| GPU 卡号 | `0` | `0` |

保持“保存最终小模型至 weights 文件夹”开启，DPO 先关闭。
v5 的 SoVITS 微调输出为 LoRA 权重，推理时仍需要对应底模。
turbo 使用 `v5turbo` 实验和目录；当前推理默认采样 dev 为 32 步、turbo 为 4 步。
不要直接复用其他版本的训练中间目录，切换版本或替换数据时使用新实验名。

## TTS API

用 v5dev 底模启动 API：

```powershell
.\.venv\Scripts\python.exe api_v2.py -a 127.0.0.1 -p 9880 -c GPT_SoVITS/configs/tts_v5.yaml
```

`GPT_SoVITS/configs/*.yaml` 被 Git 忽略；全新克隆后需要手动创建
`GPT_SoVITS/configs/tts_v5.yaml`，内容如下（环境安装脚本不生成该文件）：

```yaml
custom:
  device: cuda
  is_half: true
  version: v5dev
  t2s_weights_path: GPT_SoVITS/pretrained_models/s1v3.ckpt
  vits_weights_path: GPT_SoVITS/pretrained_models/gsv-v5-pretrained/s2Gv5dev.pth
  bert_base_path: GPT_SoVITS/pretrained_models/chinese-roberta-wwm-ext-large
  cnhuhbert_base_path: GPT_SoVITS/pretrained_models/chinese-hubert-base
```

训练后把配置中的路径换成实际文件，例如
`Weights/GPT/v5dev/myvoice-e15.ckpt` 和 `Weights/SoVITS/v5dev/myvoice_e2_s100_l32.pth`。
这些是示例文件名，必须以实际输出为准。重启 API 后生效。
配置指向不存在的权重时当前代码可能回退到底模，启动时应检查打印的加载路径。

准备自己的 3～10 秒干净参考录音 `ref_audios/myvoice.wav`，然后在另一个终端调用：

```powershell
$ttsBody = @{
    text = "你好，这是我自己的语音合成服务。"
    text_lang = "zh"
    ref_audio_path = "ref_audios/myvoice.wav"
    prompt_lang = "zh"
    prompt_text = "替换为参考录音实际说出的完整文字。"
    media_type = "wav"
    streaming_mode = $false
    batch_size = 1
} | ConvertTo-Json

Invoke-WebRequest -Uri "http://127.0.0.1:9880/tts" -Method Post `
    -ContentType "application/json; charset=utf-8" `
    -Body ([System.Text.Encoding]::UTF8.GetBytes($ttsBody)) `
    -OutFile ".\output\tts-result.wav"
```

调用前执行 `New-Item -ItemType Directory -Force output, ref_audios`，并放入参考录音。
参考路径是 API 电脑上的路径，
不是客户端文件上传；v5 要求参考音频和非空参考文字。
成功返回音频，参数错误通常返回 HTTP 400 和 JSON，完整参数查看
`http://127.0.0.1:9880/docs` 或根目录 `api_v2.py`。
个人服务先保持单进程、串行请求；切换权重时两种权重都要对应自己的实验。

## 检查与排障

```powershell
.\.venv\Scripts\python.exe --version
.\.venv\Scripts\python.exe -m pip check
.\.venv\Scripts\python.exe -c "import torch; print(torch.__version__, torch.version.cuda, torch.cuda.is_available()); print(torch.cuda.get_device_name(0)); print((torch.ones(1, device='cuda') + 1).item())"
ffmpeg -version
ffprobe -version
```

预期为 Python 3.12、Torch 2.7.1+cu118、CUDA 11.8、GPU 可用，运算结果 `2.0`。

| 情况 | 处理 |
| --- | --- |
| GPU 不可用或误用 Python 3.13 | 确认使用 `.venv/Scripts/python.exe`，检查驱动和 Torch 版本 |
| FFmpeg 找不到 | 当前环境、项目 runtime、根目录或系统 PATH 中提供可执行文件 |
| 训练显存不足 | 停止其他训练/推理，降低 batch，排查过长切片 |
| G2PW 缺失或 ONNX CUDA DLL 报错 | 重新运行安装脚本补齐数据/依赖，重启 Python 进程；DLL 初始化在 `tools/portable_runtime.py` |
| 模型列表没有训练结果 | 确认小模型保存开启，文件位于 `Weights` 对应版本目录，再刷新列表 |
| 端口占用 | API 可用 `-p` 更换端口；WebUI 端口定义在 `config.py` |
| 参考音频不存在 / 文字为空 | 使用服务端真实路径，填写录音对应的文字 |

`NLTK_DATA` 可由调用方指定，否则使用当前环境的 `nltk_data`，存在旧 runtime 数据时兼容回退。
`CUDAGraph=0` 可禁用 CUDA Graph；FlashAttention 不可用时可回退到 Torch 路线。
加速机制参见 [Accel 说明](../GPT_SoVITS/Accel/README.md)。

无需激活环境，直接调用 `.venv/Scripts/python.exe` 即可；IDE 也选择该解释器。

## 验证范围

以下保留 2026-10-12 的既有本机验证记录（RTX 4070 Ti SUPER 16GB）；
本次文档整理未重新执行环境安装、训练或合成：

- 全新本地环境安装及 `pip check`；Python 3.12.15、Torch/torchaudio 2.7.1+cu118。
- 六个预训练权重的 ZIP CRC 检查，以及 v5dev、vocoder、BERT、HuBERT 实际加载。
- CUDA 张量运算、FlashAttention 能力检测、中文文本特征提取；G2PW 会话包含 CUDA provider。
- WebUI `/config` 和 v5 API `/docs` 的 HTTP 启动检查。
- 新目录中的小型测试权重保存、读取及模型扫描；WebUI 没有重新创建旧根目录。

尚未执行真实录音的 ASR、完整训练、真实参考音频的 TTS 合成或音质评估，
也未实测 v5turbo 加载与推理、CUDA Graph 捕获。训练参数表是起步建议。
本机验证脚本、安装快照和日志位于被忽略的 `env`；全新克隆不包含它们。
