// OmniEEG Challenge 2026 初赛研究方案
// 编译：python3 -c "import typst; typst.compile('docs/report/proposal.typ', output='docs/report/proposal.pdf')"

#set page(paper: "a4", margin: (x: 23mm, top: 23mm, bottom: 22mm))
#set text(font: ("Libertinus Serif", "Noto Serif CJK SC"), size: 10pt)
#set par(justify: true, leading: 0.55em, first-line-indent: 1.2em)
#set heading(numbering: "1.1")
#set math.equation(numbering: "(1)")
#show heading.where(level: 1): set text(size: 12pt)
#show heading.where(level: 2): set text(size: 10.5pt)
#show figure.caption: set text(size: 8pt)
#show figure.where(kind: table): set figure.caption(position: top)
#set figure(gap: 5pt)

// ── 封面 ──

#v(18mm)
#align(center)[
  #set par(justify: false)
  #text(size: 12pt)[OmniEEG Challenge 2026 · 主赛道]
  #v(10mm)
  #text(size: 16pt, weight: "bold")[先诊断，后改进：面向跨任务 EEG 基础模型的 \ 频段正交子空间预测学习]
  #v(5mm)
  #text(size: 11pt)[Diagnose First, Improve Next: Frequency-Orthogonal Subspace Predictive \ Learning for Cross-Task EEG Foundation Models]
  #v(8mm)
  初赛研究方案
  #v(6mm)
  队伍名称：#underline[#h(5em)] #h(1em) 参赛成员：#underline[#h(5em)] \
  2026 年 11 月
]
#v(6mm)
#align(center)[#strong[摘要]]
#v(2mm)
#block(inset: (x: 1mm))[#set text(size: 9pt)
#set par(first-line-indent: 0pt, justify: true)
当前 EEG 基础模型在运动想象和 SSVEP 等任务上表现突出，但在疾病诊断等方向大幅落后于专用小模型。本方案提出"先诊断，后改进"的研究思路：首先通过冻结表示的频段–尺度可恢复性图和读出瓶颈实验，系统诊断 REVE 表征中各频段、各尺度信息的保留与可读出程度；然后在 REVE 编码器之上拼接三个零初始化模块——频段锚定与自由的混合正交子空间、可变长度 patch 与跨尺度门控注意力、任务门控读出——通过继续预训练注入结构化的频段监督与潜在预测目标。正交约束保证各子空间几何上不重叠，任务门控权重使"哪个频段、哪个尺度被用到"可以直接报告和检验。复赛基于 REVE 公开权重（MIT 许可），决赛使用复赛验证过的目标与结构从零训练。10 项消融分别检验锚定与自由子空间的必要性、正交约束的作用、可变 patch 的贡献和门控读出的效果，并以带限扰动和描述子探测实验检验可解释性。

#strong[关键词：] EEG 基础模型，频段正交子空间，预测学习，跨尺度注意力，任务门控读出，REVE
]

#pagebreak()
#counter(page).update(1)
#set page(
  header: [#set text(size: 8pt)
#grid(columns: (1fr, auto), [频段正交子空间预测学习], [OmniEEG 2026 初赛研究方案])
#line(length: 100%, stroke: 0.4pt)],
  footer: context align(center, text(size: 9pt, counter(page).display())),
)
#outline(title: [目录], depth: 2)
#pagebreak()

// ══════════════════════════════════════════════
// 1  赛道选择与研究动机
// ══════════════════════════════════════════════

= 赛道选择与研究动机 <sec:motivation>

== 为什么选主赛道

本赛事的 7 个分赛道覆盖信号可靠性、疾病诊断、睡眠分期、认知与情绪、自然刺激解码、运动想象和 SSVEP。14 个下游数据集的通道数从 4 到 128，时长从 1 秒到 30 秒。分赛道考察的是"某一类任务做得好不好"；主赛道考察的是*同一个基础模型能否同时服务于性质差异很大的任务*。后者正是"基础模型"这一概念成立的前提，也是我们想研究的问题，因此选择主赛道。

== 问题的由来：从专用模型到基础模型

#par(first-line-indent: 0em)[*专用模型的局限。*]
传统 EEG 解码针对每种范式单独设计预处理、特征和分类器。EEGNet 等紧凑 CNN 把"滤波器组 + 空间滤波"写进网络结构，能跨范式使用，但每个模型绑定一种通道配置（空间卷积核大小等于通道数），不能跨布局迁移，也没有利用大规模无标注数据。

#par(first-line-indent: 0em)[*EEG 数据本身的困难。*]
EEG 信噪比低；不同数据集的导联数、电极位置、参考方式、时长和采样率高度异构；被试之间差异大；功率谱大致服从 $1 slash f^alpha$，能量集中在低频；有标注的数据量通常只有几十小时。

