# LocaLeJEPA：研究问题、架构与训练逻辑

> 版本：2026-11-14 / 论文笔记 v0.1（**只读了 README 与 arXiv 摘要，论文正文未读**）。PDF 约 39 MB 超出读取上限；paperswithcode 页面受网络限制未能访问。下文关于方法的内容来自 README 的项目说明，不是论文公式。统一记号见[阅读约定](../process/文档维护与阅读约定.md)。

## 1. 作者要解决的问题

LeJEPA 用一个分布匹配正则（SIGReg）把整个 batch 的嵌入推向**各向同性高斯**，以防止表示坍缩。作者认为这一“全局”目标隐含了“嵌入空间是欧氏的、数据整体是一个各向同性区域”的几何先验；而流形只是**局部**近似欧氏。因此改为在局部邻域内做分布匹配。

## 2. 方法（README）

- 每个训练步对 batch 嵌入做 **k-means**，分成至多 $K$ 个邻域；过小的簇跳过，全部跳过时退回全 batch 检验；
- 每个邻域**减去自己的均值后**，匹配到一个**球内均匀分布**（不是高斯）；邻域之间的位置不受约束，只约束内部分布；
- 损失：$(1-\lambda)\cdot\text{invariance}+\lambda\cdot\text{local\_ballreg}$，invariance 项把同一图像的各视图拉向其均值；
- 主要超参数：λ=0.1、K=4（LeJEPA 用 λ=0.02）；默认 256 个随机投影；
- 支持欧氏 ViT、双曲输出 ViT、旋转/翻转等变 ResNet-50。

## 3. 实验与证据强度（README）

- 只在视觉上做：ImageNet-1K 预训练、7 个下游数据集线性探测；
- ViT-S/8 100 epoch：线性探测 40.7% → 49.6%，k-NN 24.3% → 34.1%；README 称各骨干线性探测提升 6.6–9.4 个点；
- **作者自己的注意事项**：两种方法用了**不同的训练配方**（学习率、warmup、梯度裁剪），部分提升可能来自优化；在 LeJEPA 的学习率下局部匹配会坍缩；“减均值”与“球形目标”两者的作用没有分开；k-means 只看每步的小 batch，结果依赖 batch 大小；头条数字为单次预训练；
- **没有时间序列或生理信号实验**。

## 4. 发表与代码

arXiv:2610.28458v1（2026-10-20，cs.LG），作者 Kartik Tandon、Alessio Borgi 等 11 人（含 Randall Balestriero）；README 中 BibTeX 标题与 arXiv 标题不一致。代码 github.com/alessioborgi/LocaLeJEPA（MIT），README 未提及发布权重。

## 5. 与本项目的关系（助手推断，需用户判断）

- 它解决的是**防坍缩正则的几何形状**问题，不是时域 / 频域分解问题；
- 用到 EEG 时，batch 内 k-means 的邻域可能主要按**被试身份**聚类，而不是按任务相关的状态聚类，需要谨慎设计采样；
- 与 JEPA-Anything 的关系：两者都是在 JEPA 目标上加正则，作用对象不同（一个约束子空间的正交性，一个约束嵌入分布的局部形状）。

## 原文与证据

- [LocaLeJEPA（arXiv v1 摘要）](https://arxiv.org/abs/2610.28458)；[代码](https://github.com/alessioborgi/LocaLeJEPA)；README 链接的 LeJEPA 原文 arXiv:2511.08544（未读）。

- [返回论文索引](README.md)
