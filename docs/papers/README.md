# 论文笔记

每篇文档解释研究问题、输入输出、模块连接与训练逻辑；模型借鉴意见在各篇末尾，研究选型在独立文档更新。

- [REVE](REVE.md)：主基线。
- [CBraMod](CBraMod.md)：主要结构参照。
- [CSBrain](CSBrain.md)：多尺度与区域建模参照。
- [FAME](FAME.md)：频谱目标候选。
- [EEGPT](EEGPT.md)：表征预测候选。
- [BrainOmni](BrainOmni.md)：传感器与tokenizer参照。
- [NeuroLM](NeuroLM.md)：多任务语言化参照。
- [UniMind](UniMind.md)：任务相关读出参照。
- [ECHO](ECHO.md)：上下文适配参照。
- [LaBraM](LaBraM.md)：必要强基线。
- [BIOT](BIOT.md)：频域及临床专长参照。
- [BENDR](BENDR.md)：对比预测与临床基线。
- [EEGNet](EEGNet.md)：必要监督基线。
- [EEG Conformer](EEG_Conformer.md)：必要监督与局部时序参照。

2026-11-14 起，14 篇笔记均更新为 v0.2：按[阅读约定](../process/文档维护与阅读约定.md)的 8 条要求，逐篇写明研究问题与已证明事实的区分、输入输出与张量形状、逐步前向计算、训练阶段与超参数、实验与消融（含协议差异和可比性提醒）、局限与未读懂之处、与本赛题规格的事实对照，以及留给讨论的问题。

仍需注意：

- 全部笔记都**没有做代码级核对或本地复现**；
- EEG Conformer 的论文原文未保存，笔记依据作者 README 与公开代码；
- BIOT 的附录来自 `biot.html`（txt 版缺附录）；
- 各篇的“与赛题规格对照”只列事实，不构成路线选择。