#par(first-line-indent: 0em)[*基础模型的回应。*]
为此出现了一系列在大规模无标注 EEG 上预训练的基础模型，例如：BIOT 把逐通道片段拉平成序列；LaBraM 用神经 tokenizer 预测离散码；CBraMod 的 criss-cross 注意力把空间与时间分开建模；REVE 用电极坐标的 4D Fourier 位置编码支持任意布局，并在约 6 万小时数据上预训练；FAME 把重建目标改为按频段标准化的时频活动。

== 基础模型仍然存在的问题 <sec:problems>

我们认为当前 EEG 基础模型最大的问题是：*准确率不稳定、表征空间缺乏可解释性、泛化能力没有被明确验证、下游评测困难*。归结起来，领域缺少对三件事的诊断：模型学到了什么，哪些设计真正在起作用，评测数字代表什么。下面逐条给出公开证据。

#par(first-line-indent: 0em)[*(1) 准确率：并不稳定地超过专用小模型。*]
NeuralBench 的同一快照中，REVE 在运动想象（68.0%，第 1）和 SSVEP（96.1%，第 2）上很强；但在精神分裂症识别上只有 43.7%，最佳专用网络 ATCNet 为 72.9%；癫痫检测 77.6%，BDTCN 为 85.5%。基础模型的优势随任务而异，"更大、更多数据"并不自动带来全面提升。LaBraM 的数据量实验中，Base 模型用 500 小时在 TUAB 上反而超过 2500 小时；FAME 报告扩大数据或规模后下游表现不稳定提升。

#figure(
  image("figures/fig_neuralbench_reve_gap.png", width: 95%),
  caption: [NeuralBench 统一微调协议下，REVE 与各任务最佳模型的差距。只含以平衡准确率为指标的任务，按差距排序；右侧标注差距 ≥ 3 个百分点的最佳模型与差值。数据：NeuralBench 官方结果（提交 fe31393）。],
) <fig:gap>

#par(first-line-indent: 0em)[*(2) 表征：冻结表示普遍偏弱，学到了什么并不清楚。*]
多个模型的作者承认下游需要全量微调，冻结表示不够用：LaBraM 在 TUEV 上线性探测 0.346，全量微调 0.641；CBraMod 冻结后 PhysioNet-MI 只有 0.385；BrainOmni 冻结后 TUEV 从 0.618 降到 0.489。FAME 指出，现有预训练编码器普遍存在*低频偏置*：表示对高频成分的可恢复性更差，其机制是时域 MSE 重建按功率给各频率加权。

REVE 的同一个模型换用不同读出方式（池化与不池化）后，各任务结果差异明显（REVE Table 4）。FAME 的最佳读出层是第 9 层而非最后一层。这说明下游表现差，可能部分来自*读出*而不全是*表征*本身。目前没有工作系统地区分这两者。Neuro-KE（NeurIPS 2026）也指出，原始 EEG 没有规范的 token 语义，模型可能保留了波形细节却丢掉了有生理意义的结构；它把无需人工标注的 EEG 描述子转成掩码预训练的数值目标，在 12 个数据集、3 种骨干上相对只做重建平均提高 BAcc 2.60 个百分点。这说明"把领域知识写进预训练目标"是有效的方向。

#grid(
  columns: (1fr, 1fr),
  gutter: 8pt,
  figure(
    image("figures/related/FAME_fig3.png", width: 100%),
    caption: [现有预训练编码器偏向低频（图源：FAME Fig. 3）。],
  ),
  figure(
    image("figures/fig_reve_readout.png", width: 100%),
    caption: [REVE-Base 同一冻结表示，只换读出方式。数字为"不池化 − 池化"，只标注差值 ≥ 5 的任务。数据：REVE Table 4。],
  ),
)

#par(first-line-indent: 0em)[*(3) 泛化：跨被试、回归和零样本适应没有被充分验证。*]
同一个 EEG Conformer 在 BCI IV-2a 上被试内约 78.7%，跨被试只有 47.0%。评测协议对数值的影响远大于模型之间的差异。AdaBrain-Bench 唯一的回归任务 SEED-VIG 中，基础模型没有明显优于从零训练的 EEGNet（Table~#ref(<tab:seedvig>, supplement: none)）。零样本跨被试方面，UniMind 作者明确说明没有研究对完全未见被试的泛化；ECHO 的上下文学习在测试时使用测试被试本人的带标签支持样本。

#block[
  #set text(size: 8pt)
  #set par(justify: false)
  #figure(table(
    columns: (2fr, 1fr),
    inset: 4pt, stroke: none, align: left,
    table.hline(stroke: 0.8pt),
    table.header([*模型*], [*R²（%）*]),
    table.hline(stroke: 0.5pt),
    [EEGNet], [26.65],
    [BIOT], [27.09],
    [LaBraM], [25.35],
    [EEGPT], [23.47],
    [CBraMod], [2.40],
    table.hline(stroke: 0.8pt),
  ), caption: [回归任务 SEED-VIG（跨被试，全量微调）。CBraMod 原文报告 R² = 33.7%。数据：AdaBrain-Bench Table 2。]) <tab:seedvig>
]

