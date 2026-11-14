# JEPA-Anything：研究问题、架构与训练逻辑

> 版本：2026-11-14 / 论文笔记 v0.1（**阅读不完整**）。依据 arXiv HTML v1 正文至 §3.4.1（逐字）、abs 页面与 GitHub README；§3.4.2 之后、附录 A–B（含 λ、γ、EMA 动量等超参数）**未逐字核对**。由 web-fetch 代理读取后整理，未本地保存原文。统一记号见[阅读约定](../process/文档维护与阅读约定.md)。

## 1. 作者要解决的问题

在不预设领域语义的前提下，让 JEPA 式预测模型学到可解释的潜在因子，并在多个“世界”（视觉、单细胞、临床、动力系统、控制、分子等）中通用。核心是**正交预测分解（Orthogonal Predictive Factorization, OPF）**。

## 2. OPF 的定义（论文）

- 目标潜变量 $\tilde z_t=\mathrm{sg}(z_t)$ 来自 EMA 目标编码器（$\bar\theta\leftarrow m\bar\theta+(1-m)\theta$）；
- 维度 $d$ 分成 $K$ 个块（$K\cdot r=d$），每块一个**可学习投影** $P_k\in\mathbb R^{d\times r}$：$z^{(k)}_t=P_k^\top\tilde z_t$；
- 每个因子有自己的预测器 $q_k$（独立或共享主干 + 分支头），预测值拼接后经 $(P^\top)^\dagger$ 合成回完整潜变量；
- **正交损失**（式 7，软约束）：

$$\mathcal L_{orth}=\sum_k\|P_k^\top P_k-I_r\|_F^2+\sum_{i<j}\|P_i^\top P_j\|_F^2$$

- 因子身份**不预设**（“由预测学习中涌现”），可解释性只能事后用探测验证；
- 多数实验 $K=4$。

## 3. 总目标（论文）

$$\mathcal L_{OPF}=\mathcal L_{pred}+\lambda_{orth}\mathcal L_{orth}+\lambda_{fac}\mathcal L_{fac}+\lambda_{enc}\mathcal L_{enc},\qquad\mathcal L_{train}=\mathcal L_{base}+\mathcal L_{OPF}$$

- $\mathcal L_{pred}$：每个因子回归到其 EMA 目标因子（MSE）；
- $\mathcal L_{fac}$、$\mathcal L_{enc}$：分别对目标因子、在线编码器输出的逐维标准差加 hinge，防止坍缩（形式类似 VICReg 的方差项，论文未这样称呼）；
- $\mathcal L_{base}$：各领域原有的损失（例如单细胞领域的 Cell-JEPA 还保留 mask 基因重建）。**即 OPF 是叠加在原有目标之上的附加项。**
- λ、γ、$m$ 的具体取值未核实（代理在摘要中见到 λ_orth=0.10、λ_fac=0.05、λ_enc=0.02 的“典型值”，未逐字核对）。

## 4. 实验与证据强度

- 与“同数据、同骨干、同预算、只换目标”的标准 JEPA 对比：视觉绑定（差距约 0.01，无标准差）、单细胞（PBMC 微调 0.783 → 0.830）、CITRIS 干预预测（单干预一步误差 −34.8%）、PDE / 天气（Burgers 6 步 0.00637 → 0.00401）、分子轨迹 RMSD 略降；
- **较弱或相反的结果**：Hopper 控制中标准 JEPA 更好；参数匹配的 Burgers 实验中增益随预测步长从 −5.8% 缩小到 −3.2%；
- **正交项本身的消融不足**：唯一直接相关的是几何审计（Table 5：正交化后因子重叠约 5e-16、条件数约 1），它只说明投影基不重叠，**没有**显示“λ_orth=0 时预测变差”；增益无法与多头预测器、其他正则项分开。
- **没有任何 EEG / 生理信号实验**；最接近的是规则采样的 PDE / 天气场和不规则采样的临床记录。

## 5. 发表与代码

arXiv:2609.20800v1（2026-09-17，cs.CL），13 位作者（Taoyong Cui … Ling Yang），无会议信息。代码 github.com/Gen-Verse/JEPA-Anything（Apache-2.0），但 README 说明**不含各领域数据与训练好的权重，无法复现论文结果**。

## 6. 与本项目想法的关系（助手推断，需用户判断）

- OPF 的因子是**学出来的**，不对应任何预设的“时域 / 频域”含义；若要让某个子空间专门承载频域信息，需要额外设计（例如不同子空间对应不同的预测目标），这是论文没有做过的；
- 正交是**投影基的几何正交**，不等于两个因子携带的信息互不冗余；
- 因子含义只能事后用探测检验（论文用岭回归探测），与用户计划的 PCA / 多项式读出探测思路一致。

## 原文与证据

- [JEPA-Anything（arXiv v1）](https://arxiv.org/abs/2609.20800)；[HTML 版](https://arxiv.org/html/2609.20800)；[代码](https://github.com/Gen-Verse/JEPA-Anything)。

- [返回论文索引](README.md)
