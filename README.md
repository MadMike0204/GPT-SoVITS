# GPT-SoVITS 中文自用版

用于 Windows 本机的个人音色微调与 TTS 服务，沿用 Python、Gradio 和 FastAPI。
本机配置为 Python 3.12、PyTorch/torchaudio 2.7.1+cu118，所有命令在项目根目录执行。

## 快速开始

首次安装或补齐依赖：

```powershell
powershell -ExecutionPolicy Bypass -File .\setup-venv.ps1
```

安装脚本不会下载 TTS 底模或 FFmpeg；先按 [模型与目录](docs/windows.md#模型与目录)
准备所需模型，并安装 FFmpeg/ffprobe。

日常启动中文 WebUI：

```powershell
.\.venv\Scripts\python.exe webui.py zh_CN
```

打开 <http://127.0.0.1:9874>。也可双击 `go-webui.bat`，或运行 `go-webui.ps1`。
界面初始版本为 **v2Pro**，使用 v5 前先切换到已下载底模的 **v5dev** 或 **v5turbo**。

自己的录音按「切分 → ASR → 校对 → 训练集格式化 → SoVITS/GPT 微调 → 推理试听」处理，
步骤和起步参数见 [训练流程](docs/windows.md#训练流程)。

## 文档入口

| 需要做什么 | 查看哪里 |
| --- | --- |
| 安装环境、下载模型 | [Windows 自用指南](docs/windows.md#环境安装) |
| 用自己的录音训练 | [训练流程](docs/windows.md#训练流程) |
| 启动服务并调用 `/tts` | [TTS API 配置与请求示例](docs/windows.md#tts-api) |
| 检查 GPU、DLL、模型和端口问题 | [检查与排障](docs/windows.md#检查与排障) |
| 查看已有实测与未验证内容 | [验证范围](docs/windows.md#验证范围) |
| 了解 FlashAttention、CUDA Graph 与 DLL 加载 | [推理加速说明](GPT_SoVITS/Accel/README.md) |

API 默认使用 <http://127.0.0.1:9880>，启动后完整接口参数见 <http://127.0.0.1:9880/docs>。
首次使用需按指南创建配置文件并准备参考录音。

## 目录速查

| 路径 | 用途 |
| --- | --- |
| `.venv/` | 项目虚拟环境；使用其中的 `Scripts/python.exe` |
| `env/` | Python 本体、安装工具及缓存；`.venv` 依赖 `env/python` |
| `GPT_SoVITS/pretrained_models/` | 下载的底模、BERT、HuBERT 和声码器 |
| `Weights/GPT/<版本>/` | 训练导出的 GPT 权重（`.ckpt`） |
| `Weights/SoVITS/<版本>/` | 训练导出的 SoVITS 权重（`.pth`）；v5 LoRA 仍需对应底模 |
| `logs/<实验名>/` | 训练中间数据与断点 |
| `output/`、`ref_audios/` | 自己的录音、切片、标注和合成结果 |
| `GPT_SoVITS/configs/` | 训练/API 配置；其中 YAML 默认被 Git 忽略 |

录音、模型和环境属于本地数据。训练保存与推理扫描目录统一由 `config.py` 映射。

## 组件说明与来源

按需查看：[中文文本规范化](GPT_SoVITS/text/zh_normalization/README.md)、
[BigVGAN 声码器](GPT_SoVITS/BigVGAN/README.md)、
[F5-TTS 骨干网络](GPT_SoVITS/f5_tts/model/backbones/README.md)、
[AP-BWE 音频超分](tools/AP_BWE_main/README.md)。

项目基于 [RVC-Boss/GPT-SoVITS](https://github.com/RVC-Boss/GPT-SoVITS)，
上游版本说明和历史更新可在 [上游中文文档](https://github.com/RVC-Boss/GPT-SoVITS/blob/main/docs/cn/README.md)
与 [更新日志](https://github.com/RVC-Boss/GPT-SoVITS/blob/main/docs/cn/Changelog_CN.md) 查阅。
许可证见 [LICENSE](LICENSE)，各引入组件的许可证保留在对应目录。
