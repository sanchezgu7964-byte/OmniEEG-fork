// OmniEEG Challenge 2026 初赛研究方案
// 方案标题：先诊断，后改进：面向跨任务 EEG 基础模型的频段正交子空间预测学习
// 编译：python3 -c "import typst; typst.compile('docs/report/proposal.typ', output='docs/report/proposal.pdf')"

#set document(
  title: "先诊断，后改进：面向跨任务 EEG 基础模型的频段正交子空间预测学习",
  author: ("参赛成员"),
)

#set page(
  paper: "a4",
  margin: (top: 2.2cm, bottom: 2.2cm, left: 2cm, right: 2cm),
  numbering: "1",
  number-align: center,
)

#set text(font: ("New Computer Modern", "Noto Serif CJK SC"), size: 10.5pt, lang: "zh")
#set par(leading: 0.72em, first-line-indent: 2em, justify: true)
#set heading(numbering: "1.1")

#show heading: it => {
  set text(font: ("New Computer Modern", "Noto Sans CJK SC"))
  set par(first-line-indent: 0em)
  v(0.5em)
  it
  v(0.25em)
}

#show heading.where(level: 1): it => {
  set text(size: 13pt, weight: "bold")
  v(0.7em)
  it
  v(0.35em)
}

#show heading.where(level: 2): it => {
  set text(size: 11.5pt, weight: "bold")
  it
}

#show figure.caption: it => {
  set text(size: 9pt)
  it
}

// ── 封面 ──

#align(center)[
  #v(2.5cm)
  #text(size: 20pt, weight: "bold", font: ("New Computer Modern", "Noto Sans CJK SC"))[
    先诊断，后改进：面向跨任务 EEG 基础模型的#linebreak()频段正交子空间预测学习
  ]

  #v(1.2cm)
  #text(size: 12pt)[
    OmniEEG Challenge 2026 · 主赛道（覆盖全部 7 个分赛道）
  ]

  #v(1cm)
  #text(size: 11pt)[
    队伍名称：#underline[#h(6em)] \
    参赛成员：#underline[#h(6em)]
  ]

  #v(2cm)
  #text(size: 11pt, fill: luma(100))[
    2026 年 11 月
  ]
]

#pagebreak()

// ══════════════════════════════════════════════
// 1  赛道选择与研究动机
// ══════════════════════════════════════════════

= 赛道选择与研究动机

== 为什么选主赛道

本赛事的 7 个分赛道覆盖信号可靠性、疾病诊断、睡眠分期、认知与情绪、自然刺激解码、运动想象和 SSVEP。14 个下游数据集的通道数从 4 到 128，时长从 1 秒到 30 秒。分赛道考察的是"某一类任务做得好不好"；主赛道考察的是*同一个基础模型能否同时服务于性质差异很大的任务*。后者正是"基础模型"这一概念成立的前提，也是我们想研究的问题，因此选择主赛道。

== 问题的由来：从专用模型到基础模型

#par(first-line-indent: 0em)[*专用模型的局限。*]
传统 EEG 解码针对每种范式单独设计预处理、特征和分类器。EEGNet 等紧凑 CNN 把"滤波器组 + 空间滤波"写进网络结构，能跨范式使用，但每个模型绑定一种通道配置（空间卷积核大小等于通道数），不能跨布局迁移，也没有利用大规模无标注数据。

#par(first-line-indent: 0em)[*EEG 数据本身的困难。*]
EEG 信噪比低；不同数据集的导联数、电极位置、参考方式、时长和采样率高度异构；被试之间差异大；功率谱大致服从 $1\/f^alpha$，能量集中在低频；有标注的数据量通常只有几十小时。

#par(first-line-indent: 0em)[*基础模型的回应。*]
为此出现了一系列在大规模无标注 EEG 上预训练的基础模型，例如：BIOT 把逐通道片段拉平成序列；LaBraM 用神经 tokenizer 预测离散码；CBraMod 的 criss-cross 注意力把空间与时间分开建模；REVE 用电极坐标的 4D Fourier 位置编码支持任意布局，并在约 6 万小时数据上预训练；FAME 把重建目标改为按频段标准化的时频活动。

== 基础模型仍然存在的问题

我们认为当前 EEG 基础模型最大的问题是：*准确率不稳定、表征空间缺乏可解释性、泛化能力没有被明确验证、下游评测困难*。归结起来，领域缺少对三件事的诊断：模型学到了什么，哪些设计真正在起作用，评测数字代表什么。下面逐条给出公开证据。

#par(first-line-indent: 0em)[*(1) 准确率：并不稳定地超过专用小模型。*]

NeuralBench 的同一快照中，REVE 在运动想象（68.0%，第 1）和 SSVEP（96.1%，第 2）上很强；但在精神分裂症识别上只有 43.7%，最佳专用网络 ATCNet 为 72.9%；癫痫检测 77.6%，BDTCN 为 85.5%。基础模型的优势随任务而异，"更大、更多数据"并不自动带来全面提升。LaBraM 的数据量实验中，Base 模型用 500 小时在 TUAB 上反而超过 2500 小时；FAME 报告扩大数据或规模后下游表现不稳定提升。

#figure(
  image("figures/fig_neuralbench_reve_gap.png", width: 95%),
  caption: [NeuralBench 统一微调协议下，REVE 与各任务最佳模型的差距。只含以平衡准确率为指标的任务，按差距排序；右侧标注差距 ≥ 3 个百分点的最佳模型与差值。数据：NeuralBench 官方结果（提交 fe31393）。],
) <fig-gap>

