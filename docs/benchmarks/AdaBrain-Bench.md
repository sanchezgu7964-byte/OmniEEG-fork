# AdaBrain-Bench

版本：2026-11-13，基于已读取公开来源。

## 要解决的问题与评价对象

参考跨被试、多被试、少样本适配的定义和基线组织。

## 实验组织

13个数据集/7类应用，包含分类、回归、检索；官方README有多种设置表。

## 回归任务证据（SEED-VIG，2026-11-14 补充）

AdaBrain-Bench 唯一的回归任务是 SEED-VIG（警觉度估计，17 ch、8 s、21 名被试，指标 Pearson 相关与 R²）。论文 Table 2 / 官方 README“Cross-Subject Transfer”表，**跨被试、基础模型全量微调**：

| 模型 | Corr (%) | R² (%) |
|---|---|---|
| EEGNet | 58.34 | 26.65 |
| LDMA | 57.22 | 11.15 |
| ST-Tran | 49.19 | 3.98 |
| Conformer | 52.11 | 2.55 |
| BIOT | 62.98 | **27.09** |
| EEGPT | 57.83 | 23.47 |
| LaBraM | **65.52** | 25.35 |
| CBraMod | 60.47 | **2.40** |

可直接读出的事实：

- 所有模型的跨被试 R² 都不超过 0.27；基础模型没有明显超过 EEGNet（0.267）。
- CBraMod 相关系数 0.60，R² 却只有 0.024：预测值与真实值相关，但尺度或偏移不对。R² 与相关系数的这种背离，提示存在被试间的整体偏移或尺度差异（这是推测，表中无法直接验证）。
- 同一任务在 CBraMod 原论文（按被试编号划分）中 R² 为 0.337，在本表中为 0.024，再次说明协议依赖。
- 局限：只有一个回归数据集，不足以单独支撑“回归任务普遍泛化不足”的一般性结论。

来源：[AdaBrain-Bench（arXiv v2）](https://arxiv.org/html/2507.09882v2) Table 2（caption：“The brain foundation models are fully fine-tuned”）；本地 `research/reve_route_20261113/sources/adabrain.txt`、`adabrain_readme.md`。

## 与本赛事的关系

当前官方表没有REVE，不能由该表判断REVE弱项；不计算混合指标的自制总分。

## 阅读与复现检查点

记录数据集与任务定义、被试隔离、预处理、适配方式、调参预算、种子作用、指标及预训练重叠处理。相同数据集名称并不足以保证分数可比。

## 来源

- [AdaBrain-Bench（arXiv v2，按预印本引用）](https://arxiv.org/html/2507.09882v2)。
- [AdaBrain-Bench 官方结果表](https://github.com/Jamine-W/AdaBrain-Bench)。

[逐项证据与协议边界](评测证据与可比性.md) · [返回索引](README.md)
