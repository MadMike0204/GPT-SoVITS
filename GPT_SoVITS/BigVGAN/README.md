# BigVGAN 声码器

本目录来自 [NVIDIA/BigVGAN](https://github.com/NVIDIA/BigVGAN)，
用于将梅尔频谱转换为音频波形。本项目的 v3 推理使用此组件；
v4/v5 加载各自模型目录中的 `vocoder.pth`。

## 在本项目中使用

v3 权重目录为 `GPT_SoVITS/pretrained_models/models--nvidia--bigvgan_v2_24khz_100band_256x`。
按上游模型结构保留配置和权重文件，推理入口负责加载。
v5 的模型准备参见 [自用指南](../../docs/windows.md#模型与目录)。

本目录是集成代码，不包含上游完整的训练、演示及基准测试工程。
独立训练、其他预训练模型和自定义 CUDA 内核说明请查阅
[上游文档](https://github.com/NVIDIA/BigVGAN#readme)。

## 来源与许可证

BigVGAN 由 NVIDIA 发布，许可证见 [LICENSE](LICENSE)；
引入实现的其他许可证位于 [incl_licenses](incl_licenses)。