#par(first-line-indent: 0em)[*(2) 表征：冻结表示普遍偏弱，学到了什么并不清楚。*]

多个模型的作者承认，下游需要全量微调，冻结表示不够用：LaBraM 在 TUEV 上线性探测 0.346，全量微调 0.641；CBraMod 冻结后 PhysioNet-MI 只有 0.385；BrainOmni 冻结后 TUEV 从 0.618 降到 0.489。FAME 指出，现有预训练编码器普遍存在*低频偏置*：表示对高频成分的可恢复性更差，其机制是时域 MSE 重建按功率给各频率加权。

REVE 的同一个模型换用不同读出方式（池化与不池化）后，各任务结果差异明显（REVE Table 4）。FAME 的最佳读出层是第 9 层而非最后一层。这说明下游表现差，可能部分来自*读出*而不全是*表征*本身。目前没有工作系统地区分这两者。

Neuro-KE（NeurIPS 2026）也指出，原始 EEG 没有规范的 token 语义，模型可能保留了波形细节却丢掉了有生理意义的结构；它把无需人工标注的 EEG 描述子转成掩码预训练的数值目标，在 12 个数据集、3 种骨干上相对只做重建平均提高 BAcc 2.60 个百分点。这说明"把领域知识写进预训练目标"是有效的方向。

基础模型是否学到了不同时间、空间尺度的表征，是否包含并超出已知的神经科学先验（例如频段、节律、脑区分工），目前缺乏直接检验。

#grid(
  columns: (1fr, 1fr),
  gutter: 8pt,
  figure(
    image("figures/related/FAME_fig3.png", width: 100%),
    caption: [现有预训练编码器偏向低频（图源：FAME Fig. 3）。],
  ),
  figure(
    image("figures/fig_reve_readout.png", width: 100%),
    caption: [REVE-Base 同一冻结表示，只换读出方式（线性探测）。数字为"不池化 − 池化"，只标注差值 ≥ 5 的任务。数据：REVE Table 4。],
  ),
)

#par(first-line-indent: 0em)[*(3) 泛化：跨被试、回归和零样本适应没有被充分验证。*]

同一个 EEG Conformer 在 BCI IV-2a 上被试内约 78.7%，跨被试只有 47.0%。评测协议对数值的影响远大于模型之间的差异。AdaBrain-Bench 唯一的回归任务 SEED-VIG（警觉度估计）中，基础模型没有明显优于从零训练的 EEGNet（@tbl-seedvig）。零样本跨被试方面，UniMind 作者明确说明没有研究对完全未见被试的泛化；ECHO 的上下文学习在测试时使用测试被试本人的带标签支持样本。"不使用目标被试标签时能否直接适应"这一点没有被验证。

#figure(
  table(
    columns: (auto, auto),
    stroke: 0.5pt,
    inset: 6pt,
    align: (left, right),
    table.header([*模型*], [*R²（%）*]),
    [EEGNet], [26.65],
    [BIOT], [27.09],
    [LaBraM], [25.35],
    [EEGPT], [23.47],
    [CBraMod], [2.40],
  ),
  caption: [回归任务 SEED-VIG（跨被试，全量微调）：基础模型没有明显优于从零训练的模型。CBraMod 原文报告同一任务 R² 为 33.7%。数据：AdaBrain-Bench Table 2。],
) <tbl-seedvig>

#par(first-line-indent: 0em)[*(4) 评测：不同论文的数字往往不可比。*]

划分方式不同（被试内与跨被试，EEG Conformer 在 BCI IV-2a 上差 30 个百分点）；"线性探测"的定义不同（EEGPT 的线性探测实际包含卷积层）；模型选择方式不同（EEG Conformer 公开代码每个 epoch 都在测试集上评估）；同一模型在不同论文中数值不一致（CBraMod）；适配方式差异巨大（REVE 在 OmniEEG-Bench 的 SSVEP 上线性探测 5.6%，全量微调 67.4%；而 NeuralBench 中达 96.1%）。此外，指标在真实场景中是否有意义也值得追问——例如运动想象是瞬时任务，逐窗口预测容易出现标签"闪动"噪声，平衡准确率反映不出这一点。

#grid(
  columns: (1fr, 1fr),
  gutter: 8pt,
  figure(
    image("figures/fig_reve_ssvep_protocols.png", width: 100%),
    caption: [同一个 REVE 在不同评测协议下的 SSVEP 平衡准确率。数据集、划分与适配方式不同，不构成排行榜。],
  ),
  figure(
    image("figures/fig_omnieeg_ssvep_lp_ft.png", width: 100%),
    caption: [OmniEEG-Bench（Benchmark-SSVEP，跨被试）：线性探测与全量微调。EEGNet、EEG Conformer 为从零训练的监督模型，只有微调结果。],
  ),
)

== 我们想研究的问题

基于上述问题，本方案采取"*先诊断，后改进*"的思路，诊断分三层：

+ *表征层*：基础模型是否学到了不同时间、空间尺度的表征？是否包含、甚至超出神经科学先验？Neuro-KE 表明，成熟的 EEG 描述子既能用来*检查*表示（探测其中是否保留了有生理意义的结构），也能用来*监督*表示（作为预训练目标）。
+ *设计层*：现有模型的各项设计中，哪些是针对 EEG 特殊性提出的，哪些有深度学习理论支撑？
+ *评测层*：评测指标在真实场景中是否有意义？