#par(first-line-indent: 0em)[*(4) 评测：不同论文的数字往往不可比。*]
划分方式不同（被试内与跨被试差 30 个百分点）；"线性探测"定义不同（EEGPT 包含卷积层）；模型选择方式不同（EEG Conformer 公开代码在测试集上评估）；同一模型在不同论文中数值不一致（CBraMod）；适配方式差异巨大（REVE 在 OmniEEG-Bench SSVEP 上线性探测 5.6%，全量微调 67.4%；NeuralBench 中达 96.1%）。此外，运动想象等瞬时任务中，逐窗口预测容易出现标签"闪动"噪声，平衡准确率反映不出这一点。

#grid(
  columns: (1fr, 1fr),
  gutter: 8pt,
  figure(
    image("figures/fig_reve_ssvep_protocols.png", width: 100%),
    caption: [同一个 REVE 在不同评测协议下的 SSVEP 平衡准确率。],
  ),
  figure(
    image("figures/fig_omnieeg_ssvep_lp_ft.png", width: 100%),
    caption: [OmniEEG-Bench SSVEP 线性探测与全量微调。],
  ),
)

== 我们想研究的问题 <sec:rq-preview>

基于上述问题，本方案采取"*先诊断，后改进*"的思路，诊断分三层：(1) *表征层*——基础模型是否学到了不同时间、空间尺度的表征？(2) *设计层*——哪些设计针对 EEG 特殊性，哪些有理论支撑？(3) *评测层*——评测指标在真实场景中是否有意义？主赛道恰好提供了诊断所需的条件：统一划分、固定种子，覆盖 7 类频段特性和时间尺度差异很大的任务。如果一个改进只对某类任务有效，主赛道的结构能把这一点暴露出来。

// ══════════════════════════════════════════════
// 2  相关工作
// ══════════════════════════════════════════════

= 相关工作 <sec:related>

本节按"解决什么问题"组织，不按时间顺序。

== 任务专用的有监督模型

EEGNet（Lawhern et al., 2018）用深度可分离卷积实现"时间滤波器组 + 频段特异的空间滤波"，约 1–2k 参数。EEG Conformer（Song et al., 2023）在卷积前端上叠加 6 层 Transformer。这两者是基础模型论文中最常用的监督基线，也是本方案实验计划中的必要对照。

== EEG 基础模型：如何统一异构输入

#block[
  #set text(size: 8pt)
  #set par(justify: false)
  #figure(table(
    columns: (1fr, 2fr, 1.5fr),
    inset: 4pt, stroke: none, align: left,
    table.hline(stroke: 0.8pt),
    table.header([*工作*], [*输入如何统一*], [*位置/通道信息*]),
    table.hline(stroke: 0.5pt),
    [BIOT (NeurIPS 2023)], [逐通道 FFT 能量 token，线性注意力], [通道查表嵌入],
    [LaBraM (ICLR 2024)], [通道 × 1 s patch], [电极编号查表],
    [CBraMod (ICLR 2025)], [通道 × 时间 patch，空间/时间注意力并行], [条件位置编码 (ACPE)],
    [EEGPT (NeurIPS 2024)], [先跨通道、再跨时间的分层结构], [通道名码本],
    [BrainOmni (2025)], [传感器编码器 + cross-attention → 16 个潜在源], [三维坐标、方向、类型],
    [CSBrain (2025)], [交替 CST + SSA], [解剖脑区分组],
    [*REVE* (2025)], [保留观测通道，全局注意力], [*4D Fourier 位置编码*],
    table.hline(stroke: 0.8pt),
  ), caption: [EEG 基础模型的输入统一方式比较。]) <tab:input>
]

REVE 指出以往模型预训练语料多来自 TUH 的固定 19/21 导联，查表或卷积式位置编码难以覆盖未见布局。REVE 用 92 个数据集、约 6 万小时数据预训练，并强调冻结表示的可用性。

#figure(
  image("figures/related/REVE_fig1.png", width: 92%),
  caption: [REVE 预训练框架：4D Fourier 位置编码、块状掩码、主重建与辅助全局 token 重建（图源：REVE Fig. 1）。],
) <fig:reve>

#grid(
  columns: (1fr, 1fr),
  gutter: 8pt,
  figure(
    image("figures/related/CBraMod_fig2.png", width: 100%),
    caption: [CBraMod criss-cross 注意力（图源：CBraMod Fig. 2）。],
  ),
  figure(
    image("figures/related/LaBraM_fig1.png", width: 100%),
    caption: [LaBraM 通道 × 1 s patch（图源：LaBraM Fig. 1）。],
  ),
)

