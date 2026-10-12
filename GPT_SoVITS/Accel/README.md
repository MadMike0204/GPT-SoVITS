# Accel 推理加速说明

本目录提供 GPT 文本到语义序列（AR）的可选推理加速，不替代 SoVITS 或声码器。
本仓库的 Windows `.venv` 安装、训练及 API 用法见
[自用指南](../../docs/windows.md)。

## 结构与依赖

- `PyTorch/`：Torch SDPA、FlashAttention 与 CUDA Graph 后端。
- `MLX/`：Apple silicon 后端，本机 Windows 配置不使用。
- `adapter.py`：加载 GPT 权重、选择后端、管理引擎及批量请求。
- `../../tools/acceleration.py`：根据设备、精度和开关检测加速能力。
- `../../tools/portable_runtime.py`：初始化 DLL 搜索路径、FFmpeg、NLTK 与 Transformers 兼容逻辑。
- `vendor/cuda/bin/`：Windows FlashAttention 需要的附带 CUDA DLL。

Windows/Python 3.12 的依赖清单位于根目录
[`requirements-py312-win-flash_attention`](../../requirements-py312-win-flash_attention)。
本地 CUDA 11.8 使用 `setup-venv.ps1` 安装匹配的 Torch 和依赖，不需要外置补丁 ZIP。
其中预编译 FlashAttention wheel 仅适用于对应的 Windows/CPython/Torch 组合，
不能直接用于 Python 3.9 或 Linux。

## 加速路线

FlashAttention 与 CUDA Graph 分别检测，按实际设备、dtype 和用户开关选择。
以下表格描述非 token 流式 AR 的选择逻辑：

| FlashAttention 可用且开启 | CUDA Graph 有效且开启 | 路线 |
| --- | --- | --- |
| 是 | 是 | FlashAttention + Graph |
| 是 | 否 | FlashAttention eager |
| 否 | 是 | Torch SDPA Graph |
| 否 | 否 | 普通 AR |

FlashAttention 要求 CUDA、FP16/BF16、GPU compute capability 至少 8.0，
并且模块提供 `flash_attn_with_kvcache`。CUDA Graph 要求 CUDA 和相关 Torch 接口；
能力检测通过不代表实际捕获成功。

普通推理子 WebUI 使用单句 `bs=1`；主界面勾选“启用并行推理版本”后，
快速子 WebUI 使用批量参数。两个界面的 `CUDA Graph` 和 `flash_attn` 控件
按能力显示、默认开启或隐藏，也可独立关闭。设置环境变量 `CUDAGraph=0`
会禁用 Graph。API 保留 `parallel_infer`，真正 token 流式走原实现。

Graph 捕获失败时，FlashAttention 可继续 eager；Torch Graph 路线退回普通 AR。
适配器记录捕获失败状态，避免同一引擎反复尝试。设备、精度或权重改变时需重建引擎。
加速能力缺失可回退，权重加载和实际推理错误仍需排查。

## Windows DLL 初始化

当前 cu118 清单中的 ONNX Runtime GPU 1.18.0 使用 CUDA 11/cuDNN 8，
与 Torch 2.7.1 自带的 cuDNN 9 不同。清单额外安装 NVIDIA cu11/cuDNN 8 依赖，
位于当前环境的 `Lib/site-packages/nvidia/*/bin`。

`tools/portable_runtime.py` 从 `sys.prefix` 定位环境，注册现存的 Torch、NVIDIA
和 vendor DLL 目录，并加入当前进程的 PATH，支持 cuDNN 加载组件 DLL。
这适用于 `.venv` 和整合包 `runtime`，不修改系统 PATH 或 CUDA Toolkit。
G2PW 和 UVR5 的 FoxJoy ONNX 会话复用初始化逻辑；修复依赖后应重启 Python 进程。

## 本机验证范围

本机环境及验证结果统一记录在
[自用指南的验证范围](../../docs/windows.md#验证范围)。
上述能力表描述代码选择逻辑，实测范围以该记录为准。