主赛道恰好提供了诊断所需的条件：同一套被试隔离的 8:1:1 划分、固定种子、统一的验证集选择规则，覆盖 7 类频段特性和时间尺度差异很大的任务。例如 SSVEP 依赖稳定的高频响应，睡眠分期依赖 30 秒的慢节律，运动想象依赖 μ/β 节律的瞬时变化。如果一个改进只对某类任务有效，主赛道的结构能把这一点暴露出来。

// ══════════════════════════════════════════════
// 2  相关工作
// ══════════════════════════════════════════════

= 相关工作

本节按"解决什么问题"组织，不按时间顺序。

== 任务专用的有监督模型

EEGNet（Lawhern et al., 2018）用深度可分离卷积实现"时间滤波器组 + 频段特异的空间滤波"，约 1–2k 参数，在 P300、ERN、MRCP、运动想象上与参考方法相当。通道数是架构参数，不能跨布局。EEG Conformer（Song et al., 2023）在卷积前端上叠加 6 层 Transformer。这两者是基础模型论文中最常用的监督基线，也是本赛题实验计划中的必要对照。

== EEG 基础模型：如何统一异构输入

#figure(
  table(
    columns: (auto, 1fr, 1fr),
    stroke: 0.5pt,
    inset: 5pt,
    align: left,
    table.header([*工作*], [*输入如何统一*], [*位置/通道信息*]),
    [BIOT (NeurIPS 2023)], [逐通道片段的 FFT 能量 token 拉平成序列，线性注意力], [通道查表嵌入],
    [LaBraM (ICLR 2024)], [通道 × 1 秒 patch], [按电极编号查表],
    [CBraMod (ICLR 2025)], [通道 × 时间 patch，空间与时间注意力并行], [条件位置编码 (ACPE)],
    [EEGPT (NeurIPS 2024)], [先跨通道、再跨时间的分层结构], [通道名码本],
    [BrainOmni (2025)], [传感器编码器 + cross-attention 压缩为 16 个潜在源], [电极三维坐标、方向、类型],
    [CSBrain (2025)], [交替多尺度 token 化 (CST) 与结构化稀疏注意力 (SSA)], [按解剖脑区分组],
    [*REVE* (2025)], [保留观测通道，全局注意力], [电极坐标 + 时间的 *4D Fourier 位置编码*],
  ),
  caption: [EEG 基础模型的输入统一方式比较。REVE 指出以往模型预训练语料多来自 TUH 的固定 19/21 导联，查表或卷积式位置编码难以覆盖未见布局。],
) <tbl-input>

#figure(
  image("figures/related/REVE_fig1.png", width: 95%),
  caption: [REVE 预训练框架：4D Fourier 位置编码、块状掩码、主重建与辅助全局 token 重建（图源：REVE Fig. 1）。],
) <fig-reve>

#grid(
  columns: (1fr, 1fr),
  gutter: 8pt,
  figure(
    image("figures/related/CBraMod_fig2.png", width: 100%),
    caption: [CBraMod：criss-cross 注意力的预训练（图源：CBraMod Fig. 2）。],
  ),
  figure(
    image("figures/related/LaBraM_fig1.png", width: 100%),
    caption: [LaBraM：通道 × 1 s patch 与时空嵌入（图源：LaBraM Fig. 1）。],
  ),
)

#grid(
  columns: (1fr, 1fr),
  gutter: 8pt,
  figure(
    image("figures/related/CSBrain_fig2.png", width: 100%),
    caption: [CSBrain：多尺度 token 化与结构化稀疏注意力（图源：CSBrain Fig. 2）。],
  ),
  figure(
    image("figures/related/BrainOmni_fig1.png", width: 100%),
    caption: [BrainOmni：传感器编码器与潜在源 tokenizer（图源：BrainOmni Fig. 1）。],
  ),
)

#figure(
  image("figures/related/BIOT_fig1.jpg", width: 70%),
  caption: [BIOT：逐通道片段 token 化与线性 Transformer（图源：BIOT Fig. 1）。],
) <fig-biot>

== EEG 基础模型：预训练预测什么

#figure(
  table(
    columns: (auto, auto, 1fr),
    stroke: 0.5pt,
    inset: 5pt,
    align: left,
    table.header([*预测对象*], [*代表工作*], [*要点*]),
    [原始波形], [REVE, CBraMod], [简单直接；FAME 认为 MSE 重建会按功率放大低频监督],
    [离散码], [LaBraM, BrainOmni], [LaBraM 报告直接重建原始波形时不收敛；但消融结果分裂],
    [频段标准化时频活动], [*FAME* (2026)], [各频段对数功率分别标准化、等权；13 任务平均 61.4%],
    [潜在表示], [*EEGPT*, S-JEPA], [在表示空间设目标；EEGPT 去掉对齐损失后 BCIC-2A 从 0.585 降到 0.529],
    [对比预测], [BENDR, BIOT], [避免逐点重建；BENDR 作者承认多数任务不及针对性方法],
  ),
  caption: [EEG 基础模型的预训练目标比较。],
) <tbl-pretrain>

#figure(
  image("figures/related/FAME_fig2.png", width: 65%),
  caption: [FAME：传统波形重建 vs 按频段平衡的重建（图源：FAME Fig. 2）。],
) <fig-fame>

== 把领域知识写进监督信号

Neuro-KE（NeurIPS 2026）无需额外人工标注地计算 EEG 描述子，转成三种按范式区分的监督：掩码预训练的数值预测目标、EEG–文本对齐的特征状态文本锚、EEG 多模态大模型的特征依据回答。相对只做重建的掩码预训练，12 个数据集、3 种骨干上平均 BAcc +2.60。FAME 的按频段标准化目标，也可以看作同一思路的一个特例：用"频段功率"这一领域知识重新定义重建目标。