#grid(
  columns: (1fr, 1fr),
  gutter: 8pt,
  figure(
    image("figures/related/CSBrain_fig2.png", width: 100%),
    caption: [CSBrain 多尺度 token 化与 SSA（图源：CSBrain Fig. 2）。],
  ),
  figure(
    image("figures/related/BrainOmni_fig1.png", width: 100%),
    caption: [BrainOmni 传感器编码器（图源：BrainOmni Fig. 1）。],
  ),
)

#figure(
  image("figures/related/BIOT_fig1.jpg", width: 65%),
  caption: [BIOT 逐通道 token 化与线性 Transformer（图源：BIOT Fig. 1）。],
) <fig:biot>

== EEG 基础模型：预训练预测什么

#block[
  #set text(size: 8pt)
  #set par(justify: false)
  #figure(table(
    columns: (1fr, 1fr, 2.5fr),
    inset: 4pt, stroke: none, align: left,
    table.hline(stroke: 0.8pt),
    table.header([*预测对象*], [*代表工作*], [*要点*]),
    table.hline(stroke: 0.5pt),
    [原始波形], [REVE, CBraMod], [简单直接；FAME 认为 MSE 重建按功率放大低频监督],
    [离散码], [LaBraM, BrainOmni], [LaBraM 报告直接重建不收敛；消融结果分裂],
    [频段标准化时频活动], [*FAME* (2026)], [各频段对数功率分别标准化等权；13 任务平均 61.4%],
    [潜在表示], [*EEGPT*, S-JEPA], [在表示空间设目标；去掉对齐损失后 BCIC-2A 从 0.585 降到 0.529],
    [对比预测], [BENDR, BIOT], [避免逐点重建；BENDR 作者承认多数任务不及针对性方法],
    table.hline(stroke: 0.8pt),
  ), caption: [EEG 基础模型的预训练目标比较。]) <tab:pretrain>
]

#figure(
  image("figures/related/FAME_fig2.png", width: 55%),
  caption: [FAME：传统波形重建 vs 按频段平衡的重建（图源：FAME Fig. 2）。],
) <fig:fame>

== 把领域知识写进监督信号

Neuro-KE（NeurIPS 2026）无需额外人工标注地计算 EEG 描述子，转成三种按范式区分的监督，相对只做重建平均 BAcc +2.60。FAME 的按频段标准化目标也可看作同一思路的特例。本方案的区别在于：不只增加知识目标，而是把目标按"频段 × 尺度"组织进可检查的子空间，并让下游任务以可读的门控权重选择使用哪些子空间。

== 一个模型、多个任务：更强的解码器

NeuroLM 把 EEG 码加入 GPT-2 词表做多任务，所有任务低于 LaBraM。UniMind 用时空 query 连接器接入 7B LLM，平均 67.50 略高于 LaBraM 的 66.56。ECHO 通过带标签支持样本完成序列到序列解码。这一分支希望借助泛化能力已被验证的解码器解决读出问题，但目前竞争力不足。它们暗示：下游表现差，是*表征瓶颈*还是*读出瓶颈*。

#grid(
  columns: (1fr, 1fr),
  gutter: 8pt,
  figure(
    image("figures/related/NeuroLM_fig3.png", width: 100%),
    caption: [NeuroLM 多通道自回归与指令微调（图源）。],
  ),
  figure(
    image("figures/related/UniMind_fig2.png", width: 100%),
    caption: [UniMind 任务感知 query 选择（图源）。],
  ),
)

#figure(
  image("figures/related/ECHO_fig2.png", width: 55%),
  caption: [ECHO 带支持样本的序列到序列解码（图源）。],
) <fig:echo>

== 潜在预测与结构化表征（非 EEG 领域）

JEPA-Anything 提出正交预测分解（OPF），把潜在空间分为若干相互正交的可学习子空间，并用正交约束防止信息混叠。H-JEPA 按时间分层的世界模型，探测显示层级越高越丢弃快变特征。这些工作给出了两件 EEG 基础模型尚未系统使用的工具：*正交子空间*（让不同因素可分离、可检查）和*按尺度分层的潜在预测*（让不同时间尺度各有位置）。

#grid(
  columns: (1fr, 1fr),
  gutter: 8pt,
  figure(
    image("figures/related/JEPA-Anything_fig1.png", width: 100%),
    caption: [JEPA-Anything 正交预测分解（图源）。],
  ),
  figure(
    image("figures/related/H-JEPA_fig1.png", width: 100%),
    caption: [H-JEPA 按时间分层的世界模型（图源）。],
  ),
)

== 评测基准

OmniEEG-Bench 与本赛事最接近的任务体系。NeuralBench 多任务、多模型的统一评测。AdaBrain-Bench 包含跨被试、少样本及唯一的回归任务。

