# Windows 本地 .venv（CUDA 11.8）

本项目使用 Python 3.12、PyTorch 2.7.1+cu118、torchaudio 2.7.1+cu118。
在项目根目录执行以下命令可创建或补齐环境，不需要 Conda：

```powershell
powershell -ExecutionPolicy Bypass -File .\setup-venv.ps1
```

国外下载源可添加 `-Source Overseas`。已有 `.venv` 会复用，脚本不会覆盖其他 Python 版本的环境。
Python 本体位于 `env/python`，工具和下载缓存位于 `env`；请保留 `env/python`，`.venv` 依赖它。
`env`、`.venv` 均已被 Git 忽略。

启动训练 WebUI：

```powershell
.\.venv\Scripts\python.exe webui.py zh_CN
```

打开 `http://127.0.0.1:9874`，选择已经下载的 `v5dev` 或 `v5turbo`。
`go-webui.bat` / `go-webui.ps1` 也会优先使用 `.venv`。

用 v5dev 底模启动 API：

```powershell
.\.venv\Scripts\python.exe api_v2.py -a 127.0.0.1 -p 9880 -c GPT_SoVITS/configs/tts_v5.yaml
```

该配置文件如果不存在，可创建为：

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

v5 还需要 `GPT_SoVITS/pretrained_models/gsv-v5-pretrained/vocoder.pth`。
训练后将配置中的 GPT、SoVITS 路径换为自己的权重；LoRA 推理仍需保留对应底模。
请求 `/tts` 时提供服务端可读的参考音频路径和对应文字。

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

其他版本同样按版本名分目录。API 配置中的路径例如
`Weights/GPT/v5dev/myvoice.ckpt` 和 `Weights/SoVITS/v5dev/myvoice.pth`。
下载的底模仍放在 `GPT_SoVITS/pretrained_models`，训练中间数据和断点仍放在 `logs`。
`Weights` 已被 Git 忽略。

FFmpeg、ffprobe 从当前 Python 环境、项目 runtime、项目根目录或系统 PATH 查找。
安装脚本补齐 G2PW、NLTK 和 fastText 语言识别数据；ASR 模型在首次使用时另行下载。

无需激活环境，直接调用 `.venv/Scripts/python.exe` 即可；IDE 也选择该解释器。