本方案与这条路线的区别在于：不只是增加知识目标，而是把目标按"频段 × 尺度"组织进可检查的子空间，并让下游任务以可读的门控权重选择使用哪些子空间。

== 一个模型、多个任务：更强的解码器

NeuroLM 把 EEG 码加入 GPT-2 词表，通过指令微调做多任务；所有任务都低于单任务的 LaBraM。UniMind 用时空 query 连接器和任务感知 query 选择接入 7B LLM；10 个数据集平均 67.50，略高于 LaBraM 的 66.56，但部分数据集仍落后。ECHO 通过上下文中的带标签支持样本完成序列到序列解码。

这一分支希望借助泛化能力已被验证的解码器，解决"编码器或许已学到有用表征，但无法在下游任务上用好"的问题；但目前本身竞争力不足。它们共同暗示了一个可检验的问题：下游表现差，是*表征瓶颈*还是*读出瓶颈*。

#grid(
  columns: (1fr, 1fr),
  gutter: 8pt,
  figure(
    image("figures/related/NeuroLM_fig3.png", width: 100%),
    caption: [NeuroLM：多通道自回归与指令微调（图源：NeuroLM Fig. 3）。],
  ),
  figure(
    image("figures/related/UniMind_fig2.png", width: 100%),
    caption: [UniMind：神经–语言连接器与任务感知 query 选择（图源：UniMind Fig. 2）。],
  ),
)

#figure(
  image("figures/related/ECHO_fig2.png", width: 65%),
  caption: [ECHO：带支持样本的序列到序列解码（图源：ECHO Fig. 2）。],
) <fig-echo>

== 潜在预测与结构化表征（非 EEG 领域）

JEPA-Anything（arXiv 2609.20800）提出正交预测分解（OPF），把潜在空间分为若干相互正交的可学习子空间，各子空间分别做预测，并用正交约束 $sum_k norm(P_k^top P_k - I)_F^2 + sum_(i<j) norm(P_i^top P_j)_F^2$ 防止信息混叠。H-JEPA（arXiv 2610.06805）按时间分层的世界模型，探测显示层级越高越丢弃快变特征；这种分工只在快慢成分的频率差距约 2 倍以上时出现。

这些工作给出了两件 EEG 基础模型尚未系统使用的工具：*正交子空间*（让不同因素在表征中可分离、可检查）和*按尺度分层的潜在预测*（让不同时间尺度在表征中各有位置）。

#grid(
  columns: (1fr, 1fr),
  gutter: 8pt,
  figure(
    image("figures/related/JEPA-Anything_fig1.png", width: 100%),
    caption: [JEPA-Anything：正交预测分解（图源：JEPA-Anything Fig. 1）。],
  ),
  figure(
    image("figures/related/H-JEPA_fig1.png", width: 100%),
    caption: [H-JEPA：按时间分层的潜在世界模型（图源：H-JEPA Fig. 1）。],
  ),
)

#figure(
  image("figures/related/H-JEPA_fig4.png", width: 70%),
  caption: [H-JEPA：层级越高越丢弃快变特征（图源：H-JEPA Fig. 4）。],
) <fig-hjepa-probe>

== 评测基准

OmniEEG-Bench（arXiv 2606.00815）与本赛事最接近的任务体系，以跨被试线性探测为主。NeuralBench（arXiv 2605.08495）多任务、多模型的统一评测。AdaBrain-Bench（arXiv 2507.09882）包含跨被试、多被试、少样本设置及唯一的回归任务 SEED-VIG。

// ══════════════════════════════════════════════
// 3  方法理解与比较
// ══════════════════════════════════════════════

= 方法理解与比较

== 比较维度

我们从四个维度比较现有方法，每个维度对应第 1.3 节的一个问题：(1) *输入统一*：如何处理不同的通道数、电极布局和时长（泛化问题）；(2) *预训练目标*：在什么空间里设监督信号，各频段得到的监督是否均衡（表征问题）；(3) *读出与适配*：下游用冻结表示还是全量微调，读出取哪一层、是否池化（读出瓶颈）；(4) *证据强度*：作者的主张中，哪些有受控消融支持，哪些只有不同协议下的分数比较（评测问题）。

== 主要方法的核心思路、适用条件与局限

#figure(
  table(
    columns: (auto, 1fr, 1fr, 1fr),
    stroke: 0.5pt,
    inset: 4pt,
    align: left,
    table.header([*方法*], [*核心思路*], [*较强证据*], [*局限/未证明*]),
    [EEGNet], [卷积滤波器组 + 空间滤波], [参数极少；小数据表现好], [通道固定；无预训练],
    [LaBraM], [神经 tokenizer + 掩码码预测], [TUEV 上码本目标优于直接重建], [TUAB 上结论相反；冻结表示弱],
    [CBraMod], [空间/时间注意力分离 + ACPE], [criss-cross 优于全注意力], [需全量微调；不同论文数值不一致],
    [EEGPT], [掩码重建 + 动量编码器对齐], [对齐损失有明确增益], ["线性探测"包含卷积，不可比],
    [CSBrain], [多尺度 token 化 + 结构化稀疏注意力], [16 个数据集宏平均高于 CBraMod], [多尺度消融只有图；不处理 1 s 以内],
    [BrainOmni], [传感器编码器 + 潜在源 + RVQ], [去掉传感器嵌入明显下降], [压缩效果因任务而异；冻结大幅下降],
    [*REVE*], [4D Fourier PE + 块掩码 L1 + 全局辅助；6 万小时], [处理未见布局；冻结表示较强], [4D PE 相对可学习仅高 0.006；读出影响大],
    [*FAME*], [按频段标准化等权的时频重建目标], [各频段学习更均衡；13 任务略高于 REVE], [平均差距小；预训练不含 SSVEP],
  ),
  caption: [主要方法的核心思路、已有较强证据与局限。],
) <tbl-compare>