// ══════════════════════════════════════════════
// 3  方法理解与比较
// ══════════════════════════════════════════════

= 方法理解与比较 <sec:comparison>

== 比较维度

我们从四个维度比较现有方法：(1) *输入统一*——如何处理异构通道、布局和时长；(2) *预训练目标*——各频段得到的监督是否均衡；(3) *读出与适配*——冻结还是微调，读出取哪层；(4) *证据强度*——有受控消融还是只有不同协议下的分数。

== 核心思路、适用条件与局限

#block[
  #set text(size: 8pt)
  #set par(justify: false)
  #figure(table(
    columns: (0.8fr, 1.5fr, 1.5fr, 1.5fr),
    inset: 4pt, stroke: none, align: left,
    table.hline(stroke: 0.8pt),
    table.header([*方法*], [*核心思路*], [*较强证据*], [*局限/未证明*]),
    table.hline(stroke: 0.5pt),
    [EEGNet], [卷积滤波器组 + 空间滤波], [参数极少；小数据表现好], [通道固定；无预训练],
    [LaBraM], [神经 tokenizer + 掩码码预测], [TUEV 上码本目标更优], [TUAB 相反；冻结弱],
    [CBraMod], [空间/时间分离 + ACPE], [criss-cross 优于全注意力], [需全量微调；论文间数值不一致],
    [EEGPT], [掩码重建 + 动量编码器对齐], [对齐损失有明确增益], ["线性探测"含卷积，不可比],
    [CSBrain], [多尺度 token + 稀疏注意力], [16 数据集宏平均高], [消融只有图；不处理 \<1 s],
    [BrainOmni], [传感器编码器 + 潜在源], [去掉传感器嵌入下降], [压缩效果因任务而异],
    [*REVE*], [4D Fourier PE + 块掩码 L1 + 6 万小时], [处理未见布局；冻结较强], [4D PE 相对可学习仅高 0.006；读出影响大],
    [*FAME*], [按频段标准化等权时频目标], [各频段更均衡], [差距小；预训练不含 SSVEP],
    table.hline(stroke: 0.8pt),
  ), caption: [主要方法的核心思路、证据与局限。]) <tab:compare>
]

在这些方法中，*REVE* 整体最强，*FAME* 的训练方法最值得借鉴，但二者架构不同，收益不能直接比较。FAME 图 3(C) 中 REVE 的低频偏置属于较低一档，因此"REVE 的 L1 是否已部分缓解低频偏置"本身需要实验回答。

== 为什么不直接比较公开分数

公开分数之间存在划分、上下文、适配方式、模型选择、复现差异和额外信息六类不可比因素。因此本方案中所有"谁更好"的判断，都以*本赛题的统一协议*下的实验为准。公开分数只用于提出假设。

// ══════════════════════════════════════════════
// 4  研究见解与研究问题
// ══════════════════════════════════════════════

= 研究见解与研究问题 <sec:insight>

== 从调研中形成的见解

+ *下游表现差，未必全是表征的问题。* REVE 换读出方式后差异明显；FAME 最佳层在中间层；多个模型冻结后弱但微调后可用。
+ *表征中有没有神经科学结构，目前没人能回答。* Neuro-KE 证明 EEG 描述子既能*检查*也能*监督*表示。
+ *关键信息分布在不同频段和尺度上，但现有表征把它们混在一起。* FAME 证明监督不均衡；CSBrain 证明尺度重要；但没有模型能说清某任务用了哪个频段、哪个尺度。
+ *频段与尺度相关但不等价。* 同一频段的活动强度可以在秒级缓慢变化；二者的约束是时间–频率不确定性：短窗口无法表示低频。
+ *贡献应来自方法，不是推翻架构。* REVE 的坐标式位置编码与任意布局支持已经是最强公开基础；改进应"保留其权重、在其上拼接"。

== 研究问题 <sec:rq>

#block(inset: (left: 1.2em, right: 1.2em, top: 0.5em, bottom: 0.5em), fill: luma(248), radius: 3pt)[
  #set par(first-line-indent: 0em)
  *总问题：* 把 EEG 表征组织成"以频段为锚、在多个尺度上表达、由任务按需读取"的结构，能否在不牺牲通用性的前提下提高跨任务、跨被试的下游表现，并让表征可以被检查？
]

- *RQ1（表征）：* REVE 的各层表示在哪些频段、哪些尺度上保留了可恢复的生理描述子？下游差距有多少来自表征，有多少来自读出？
- *RQ2（方法）：* 在继续预训练中加入"频段锚定 + 自由"的混合正交子空间与跨尺度注意力，能否提高 14 个下游数据集的 BACC？
- *RQ3（任务）：* 不同任务学到的"频段 × 尺度"门控权重是否与已知神经生理规律一致？自由子空间是否学到了已知描述子解释不了的信息？

