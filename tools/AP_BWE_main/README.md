# AP-BWE 音频带宽扩展

本目录来自 [yxlu-0102/AP-BWE](https://github.com/yxlu-0102/AP-BWE)，
通过并行预测幅度谱与相位谱扩展音频高频。
本项目由 `tools/audio_sr.py` 调用，用于 v3 音频的可选 24kHz → 48kHz 超分。

## 模型准备

从 [上游预训练权重](https://drive.google.com/drive/folders/1IIYTf2zbJWzelu4IftKD6ooHloJ8mnZF?usp=share_link)
下载以下文件并放入 `tools/AP_BWE_main/24kto48k/`：

- `g_24kto48k.zip`：模型权重，保持该文件名。
- `config.json`：配套配置。

v3 合成音频偏闷时可尝试启用超分；v4/v5 原生使用 48kHz 声码器。
Windows 环境与日常推理操作见 [自用指南](../../docs/windows.md)。

## 来源与许可证

作者为 Ye-Xin Lu、Yang Ai、Hui-Peng Du、Zhen-Hua Ling。
论文：[Towards High-Quality and Efficient Speech Bandwidth Extension with Parallel Amplitude and Phase Prediction](https://arxiv.org/abs/2401.06387)。
许可证见 [LICENSE](LICENSE)。独立训练、数据集准备和性能数据请查阅上游项目；
本目录不包含上游文档中的完整训练工程。