在这些方法中，*REVE* 的数据处理方式兼顾了 EEG 数据的特点（任意布局、坐标化位置），整体最强；*FAME* 的训练方法最值得借鉴。但 FAME 与 REVE 的架构不同，两者的收益不能直接比较。FAME 图 3(C) 中 REVE 的低频偏置属于较低一档，因此"REVE 的 L1 重建是否已部分缓解低频偏置"本身是一个需要实验回答的问题。

== 为什么不直接比较公开分数

按评审细则，不能依据不可比的结果判断优劣。公开分数之间存在以下差异：(1) 划分方式（被试内与跨被试差 30 个百分点）；(2) 上下文（ISRUC 使用 20 个连续片段的序列）；(3) 适配方式（线性探测与全量微调差 60 个百分点以上）；(4) 模型选择方式（测试集上选模型）；(5) 复现差异（同一模型在不同论文中数值不同）；(6) 额外信息（是否使用目标被试标签）。因此，本方案中所有"谁更好"的判断，都以*本赛题的统一协议*下的实验为准。公开分数只用于提出假设。

// ══════════════════════════════════════════════
// 4  研究见解与研究问题
// ══════════════════════════════════════════════

= 研究见解与研究问题

== 从调研中形成的见解

+ *下游表现差，未必全是表征的问题。* REVE 换读出方式后各任务差异明显；FAME 的最佳读出层在中间层；多个模型冻结后很弱，但全量微调后可用。下游表现差，可能有一部分来自*读出*。
+ *表征中有没有、有多少神经科学结构，目前没人能回答。* Neuro-KE 指出模型可能保留了波形细节却丢掉了有生理意义的结构；它同时证明无需人工标注的 EEG 描述子既能用来*检查*表示也能用来*监督*表示。
+ *EEG 的关键信息分布在不同频段和不同时间尺度上，但现有表征把它们混在一起。* FAME 证明了预训练目标对各频段的监督不均衡；CSBrain 证明了尺度的重要性；但没有一个模型的表征能告诉我们，某个任务用了哪个频段、哪个尺度的信息。
+ *频段与尺度相关但不等价。* 同一频段（如 γ）的活动强度可以在秒级缓慢变化，所以尺度不应是一个独占的子空间，而是观察同一信息的范围。二者之间真实的约束是时间–频率不确定性：短窗口无法表示低频。
+ *贡献应来自方法，而不是推翻架构。* REVE 的数据处理方式（坐标式位置编码、任意布局）已兼顾 EEG 的特点，是最强的公开基础；改进应以"保留其权重、在其上拼接"的方式实现。

== 研究问题

由此提出一个总问题和三个可检验的子问题：

#block(inset: (left: 1.5em, right: 1.5em, top: 0.5em, bottom: 0.5em), fill: luma(248), radius: 4pt)[
  #set par(first-line-indent: 0em)
  *总问题：* 把 EEG 表征组织成"以频段为锚、在多个尺度上表达、由任务按需读取"的结构，能否在不牺牲通用性的前提下提高跨任务、跨被试的下游表现，并让表征可以被检查？
]

- *RQ1（表征）：* REVE 的各层表示，在哪些频段、哪些尺度上保留了可恢复的生理描述子？下游的差距有多少来自表征，有多少来自读出？
- *RQ2（方法）：* 在继续预训练中加入"频段锚定子空间 + 自由子空间"的混合结构，以及可变长度 patch 之间的跨尺度注意力，能否提高 14 个下游数据集的平衡准确率？锚定子空间与自由子空间各自贡献多少？
- *RQ3（任务）：* 不同任务学到的"频段 × 尺度"读取权重，是否与已知的神经生理规律一致（例如 SSVEP 偏高频、睡眠偏慢节律、运动想象偏 μ/β）？自由子空间是否学到了已知描述子解释不了的信息？

RQ1 是"诊断"，RQ2 是"改进"，RQ3 检验改进后的表征是否真的可解释。三者都可以在复赛中回答，回答结果决定决赛的设计。

// ══════════════════════════════════════════════
// 5  方法设计
// ══════════════════════════════════════════════

= 方法设计

== 整体框架

#par(first-line-indent: 0em)[*一句话概括：*]
保留 REVE 编码器，在其上拼接三个结构：(1) 频段锚定与自由的混合正交子空间；(2) 可变长度 patch 与零初始化的跨尺度注意力；(3) 按任务读取"频段 × 尺度"的门控读出。所有新增模块都*零初始化或以门控残差接入*，使继续预训练的第 0 步与原版 REVE 完全一致。

#figure(
  image("figures/fig_method_arch.png", width: 95%),
  caption: [本方案架构。蓝：保留 REVE 权重；橙（虚线）：新增模块，零初始化或门控初值为 0；绿：仅预训练使用的目标；紫：下游适配。门控热力图为示意。],
) <fig-arch>

#par(first-line-indent: 0em)[*输入与通道处理。*]
输入为 200 Hz 的 $C times T$ EEG 和各通道的标准导联名；坐标取自 MNE 标准 montage（REVE 的位置库也按导联名查坐标）。