RQ1 是"诊断"，RQ2 是"改进"，RQ3 检验可解释性。三者都可以在复赛中回答，结果决定决赛设计。

// ══════════════════════════════════════════════
// 5  方法设计
// ══════════════════════════════════════════════

= 方法设计 <sec:method>

== 整体框架 <sec:framework>

#par(first-line-indent: 0em)[*一句话概括：*]
保留 REVE 编码器，在其上拼接三个结构——频段锚定与自由的混合正交子空间、可变长度 patch 与零初始化跨尺度注意力、任务门控读出——所有新增模块*零初始化或门控残差接入*，使继续预训练第 0 步与原版 REVE 完全一致。

#figure(
  image("figures/fig_method_arch.png", width: 95%),
  caption: [本方案架构。蓝：保留 REVE 权重；橙（虚线）：新增模块，零初始化；绿：仅预训练目标；紫：下游适配。],
) <fig:arch>

#par(first-line-indent: 0em)[*组件一：REVE 编码器。*]
22 层、512 维、8 头 Transformer，4D Fourier 位置编码，MIT 许可公开权重。两处兼容性修改：时间坐标改为按秒计的连续时间；增加零初始化尺度嵌入。

#par(first-line-indent: 0em)[*组件二：可变长度 patch 与跨尺度注意力。*]
1 s patch 使用 REVE 原嵌入层；0.5 s、0.25 s 的 patch 使用原嵌入矩阵 $W in bb(R)^(512 times 200)$ 中对应时长的列切片（短片段补零放进 1 s 窗口），频率语义不变。*尺度内注意力*对 1 s 尺度就是 REVE 全注意力，短尺度在同通道局部时间窗内做。*跨尺度注意力*每隔 $k$ 层插入，带 tanh 门控且初值为 0（借鉴 Flamingo）。

#par(first-line-indent: 0em)[*组件三：混合正交子空间。*]
在编码器输出 $z in bb(R)^512$ 上学习投影 $P_k in bb(R)^(512 times r)$，分两类：

- *锚定子空间*（$k in {delta, theta, alpha, beta, gamma}$）：预测被遮 token 在对应频段的描述子（FAME 式对数功率 + Neuro-KE 式扩展）。描述子只在物理上有意义的尺度上计算。
- *自由子空间*：不指定含义，做 JEPA 式潜在预测（EMA 教师以 REVE 初始化），加方差约束防坍缩。

*正交约束*（JEPA-Anything）：

$ cal(L)_"orth" = sum_k norm(P_k^top P_k - I_r)_F^2 + sum_(i<j) norm(P_i^top P_j)_F^2 $ <eq:orth>

保证子空间几何不重叠，但不保证统计独立。初始维度 $r = 48$：5 个锚定共 240 维，4 个自由共 192 维，剩余 80 维不约束。

#par(first-line-indent: 0em)[*预训练总损失：*]

$ cal(L) = underbrace(sum_(k in "band") cal(L)_"desc"^((k)), "锚定") + lambda_f underbrace(sum_(j in "free") cal(L)_"latent"^((j)), "自由") + lambda_"orth" cal(L)_"orth" + lambda_"keep" cal(L)_"keep" $ <eq:loss>

$cal(L)_"keep"$ 用特征蒸馏（对冻结原版 REVE）防止遗忘。

#par(first-line-indent: 0em)[*组件四：任务门控读出。*]
每个下游数据集学习 $g in bb(R)^(K times S)$（子空间 × 尺度，softmax 归一化），对子空间表示加权后送入分类头。门控权重即 RQ3 的分析对象。

== 复赛：基于 REVE 公开权重 <sec:semi>

*第 0 步：诊断（不训练，回答 RQ1）。* (1) 冻结 REVE 各层表示做频段 × 尺度线性探测，得可恢复性图；(2) 14 个数据集上比较不同复杂度读出，定位读出瓶颈；(3) 按 REVE 官方流程微调建立基线。

*第 1 步：继续预训练（RQ2）。* 数据为 14 个下游训练集被试（不使用标签，验证/测试被试绝不进入）。阶段 1 冻结 REVE 只训新模块；阶段 2 解冻编码器，按层衰减学习率，每 batch 随机抽 patch 长度组合。

*第 2 步：下游适配。* 两段式——先冻结编码器训练门控与分类头，再全量微调。所有超参按验证集 BACC 选择。

#figure(
  image("figures/fig_pipeline.png", width: 92%),
  caption: [两阶段研究流程：复赛回答 RQ1–RQ3，决赛按结果设计。],
) <fig:pipeline>

== 决赛：从零预训练 <sec:final>

不得加载任何预训练权重；能带入决赛的是复赛验证过的*目标、结构与比例*。语料为官方 21 个 OpenNeuro 数据集。REVE 式编码器，规模按语料和算力选择。$cal(L)_"keep"$ 换成 L1 波形重建。

