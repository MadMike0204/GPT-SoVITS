# F5-TTS 骨干网络

本目录保留 F5-TTS 的 `dit.py` 骨干网络实现，供模型代码使用。
来源与完整模型说明见 [SWivid/F5-TTS](https://github.com/SWivid/F5-TTS)。

| 文件 | 结构与输入 |
| --- | --- |
| `dit.py` | 使用 AdaLN-Zero 的 DiT；时间步作为条件，将带噪输入、掩码条件和文本嵌入拼接后投影，支持长跳跃连接 |

日常训练和推理从项目 WebUI/API 进入，操作见 [自用指南](../../../../docs/windows.md)。