#par(first-line-indent: 0em)[*组件一：保留的 REVE 编码器。*]
22 层、512 维、8 头的 Transformer，4D Fourier 位置编码，公开权重 MIT 许可。我们只做两处兼容性修改：时间坐标由 patch 序号改为按秒计的连续时间；增加一个零初始化的尺度嵌入。

#par(first-line-indent: 0em)[*组件二：可变长度 patch 与跨尺度注意力。*]
1 s patch 使用 REVE 原嵌入层；0.5 s、0.25 s 的 patch 使用原嵌入矩阵 $W in bb(R)^(512 times 200)$ 中对应时长的列切片，相当于把短片段补零放进 1 s 窗口。这样采样率和频率语义不变，1 s 的预训练权重完全保留。注意力分两类交替进行：*尺度内注意力*对 1 s 尺度就是 REVE 原来的全注意力，短尺度只在同一通道的局部时间窗内做；*跨尺度注意力*在同一通道、时间范围重叠的不同尺度 token 之间进行，每隔 $k$ 层插入一层，带 tanh 门控且初值为 0（借鉴 Flamingo）。

#par(first-line-indent: 0em)[*组件三：混合正交子空间。*]
在编码器输出 $z in bb(R)^512$ 上学习投影 $P_k in bb(R)^(512 times r)$，分两类：

- *锚定子空间*（$k in {delta, theta, alpha, beta, gamma}$）：每个子空间预测被遮 token 在对应频段的描述子。主干目标为按频段标准化的对数功率（FAME 式）；扩展目标为更多 Neuro-KE 式描述子。描述子只在物理上有意义的尺度上计算：窗口太短的尺度不挂低频段（如 0.25 s 不挂 δ）。
- *自由子空间*：不指定含义，只做 JEPA 式潜在预测——预测器根据可见 token 预测被遮 token 在 EMA 教师（以 REVE 初始化）表示中的投影。为防坍缩，加方差约束或 SIGReg。

*正交约束*：$cal(L)_"orth" = sum_k norm(P_k^top P_k - I_r)_F^2 + sum_(i<j) norm(P_i^top P_j)_F^2$（JEPA-Anything）。它保证各子空间几何上不重叠、不互相复制，但不保证统计独立；子空间对应哪个频段由监督目标决定。跨频段的真实关联保留在共享的 $z$ 中，下游可组合读取。

初始维度（待调）：$r = 48$；5 个锚定子空间共 240 维，4 个自由子空间共 192 维，剩余 80 维不约束。

#par(first-line-indent: 0em)[*预训练总损失：*]

$ cal(L) = underbrace(sum_(k in "band") cal(L)_"desc"^((k)), "锚定") + lambda_f underbrace(sum_(j in "free") cal(L)_"latent"^((j)), "自由") + lambda_"orth" cal(L)_"orth" + lambda_"keep" cal(L)_"keep" $

$cal(L)_"keep"$ 防止继续预训练时遗忘 REVE 已学到的知识。REVE 的 decoder 没有公开，因此主方案用*对冻结的原版 REVE 做特征蒸馏*（不需要 decoder）；重建 decoder 并保留 L1 波形重建作为对照。

#par(first-line-indent: 0em)[*组件四：任务门控读出。*]
每个下游数据集学习一组门控权重 $g in bb(R)^(K times S)$（$K$ 个子空间 × $S$ 个尺度，softmax 归一化），对子空间表示加权后送入分类头。读出方式和 patch 长度组合按验证集 BACC 选择。门控权重本身就是 RQ3 的分析对象。

== 复赛：基于 REVE 公开权重的训练与适配

#par(first-line-indent: 0em)[*第 0 步：诊断（不训练，回答 RQ1）。*]

+ *可恢复性图*：用冻结的 REVE 抽取各层表示，以按频段、按尺度计算的描述子为目标训练线性探测，得到"层 × 频段 × 尺度"的可恢复性图。
+ *读出瓶颈*：在 14 个数据集上，对同一冻结表示比较不同复杂度的读出（线性、PCA 降维后线性、MLP、池化与不池化）。如果复杂读出大幅提高分数，说明信息在表征中但难以读出。
+ *基线*：按 REVE 官方流程在 14 个数据集 × 3 个种子上微调，作为分数基线。

#par(first-line-indent: 0em)[*第 1 步：继续预训练（回答 RQ2）。*]

数据为 14 个下游数据集的训练集被试（不使用标签）。验证集、测试集被试绝不进入继续预训练。阶段 1（热身）冻结 REVE 编码器，只训练新增模块；阶段 2（联合）解冻编码器，较小学习率并按层衰减，每个 batch 随机抽取 patch 长度组合。掩码沿用 REVE 的块状掩码（比例 0.55）。

#par(first-line-indent: 0em)[*第 2 步：下游适配。*]
沿用 REVE 的两段式流程：先冻结编码器训练门控与分类头，再全量微调（或 LoRA）。所有超参数按验证集 BACC 选择。

#figure(
  image("figures/fig_pipeline.png", width: 95%),
  caption: [两阶段研究流程：复赛回答 RQ1–RQ3，决赛按复赛结果设计。],
) <fig-pipeline>

== 决赛：从零预训练与适配