== 设计依据与取舍 <sec:rationale>

#block[
  #set text(size: 8pt)
  #set par(justify: false)
  #figure(table(
    columns: (1.2fr, 0.6fr, 2fr, 1.8fr),
    inset: 4pt, stroke: none, align: left,
    table.hline(stroke: 0.8pt),
    table.header([*设计*], [*RQ*], [*为什么可能有效*], [*代价/条件*]),
    table.hline(stroke: 0.5pt),
    [保留 REVE，零初始化], [全部], [起点为当前最强公开模型], [只适用于复赛],
    [频段锚定子空间], [1, 2], [各频段独立监督（FAME）；描述子提高 BAcc（Neuro-KE +2.60）], [描述子需预计算；短窗口无法表示低频],
    [自由子空间 + 潜在预测], [2, 3], [学习先验之外的信息], [坍缩风险；含义需事后探测],
    [正交约束], [2], [防止子空间互相复制], [只约束几何关系],
    [可变 patch + 跨尺度注意力], [2], [SSVEP 的 1 s 输入从 1 token 变多个], [短 patch 增加计算量],
    [任务门控读出], [3], [不同任务依赖不同频段与尺度], [门控可能塌缩],
    [特征蒸馏防遗忘], [—], [继续预训练数据远少于 6 万小时], [蒸馏太强限制改进],
    table.hline(stroke: 0.8pt),
  ), caption: [设计依据与取舍。]) <tab:design>
]

*复赛结果如何影响决赛：* 若锚定贡献大而自由贡献小，提高锚定比例；若自由贡献明显且超出已知描述子，保留大自由子空间；若跨尺度注意力只在短时任务有效，只为该类任务启用短 patch；若瓶颈在读出，决赛重心转向门控读出；若继续预训练对照与完整方法持平，说明收益来自领域适应。

// ══════════════════════════════════════════════
// 6  实验与消融计划
// ══════════════════════════════════════════════

= 实验与消融计划 <sec:experiment>

== 整体实验设计

*统一协议：* 被试 8:1:1；3 个指定种子；验证集 BACC 选权重；测试集报告三种子均值 ± 标准差，并报 PR-AUC、ROC-AUC 和 F1。每个配置 14 数据集 × 3 种子 = 42 次运行。

#block[
  #set text(size: 8pt)
  #set par(justify: false)
  #figure(table(
    columns: (1fr, 1.3fr, 2fr),
    inset: 4pt, stroke: none, align: left,
    table.hline(stroke: 0.8pt),
    table.header([*类别*], [*模型*], [*作用*]),
    table.hline(stroke: 0.5pt),
    [从零有监督], [EEGNet, EEG Conformer], [专用小模型参照],
    [公开基础模型], [LaBraM, CBraMod, REVE], [统一协议分数],
    [*关键对照*], [*REVE + 只用原目标继续预训练*], [区分"方法本身"与"领域适应"],
    [本方法], [REVE + 混合子空间 + 跨尺度 + 门控], [—],
    table.hline(stroke: 0.8pt),
  ), caption: [实验基线。关键对照使用相同数据与步数。]) <tab:baseline>
]

== 消融与对照 <sec:ablation>

#block[
  #set text(size: 8pt)
  #set par(justify: false)
  #figure(table(
    columns: (0.5fr, 2fr, 1.5fr, 1.5fr),
    inset: 4pt, stroke: none, align: left,
    table.hline(stroke: 0.8pt),
    table.header([*编号*], [*变体*], [*检验的问题*], [*控制条件*]),
    table.hline(stroke: 0.5pt),
    [A0], [REVE 原版], [分数下限], [—],
    [A1], [只用原目标继续预训练], [收益是否来自额外训练], [数据、步数相同],
    [A2], [全锚定（无自由子空间）], [先验够不够], [总维度相同],
    [A3], [全自由（无锚定）], [先验是否必要], [同上],
    [A4], [混合，去掉正交约束], [正交是否必要], [同上],
    [A5], [固定 1 s patch], [可变 patch 的贡献], [步数相同],
    [A6], [有短 patch 但无跨尺度注意力], [是否需跨尺度共享], [同上],
    [A7], [全尺度 token 做全注意力], [跨尺度门控 vs 代价上限], [另报计算量],
    [A8], [门控读出 → 普通池化], [任务门控的贡献], [同一预训练模型],
    [A9], [特征蒸馏 → L1 重建], [防遗忘方式选择], [同上],
    table.hline(stroke: 0.8pt),
  ), caption: [消融实验设计。每个变体仅改变一个变量。]) <tab:ablation>
]

*可解释性检验：* (1) 带限扰动——滤掉某频段检查对应锚定子空间变化是否显著大于其他；(2) 自由子空间探测——用描述子探测，不可解释方差比例为"超出先验"的度量；(3) 门控权重与生理规律对照。

