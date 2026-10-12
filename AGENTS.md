# 项目工作约定

本仓库用于 Windows 本机的个人音色微调与 TTS 服务，沿用 Python/Gradio/FastAPI。

- 文档仅维护中文自用说明；根 README 提供快速入口，详细操作写入 `docs/windows.md`，不恢复多语言介绍、重复安装指南或上游历史日志。
- 使用 `.venv/Scripts/python.exe`；环境为 Python 3.12、PyTorch/torchaudio 2.7.1+cu118。
- 环境安装入口为 `setup-venv.ps1`，不使用系统 Python 3.13 或 Conda。
- `env/python` 是 `.venv` 引用的 Python 本体，不能当成下载缓存清理。
- CUDA DLL 路径从 `sys.prefix` 推导，兼容 `.venv` 与整合包 `runtime`。
- `config.py` 是训练权重目录的唯一映射来源：`Weights/{GPT,SoVITS}/<版本>`。
- 修改权重目录时同步训练保存、推理扫描、界面提示与文档；不恢复根目录旧目录。
- 预训练模型放在 `GPT_SoVITS/pretrained_models`；v5 LoRA 推理必须保留对应底模。
- 录音、模型、`.venv`、`env`、`Weights`、`logs` 都属于本地数据，不提交大型文件。
- `GPT_SoVITS/configs/*.yaml` 默认被忽略；文档中的 API 配置必须能在全新克隆中重建。
- WebUI 初始版本仍为 v2Pro，使用 v5 前明确切换版本。
- 训练参数建议与实测结果分开记录；环境加载通过不代表训练或音频合成通过。
- Git 提交由用户自行执行。
- 结构查询优先 CodeGraph；显式传入当前项目的绝对 `projectPath`，不用子代理重复探索。

## 文档入口

- [中文快速入口](README.md)
- [安装、训练、API、排障及验证范围](docs/windows.md)
- [推理加速与 DLL 机制](GPT_SoVITS/Accel/README.md)