决赛不得加载任何预训练权重。能带入决赛的是复赛验证过的*目标、结构与比例*。语料为官方 21 个 OpenNeuro 数据集（32/64/76/128 通道，200 Hz）。模型为 REVE 式编码器（坐标式 4D 位置编码、块状掩码），规模按语料时长和算力在 Small（12M）与 Base（69M）之间选择。从零训练时没有可蒸馏的原模型，$cal(L)_"keep"$ 换成重建 decoder 的 L1 波形重建。

== 设计依据与取舍

#figure(
  table(
    columns: (auto, auto, 1fr, 1fr),
    stroke: 0.5pt,
    inset: 4pt,
    align: left,
    table.header([*设计*], [*对应 RQ*], [*为什么可能有效*], [*代价/适用条件*]),
    [保留 REVE，零初始化接入], [全部], [起点为当前最强公开模型], [只适用于复赛],
    [频段锚定子空间], [RQ1, 2], [各频段独立监督（FAME）；描述子目标提高 BAcc（Neuro-KE +2.60）], [描述子需预计算；短窗口无法表示低频],
    [自由子空间 + 潜在预测], [RQ2, 3], [给模型学习先验之外信息的空间], [有坍缩风险；含义需事后探测],
    [正交约束], [RQ2], [防止各子空间互相复制], [只约束几何关系，不保证纯粹],
    [可变 patch + 跨尺度注意力], [RQ2], [SSVEP 的 1 s 输入从 1 个 token 变为多个], [短 patch 增加计算量],
    [任务门控读出], [RQ3], [不同任务依赖不同频段与尺度], [门控可能塌缩到单一子空间],
    [特征蒸馏防遗忘], [—], [继续预训练数据远少于 6 万小时], [蒸馏太强会限制改进],
  ),
  caption: [设计依据与取舍总结。],
) <tbl-design>

*复赛结果如何影响决赛设计：* 若锚定子空间带来稳定提升而自由子空间贡献小，决赛提高锚定比例；若自由子空间贡献明显且信息不能被已知描述子解释，决赛保留较大自由子空间；若跨尺度注意力只在 SSVEP 等短时任务上有效，决赛只为这些任务启用短 patch；若诊断显示瓶颈主要在读出，决赛把更多精力放在门控读出；若只继续预训练、不加新目标的对照与完整方法差不多，说明收益来自领域适应而非方法。

// ══════════════════════════════════════════════
// 6  实验与消融计划
// ══════════════════════════════════════════════

= 实验与消融计划

== 整体实验设计

*统一协议（与赛题一致）：* 训练/验证/测试按被试 8:1:1 隔离；3 个指定随机种子各自重新划分；按验证集 BACC 选择权重；报告测试集 BACC 的三种子均值与标准差，并同时报告 PR-AUC、ROC-AUC 和 F1。每个配置需要 14 个数据集 × 3 个种子 = 42 次运行。

#par(first-line-indent: 0em)[*基线：*]

#figure(
  table(
    columns: (auto, auto, 1fr),
    stroke: 0.5pt,
    inset: 5pt,
    align: left,
    table.header([*类别*], [*模型*], [*作用*]),
    [从零有监督], [EEGNet, EEG Conformer], [专用小模型参照],
    [公开基础模型], [LaBraM, CBraMod, REVE（官方流程）], [统一协议分数],
    [*关键对照*], [*REVE + 只用原目标继续预训练*], [区分"方法本身"与"领域适应"],
    [本方法], [REVE + 混合子空间 + 跨尺度注意力 + 任务门控], [—],
  ),
  caption: [实验基线设置。关键对照使用相同数据与步数，区分方法贡献与领域适应。],
) <tbl-baseline>

每类任务的预期观察点（不预设结果）：SSVEP 看短 patch 是否带来提升；睡眠分期看长尺度与低频锚定子空间的门控权重；疾病诊断看 REVE 与专用网络之间的差距是否缩小。

== 消融与对照

#figure(
  table(
    columns: (auto, 1fr, 1fr, 1fr),
    stroke: 0.5pt,
    inset: 4pt,
    align: left,
    table.header([*编号*], [*变体*], [*检验的问题*], [*控制条件*]),
    [A0], [REVE 原版（不继续预训练）], [分数下限], [—],
    [A1], [只用原目标继续预训练], [收益是否来自额外训练], [数据、步数相同],
    [A2], [全锚定（无自由子空间）], [先验够不够], [总子空间维度相同],
    [A3], [全自由（无锚定，即 JEPA-Anything 式）], [先验是否必要], [同上],
    [A4], [混合，去掉正交约束], [正交是否必要], [同上],
    [A5], [固定 1 s patch（无短 patch/跨尺度注意力）], [可变 patch 的贡献], [预训练步数相同],
    [A6], [有短 patch，但不插跨尺度注意力], [是否需跨尺度共享], [同上],
    [A7], [全部尺度 token 做一次全注意力], [跨尺度门控与代价上限], [另报计算量],
    [A8], [门控读出 → 普通池化读出], [任务门控的贡献], [同一预训练模型],
    [A9], [特征蒸馏 → 重建 decoder 的 L1], [防遗忘方式的选择], [同上],
  ),
  caption: [消融实验设计。每个变体仅改变一个变量。],
) <tbl-ablation>

*可解释性检验：* (1) *带限扰动*：把输入的某一频段滤掉，检查对应锚定子空间的变化是否明显大于其他子空间。(2) *自由子空间探测*：用 Neuro-KE 式描述子探测自由子空间，不能被已知描述子解释的方差比例作为"超出先验"的度量。(3) *门控权重*：与已知生理规律对照（RQ3）。