*算力受限优先级：* A1、A2、A3、A5 跑全部 14 个数据集；其余先在每个分赛道选 1 个数据集（共 7 个）。

== 实验判读思路

- *支持*：完整方法相对 A1 在多数分赛道提高 BACC 且超过标准差；A2、A3 均低于混合；门控权重与生理规律一致。
- *不支持*：与 A1 持平（收益来自适应）；可解释性检验失败（各子空间同等变化）。
- *任务差异*：按分赛道报告，通过门控或按任务选择 patch 长度。
- *波动*：标准差大于差异时不下结论。

// ══════════════════════════════════════════════
// 7  算力需求
// ══════════════════════════════════════════════

= 算力需求 <sec:compute>

#block[
  #set text(size: 8pt)
  #set par(justify: false)
  #figure(table(
    columns: (1.2fr, 2fr, 2fr),
    inset: 4pt, stroke: none, align: left,
    table.hline(stroke: 0.8pt),
    table.header([*阶段*], [*内容*], [*估算*]),
    table.hline(stroke: 0.5pt),
    [复赛 第 0 步], [冻结表示的探测与读出对照], [前向为主，约数十 GPU 小时],
    [复赛 第 1 步], [继续预训练（若按种子 ×3）], [REVE Base 完整预训练约 260 A100 h，继续预训练远小于此],
    [复赛 第 2 步], [42 次微调 × 约 15 个配置], [单次微调时长待短测],
    [决赛], [21 个数据集从零预训练 + 42 次微调], [取决于语料时长与官方配额],
    table.hline(stroke: 0.8pt),
  ), caption: [算力需求估算。GPU 型号、显存、卡数待官方公布。]) <tab:compute>
]

// ══════════════════════════════════════════════
// 8  数据来源与复现说明
// ══════════════════════════════════════════════

= 数据来源与复现说明 <sec:data>

- *数据*：复赛只使用官方 14 个下游数据集及 REVE 公开权重（MIT 许可）；决赛只使用官方 21 个预训练数据集。不使用私有数据。
- *防泄漏*：继续预训练只使用训练集被试；验证、测试被试不参与任何预训练或调参。
- *复现*：固定 3 个官方种子；超参数、步数和选择规则写入配置文件；代码基于 REVE 官方仓库修改，随复赛提交。

// ══════════════════════════════════════════════
// 参考文献
// ══════════════════════════════════════════════

#pagebreak()

#heading(numbering: none)[参考文献]

#set par(first-line-indent: 0em)
#set text(size: 9pt)

+ Lawhern _et al._ EEGNet: A Compact CNN for EEG-based BCIs. _J. Neural Eng._, 2018.
+ Song _et al._ EEG Conformer: Convolutional Transformer for EEG Decoding. _IEEE TNSRE_, 2023.
+ Kostas _et al._ BENDR: Using Transformers and Contrastive Self-supervised Learning. _Front. Hum. Neurosci._, 2021.
+ Yang _et al._ BIOT: Cross-data Biosignal Learning in the Wild. _NeurIPS_, 2023.
+ Jiang _et al._ LaBraM: Large Brain Model for Learning Generic Representations. _ICLR_, 2024.
+ Wang _et al._ EEGPT: Pretrained Transformer for Universal EEG Representation. _NeurIPS_, 2024.
+ Wei _et al._ CBraMod: A Criss-Cross Brain Foundation Model. _ICLR_, 2025.
+ BrainOmni: A Foundation Model for Any-to-Any Brain Signal Conversion. 2025.
+ CSBrain: Cross-Scale Brain Transformer. 2025.
+ El Ouayas _et al._ REVE: Robust EEG Vision Encoder. 2025.
+ FAME: Understanding and Correcting Low-Frequency Bias in EEG Representation Learning. 2026.
+ NeuroLM: A Universal Multi-task Foundation Model for Bridging Language and EEG. 2025.
+ UniMind: Unified Multi-task Brain Decoding with Multi-level Alignment. 2025.
+ ECHO: EEG Channel-wise Hypernetwork Organization for In-context Learning. 2025.
+ Chen _et al._ Neuro-KE: Knowledge-Guided Interfaces for EEG Foundation Models. _NeurIPS_, 2026.
+ JEPA-Anything: Orthogonal Predictive Factorization for JEPAs. 2025.
+ H-JEPA: Hierarchical World Model for Time Series. 2025.
+ OmniEEG-Bench: A Comprehensive Benchmark for EEG Foundation Models. 2026.
+ NeuralBench: A Multi-task Benchmark for Neural Signal Decoding. 2025.
+ AdaBrain-Bench: Adaptive Evaluation Framework for EEG BCIs. 2025.
+ Alayrac _et al._ Flamingo: A Visual Language Model for Few-shot Learning. _NeurIPS_, 2022.