*算力受限时的优先级：* A1、A2、A3、A5 在全部 14 个数据集上运行；其余先在每个分赛道选一个数据集（7 个）上运行，结论明确后再扩展。

== 实验判读思路

- *支持假设*：完整方法相对 A1 在多数分赛道上提高 BACC，且提升超过三种子标准差；A2、A3 都低于混合方案；门控权重与已知生理规律大体一致。
- *不支持假设*：完整方法与 A1 持平——收益来自领域适应而非方法；或可解释性检验失败——锚定子空间没有真正对应频段。
- *任务差异*：主赛道按分赛道排名计分。某个改进只在部分任务上有效时，不用 14 个数据集的平均值掩盖，而是按分赛道报告，并通过门控或按任务选择 patch 长度。
- *波动*：三种子标准差大于方法差异时，不下结论，比较跨种子一致性。
- *评测层的补充分析*：运动想象等瞬时任务中，逐窗口预测容易出现标签"闪动"。若数据允许按试次重建连续窗口，额外报告相邻窗口预测的一致性，作为平衡准确率之外的诊断（不用于选模型）。

// ══════════════════════════════════════════════
// 7  算力需求
// ══════════════════════════════════════════════

= 算力需求（估算）

#figure(
  table(
    columns: (auto, 1fr, 1fr),
    stroke: 0.5pt,
    inset: 5pt,
    align: left,
    table.header([*阶段*], [*内容*], [*估算*]),
    [复赛 第 0 步], [冻结表示的探测与读出对照], [前向为主，约数十 GPU 小时],
    [复赛 第 1 步], [继续预训练（若按种子分别做 ×3）], [REVE Base 完整预训练约 260 A100 小时，继续预训练远小于此],
    [复赛 第 2 步], [每个配置 42 次微调；约 15 个配置], [单次微调时长待短测],
    [决赛], [21 个数据集上从零预训练 + 42 次微调], [取决于语料时长与官方配额],
  ),
  caption: [算力需求估算。GPU 型号、显存、卡数待官方算力公布后填写。],
) <tbl-compute>

// ══════════════════════════════════════════════
// 8  数据来源与复现说明
// ══════════════════════════════════════════════

= 数据来源与复现说明

- *数据*：复赛只使用官方公开的 14 个下游数据集及公开预训练权重（REVE，MIT 许可）；决赛只使用官方 21 个预训练数据集，不加载任何权重。不使用未公开的私有数据。
- *防泄漏*：继续预训练只使用训练集被试；验证、测试被试不参与任何预训练或调参。
- *复现*：固定 3 个官方种子；所有超参数、继续预训练步数和选择规则写入配置文件；代码基于 REVE 官方仓库（elouayas/reve\_eeg）修改，随复赛提交。

// ══════════════════════════════════════════════
// 参考文献
// ══════════════════════════════════════════════

#pagebreak()

#heading(numbering: none)[参考文献]

#set par(first-line-indent: 0em)
#set text(size: 9.5pt)

+ Lawhern _et al._ EEGNet: A Compact Convolutional Neural Network for EEG-based Brain-Computer Interfaces. _J. Neural Eng._, 2018.
+ Song _et al._ EEG Conformer: Convolutional Transformer for EEG Decoding and Visualization. _IEEE TNSRE_, 2023.
+ Kostas _et al._ BENDR: Using Transformers and a Contrastive Self-supervised Learning Task to Classify EEG. _Front. Hum. Neurosci._, 2021.
+ Yang _et al._ BIOT: Cross-data Biosignal Learning in the Wild. _NeurIPS_, 2023.
+ Jiang _et al._ Large Brain Model for Learning Generic Representations with Tremendous EEG Data in BCI (LaBraM). _ICLR_, 2024.
+ Wang _et al._ EEGPT: Pretrained Transformer for Universal and Reliable Representation of EEG Signals. _NeurIPS_, 2024.
+ Wei _et al._ CBraMod: A Criss-Cross Brain Foundation Model for EEG Decoding. _ICLR_, 2025.
+ BrainOmni: A Foundation Model for Any-to-Any Brain Signal Conversion. 2025.
+ CSBrain: Cross-Scale Brain Transformer for Cross-Dataset EEG Decoding. 2025.
+ El Ouayas _et al._ REVE: Robust EEG Vision Encoder. 2025.
+ FAME: Understanding and Correcting Low-Frequency Bias in EEG Representation Learning. 2026.
+ NeuroLM: A Universal Multi-task Foundation Model for Bridging the Gap between Language and EEG Signals. 2025.
+ UniMind: Unified Multi-task Brain Decoding with Multi-level Alignment. 2025.
+ ECHO: EEG Channel-wise Hypernetwork Organization for In-context Learning. 2025.
+ Chen _et al._ Neuro-KE: Knowledge-Guided Interfaces for Semantically Grounded EEG Foundation Models. _NeurIPS_, 2026.
+ JEPA-Anything: Orthogonal Predictive Factorization for Joint-Embedding Predictive Architectures. 2025.
+ H-JEPA: Hierarchical World Model for Time Series. 2025.
+ LocaLeJEPA: Local Distribution Matching in Latent Space. 2025.
+ OmniEEG-Bench: A Comprehensive Benchmark for EEG Foundation Models. 2026.
+ NeuralBench: A Multi-task Benchmark for Neural Signal Decoding. 2025.
+ AdaBrain-Bench: Adaptive Evaluation Framework for EEG Brain-Computer Interfaces. 2025.
+ Alayrac _et al._ Flamingo: A Visual Language Model for Few-shot Learning. _NeurIPS_, 2022.
