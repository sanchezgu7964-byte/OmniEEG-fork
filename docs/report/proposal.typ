// OmniEEG Challenge 2026 初赛研究方案
// 编译：python3 -c "import typst; typst.compile('docs/report/proposal.typ', output='docs/report/proposal.pdf')"

#let accent = rgb("#1a4e8a")

#set page(paper: "a4", margin: (x: 23mm, top: 23mm, bottom: 22mm))
#set text(font: ("Noto Serif CJK SC",), size: 10pt, lang: "zh", region: "cn")
#set par(justify: true, leading: 0.55em, first-line-indent: 1.2em)
#set heading(numbering: "1.1")
#set math.equation(numbering: "(1)")

#show heading: it => {
  if it.level == 1 {
    set text(size: 13pt, weight: "bold", fill: accent)
    v(0.8em)
    it
    v(0.3em)
  } else if it.level == 2 {
    set text(size: 10.5pt, weight: "bold", fill: accent)
    v(0.5em)
    it
    v(0.2em)
  } else {
    it
  }
}

#set figure(gap: 5pt)

// ── 封面 ──

#v(12mm)
#align(center)[
  #set par(justify: false)
  #text(size: 10pt, fill: accent, tracking: 0.5pt, weight: "bold")[OMNIEEG CHALLENGE 2026 · 主赛道初赛研究方案]
  #v(12mm)
  #text(size: 18pt, weight: "bold", fill: accent)[面向跨任务 EEG 基础模型的 \ 频段正交子空间预测学习]
  #v(5mm)
  #text(size: 10.5pt, style: "italic", fill: accent)[Frequency-Orthogonal Subspace Predictive \ Learning for Cross-Task EEG Foundation Models]
  #v(10mm)
  #line(length: 60%, stroke: 0.5pt + accent)
  #v(4mm)
  #grid(
    columns: (auto, auto),
    column-gutter: 1em,
    row-gutter: 0.8em,
    align: (right, left),
    text(fill: accent, weight: "bold")[队伍], [Oracula],
    text(fill: accent, weight: "bold")[队员], [汪士楠 #h(0.6em) 仇心妍 #h(0.6em) 吴牧希],
    text(fill: accent, weight: "bold")[提交日期], [2026 年 11 月 15 日],
  )
]

#v(8mm)

// 摘要框
#block(fill: luma(245), inset: (x: 12pt, top: 10pt, bottom: 10pt), radius: 2pt, width: 100%)[
  #set par(first-line-indent: 0pt, justify: true)
  #align(center)[#text(weight: "bold", size: 10pt)[摘要]]
  #v(3pt)
  #set text(size: 9.5pt)
  当前脑电（EEG）基础模型在运动想象与稳态视觉诱发电位（SSVEP）等节律性任务上表现突出，但在神经精神疾病诊断等病理任务上仍大幅落后于专用小模型。针对这一现象，本方案提出"先诊断，后改进"的递进式研究框架：首先，通过冻结表征的"频段 $times$ 尺度"可恢复性探测图与读出瓶颈对照实验，系统定位当前最强公开基座 REVE 在各频段、各时间尺度下的信息保留程度与解码损耗；其次，在不破坏原有表征能力的前提下，于 REVE 编码器之上拼接三个零初始化或门控残差模块——频段锚定与自由特征的混合正交子空间、列切片可变长度 Patch 与门控跨尺度注意力、以及任务门控读出头——借助继续预训练向表征空间注入结构化频段监督与潜在预测目标。其中，正交投影约束在几何上隔离不同因子以防止特征混叠，任务门控权重则使"各下游任务究竟依赖何种频段与时间尺度"得以显式量化与生理学检验。在赛程推进上，复赛阶段基于 REVE 公开权重（MIT 许可）完成诊断、架构验证与消融；决赛阶段则将复赛锁定的最优子空间配比与预训练目标迁移至官方 21 个数据集上从零预训练。实验部分设计了 10 组受控消融（A0–A9）以严格剥离领域适应与结构创新之贡献，并辅以带限频谱扰动与描述子回归探测实验验证表征可解释性。

  #v(3pt)
  *关键词：*EEG 基础模型；频段正交子空间；潜在预测学习；跨尺度门控注意力；任务门控读出；REVE
]

#pagebreak()
#counter(page).update(1)
#set page(
  footer: context {
    set text(size: 8pt, fill: luma(100))
    grid(
      columns: (1fr, auto),
      [OmniEEG Challenge 2026 主赛道初赛研究方案 · 频段正交子空间预测学习],
      [Page #counter(page).display()],
    )
  },
)
#outline(title: [#text(fill: accent)[目录]], depth: 2)
#pagebreak()

// ══════════════════════════════════════════════
// 1  赛道选择与研究动机
// ══════════════════════════════════════════════

= 赛道选择与研究动机 <sec:motivation>

== 为什么选主赛道

本赛事的 7 个分赛道覆盖信号可靠性、疾病诊断、睡眠分期、认知与情绪、自然刺激解码、运动想象（MI）和稳态视觉诱发电位（SSVEP）等典型任务；14 个下游数据集的导联配置跨度为 4 至 128 通道，单样本时长从 1 秒延伸至 30 秒。分赛道比拼的是特定范式下的单点上限，而主赛道直面神经工程落地的核心命题——同一基础模型能否同时突破跨布局、跨时间尺度与跨范式三重壁垒。

归根结底，脑机接口的终极愿景不在于针对每个个体和任务反复"事后拟合"，而在于模型预先具备大脑通用的时空节律与生理表征，从而在新任务、新设备与新个体面前实现按需泛化。这正是"EEG 基础模型"得以成立的根本前提，亦是本方案直面的核心科学问题，故我们选择主赛道。

== 问题的由来：从任务专用模型到基础模型

#par(first-line-indent: 0em)[*传统专用模型的局限：*]
经典 EEG 解码通常针对单一实验范式手工设计带通滤波、空间投影与分类器。以 EEGNet~\[1\] 为代表的紧凑型卷积网络虽将"时域滤波器组 + 深度空间滤波"内嵌于网络拓扑中，但因其第一层空间卷积核绑定输入通道数，时间切分、滤波困难，参数量小，导致模型无法学会可跨电极布局迁移的生理表征，难以完成高级认知功能相关的任务。

#par(first-line-indent: 0em)[*EEG 信号的固有物理挑战：*]
脑电信号信噪比极低；不同采集设备与公开数据集在电极数量、三维空间坐标、参考电极方案、采样率及窗口时长上高度异构；跨被试个体生理差异显著；此外，头皮 EEG 功率谱密度近似服从 $1 slash f^alpha$ 律分布，能量高度集中于低频段，而高质量有标注数据往往仅有数十小时。

#par(first-line-indent: 0em)[*现有基础模型的探索：*]
为突破上述瓶颈，学界近年提出了一系列大规模自监督预训练架构：BIOT~\[4\] 将逐通道频谱片段展平为统一序列；LaBraM~\[5\] 引入神经词表（Neural Tokenizer）预测离散量化码；CBraMod~\[7\] 利用十字交叉（Criss-Cross）注意力解耦时空依赖；REVE~\[10\] 借助电极三维坐标的 4D Fourier 位置编码实现任意导联布局适配，并在约 6 万小时多源语料上完成预训练；FAME~\[11\] 则进一步将重建目标修正为按频段独立标准化的时频活动，以缓解功率谱失衡。

== 当前 EEG 基础模型亟待解决的四大瓶颈 <sec:problems>

尽管预训练规模持续扩大，现有 EEG 基础模型在通用性上仍存在显著短板，突出表现为跨任务准确率不稳定、表征空间缺乏结构化可解释性、真实跨被试泛化验证不足，以及评测协议不统一。归根结底，当前领域尚缺乏对三个根本问题的系统诊断：模型究竟学到了什么特征、哪些结构设计真正产生了增益，以及评测指标在多大程度上反映了表征质量。以下结合公开基准证据逐一剖析：

#par(first-line-indent: 0em)[*(1) 准确率未能达到专用小模型的能力上限：*]
在 NeuralBench~\[19\] 统一微调协议的同一测试快照下，REVE 在运动想象（68.0%，排名第 1）和 SSVEP（96.1%，排名第 2）上表现优异，但在精神分裂症识别上平衡准确率（BACC）仅为 43.7%，落后最佳专用网络 ATCNet（72.9%）达 29.2 个百分点；在癫痫发作检测上（77.6%），亦落后于专用架构 BDTCN（85.5%）7.9 个百分点（详见表~#ref(<tab:neuralbench>, supplement: none)）。同时，"更大参数量与更多预训练数据"并不必然带来单调收益——例如 LaBraM 在 TUAB 数据集上的规模实验中，500 小时预训练的 Base 模型反而优于 2500 小时版本；FAME 亦报告扩大语料或模型容量后下游性能存在显著波动。

#block[
  #set text(size: 8pt)
  #set par(justify: false)
  #figure(table(
    columns: (1.4fr, 0.8fr, 1.4fr, 0.8fr, 0.7fr),
    inset: 4pt, stroke: none, align: left,
    table.hline(stroke: 0.8pt),
    table.header([*下游任务类别*], [*REVE (%)*], [*该任务最佳模型*], [*最佳分数 (%)*], [*差距 (Δ)*]),
    table.hline(stroke: 0.5pt),
    [精神分裂症识别], [43.7], [ATCNet（专用网络）], [72.9], [−29.2],
    [视听刺激解码], [51.2], [Handcrafted（手工特征）], [63.0], [−11.8],
    [c-VEP 解码], [79.1], [LaBraM（基础模型）], [87.6], [−8.5],
    [癫痫发作检测], [77.6], [BDTCN（专用网络）], [85.5], [−7.9],
    [帕金森病识别], [69.5], [BIOT（基础模型）], [77.4], [−7.9],
    [心理想象], [25.6], [ShallowFBCSPNet], [33.1], [−7.5],
    [认知负荷评估], [67.8], [ShallowFBCSPNet], [74.7], [−6.9],
    [痴呆症识别], [40.9], [Handcrafted（手工特征）], [47.6], [−6.7],
    [睡眠觉醒检测], [55.8], [LUNA], [59.6], [−3.8],
    [异常 EEG 筛查（TUAB）], [78.1], [BENDR], [81.8], [−3.7],
    [运动想象 / SSVEP], [68.0 / 96.1], [REVE / 专用最优], [68.0 / 96.6], [0.0 / −0.5],
    table.hline(stroke: 0.8pt),
  ), caption: [NeuralBench~\[19\] 统一微调协议下 REVE 与各任务最佳模型的平衡准确率（BACC）对比（数据源：NeuralBench 官方提交 fe31393），按落后幅度排序。]) <tab:neuralbench>
]

#par(first-line-indent: 0em)[*(2) 冻结表征普遍偏弱，低频偏置与读出混叠并存：*]
现有基础模型高度依赖下游全量微调，冻结表征的线性可分性较差（如 LaBraM 在 TUEV 上线性探测仅为 0.346，全量微调升至 0.641；CBraMod 冻结后在 PhysioNet-MI 上仅为 0.385；BrainOmni~\[8\] 冻结后在 TUEV 上由 0.618 降至 0.489）。FAME~\[11\] 从机理上揭示了低频偏置（Low-Frequency Bias）：由于 $1 slash f$ 谱特性，原始时域 MSE 重建损失按信号功率加权，导致编码器优先拟合低频慢波而丢失高频细节。另一方面，下游性能受限未必全因表征缺失——REVE 同一冻结编码器仅将读出方式由"全 Token 展平"切换为"全局池化"，在 Faced 上即提升 18.2%，在 BCIC2020-3 上提升 15.6%，而在 TUEV 上却下降 8.4%（REVE Table 4）；FAME 的最佳探测层亦位于第 9 层而非末层。这表明表征瓶颈与读出瓶颈长期被混为一谈。此外，Neuro-KE~\[15\] 证明，将无需人工标注的 EEG 描述子转化为掩码预训练数值目标，平均提升 BACC 2.60 个百分点，印证了结构化领域先验的有效性。

#par(first-line-indent: 0em)[*(3) 跨被试与连续回归泛化验证不充分：*]
同一 EEG Conformer~\[2\] 在 BCI IV-2a 上被试内准确率 78.7%，跨被试骤降至 47.0%。在 AdaBrain-Bench~\[20\] 的跨被试连续回归任务 SEED-VIG 中，多数基础模型甚至未能超越从零训练的轻量级 EEGNet（见表~#ref(<tab:seedvig>, supplement: none)）。在零样本跨被试方面，UniMind~\[13\] 明确声明未考察对完全未见被试的泛化，而 ECHO~\[14\] 的上下文学习则需在推理阶段引入测试被试本人的带标签支持样本。

#block[
  #set text(size: 8pt)
  #set par(justify: false)
  #figure(table(
    columns: (1.5fr, 2fr, 1fr),
    inset: 4pt, stroke: none, align: left,
    table.hline(stroke: 0.8pt),
    table.header([*模型名称*], [*模型类型*], [*测试集 R² (%)*]),
    table.hline(stroke: 0.5pt),
    [EEGNet \[1\]], [专用轻量卷积网络（从零训练）], [26.65],
    [BIOT \[4\]], [频谱 Token 基础模型], [27.09],
    [LaBraM \[5\]], [离散码本基础模型], [25.35],
    [EEGPT \[6\]], [潜在对齐基础模型], [23.47],
    [CBraMod \[7\]], [时空分离基础模型（原文自报 33.7%）], [2.40],
    table.hline(stroke: 0.8pt),
  ), caption: [AdaBrain-Bench 跨被试连续回归任务 SEED-VIG（全量微调）决定系数 R² 对比（数据源：AdaBrain-Bench~\[20\] Table 2）。]) <tab:seedvig>
]

#par(first-line-indent: 0em)[*(4) 跨文献评测协议失准，公开分数不可直接横向比较：*]
不同论文在被试划分方式、上下文窗口长度、微调学习率策略、早停验证集选取及额外导联先验等条件上存在不可比偏差，本方案规定：公开文献分数仅用于提出科学假设，所有关于"方法优劣与模块有效性"的最终判据，均严格以 OmniEEG 统一协议下的受控对照实验为准。

== 研究切入点：三层递进诊断范式 <sec:rq-preview>

基于上述剖析，本方案摒弃"盲目堆叠大模块"的工程惯性，确立"先诊断，后改进"的研究路径，从三个递进层次展开剖析：(1) 表征层——基础模型各层究竟在多大程度上保留了不同频段、不同时间尺度的神经生理特征？(2) 设计层——哪些模块设计真正契合 EEG 物理特性并具有数学支撑，哪些仅是架构冗余？(3) 评测层——下游增益究竟源于预训练表征质量的实质跃升，还是仅来自读出方式调整或下游分布适应？OmniEEG 主赛道统一的数据划分、固定随机种子以及横跨 7 大范式的任务矩阵，恰好为检验改进的普适性提供了理想的受控实验场。

// ══════════════════════════════════════════════
// 2  相关工作
// ══════════════════════════════════════════════

= 相关工作梳理（按核心科学问题组织） <sec:related>

== 任务专用有监督基线

EEGNet~\[1\] 通过时间卷积与深度可分离空间卷积实现"时频滤波 + 频段特异空间滤波"，参数量仅约 1k–2k，在小样本范式下极为稳健；EEG Conformer~\[2\] 在卷积前端之上叠加 6 层 Transformer 以兼顾局部频谱与全局时序依赖。二者是衡量基础模型是否真正超越专用网络的基准必选对照，已纳入本方案的必要参照。

== EEG 基础模型如何统一异构输入

如表~#ref(<tab:input>, supplement: none) 所示，现有基础模型主要沿"时间切片分块（Patching）"与"通道空间编码"两条主线统一异构输入。REVE~\[10\] 指出，早期基于 TUH 固定 19/21 导联训练的模型（如采用电极编号查表嵌入的 LaBraM~\[5\]），在面对未见过的脑电帽布局时泛化受限；而 REVE 采用基于电极三维物理坐标与时间的 4D Fourier 连续位置编码，配合 92 个数据集、约 6 万小时多布局语料预训练，在任意导联配置下均展现出最优的冻结表示迁移能力。

#block[
  #set text(size: 8pt)
  #set par(justify: false)
  #figure(table(
    columns: (1.2fr, 2fr, 1.5fr),
    inset: 4pt, stroke: none, align: left,
    table.hline(stroke: 0.8pt),
    table.header([*代表工作*], [*输入序列化与时空统一方式*], [*通道 / 空间位置编码机制*]),
    table.hline(stroke: 0.5pt),
    [BIOT (NeurIPS 2023) \[4\]], [逐通道提取 FFT 频谱能量 Token，线性注意力], [固定通道索引查表嵌入],
    [LaBraM (ICLR 2024) \[5\]], [通道 × 1 秒时域 Patch 序列], [标准电极名称编号查表],
    [CBraMod (ICLR 2025) \[7\]], [通道 × 时间 Patch，空间与时间注意力并行交替], [非对称条件位置编码（ACPE）],
    [EEGPT (NeurIPS 2024) \[6\]], [先跨通道聚合、再跨时间建模的分层编码结构], [标准通道名码本嵌入],
    [BrainOmni (2025) \[8\]], [传感器编码器 + 交叉注意力映射至 16 个潜在脑源], [传感器三维坐标、朝向与类型编码],
    [CSBrain (2025) \[9\]], [跨尺度时空 Token 化（CST）+ 结构化稀疏注意力（SSA）], [基于解剖脑区的拓扑分组],
    [REVE (2025) \[10\]], [保留全部观测通道（1 秒 Patch），全局自注意力], [三维电极坐标 + 时间的 4D Fourier 编码],
    table.hline(stroke: 0.8pt),
  ), caption: [代表性 EEG 基础模型的异构输入统一机制与空间编码对比。]) <tab:input>
]

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

== 预训练预测目标与领域知识注入

在自监督目标设计上（表~#ref(<tab:pretrain>, supplement: none)），原始时域重建（REVE~\[10\]、CBraMod~\[7\]）直观但受因于 $1 slash f$ 功率谱加权，易放大低频监督、抑制高频表征。离散码预测（LaBraM~\[5\]、BrainOmni~\[8\]）依赖两阶段 tokenizer 训练且消融结论分裂；潜在表示对齐（EEGPT~\[6\]、S-JEPA）在表示空间施加动量教师约束，在 BCIC-2A 上展现出明确增益（去掉对齐损失后由 0.585 降至 0.529）。

近期最具启发性的突破来自领域知识显式监督：FAME~\[11\] 将重建目标转换为各频段对数功率独立标准化后的时频活动，强制高频与低频获得等权监督（13 项任务平均达 61.4%）；Neuro-KE~\[15\] 则直接从无标注 EEG 中计算生理描述子作为掩码预训练数值目标，平均提升 BACC 2.60%。本方案与二者的核心区别在于：我们不仅引入频段生理描述子作为监督信号，更进一步将表征空间显式解耦为"频段锚定 + 自由预测"的正交子空间矩阵（频段 $times$ 尺度），使下游任务能够通过可读的门控权重按需检索特定生理因子。

#block[
  #set text(size: 8pt)
  #set par(justify: false)
  #figure(table(
    columns: (1fr, 1.2fr, 2.5fr),
    inset: 4pt, stroke: none, align: left,
    table.hline(stroke: 0.8pt),
    table.header([*预训练预测对象*], [*代表工作*], [*核心机制与已知局限*]),
    table.hline(stroke: 0.5pt),
    [原始时域波形], [REVE \[10\], CBraMod \[7\]], [端到端简单直接；但 MSE 损失按功率谱加权，易放大低频监督、抑制高频表征],
    [离散量化码本], [LaBraM \[5\], BrainOmni \[8\]], [避免像素级波形噪声；但需额外训练 VQ Tokenizer，码本利用率与消融表现不稳定],
    [频段标准化时频活动], [FAME (2026) \[11\]], [按频段对数功率独立归一化实现等权监督，显著抑制低频偏置，但尚未显式分离表子空间],
    [潜在表示空间预测], [EEGPT \[6\], S-JEPA], [在抽象表征空间对齐目标，滤除无关波形细节；去掉对齐损失后下游性能显著下滑],
    [对比学习预测], [BENDR \[3\], BIOT \[4\]], [通过负样本对比规避逐点重建；BENDR 作者指出其在多数判别任务上仍不及专用模型],
    table.hline(stroke: 0.8pt),
  ), caption: [EEG 基础模型自监督预训练目标的技术路线对比。]) <tab:pretrain>
]

#grid(
  columns: (1fr, 1fr),
  gutter: 8pt,
  figure(
    image("figures/related/FAME_fig2.png", width: 100%),
    caption: [FAME：传统波形重建 vs 按频段平衡的重建（图源：FAME Fig. 2）。],
  ),
  figure(
    image("figures/related/FAME_fig3.png", width: 100%),
    caption: [现有预训练编码器偏向低频（图源：FAME Fig. 3）。],
  ),
)

== 多任务解码器与非 EEG 领域的结构化潜在预测借鉴

在多任务解码端，NeuroLM~\[12\]、UniMind~\[13\] 与 ECHO~\[14\] 尝试引入大语言模型（LLM）或上下文序列解码器以打通多任务输出，但受限于 EEG 编码器本身的频段混叠，其跨任务竞争力仍有限（NeuroLM 整体低于 LaBraM，UniMind 仅微弱领先 0.94%）。

与此同时，通用自监督领域的两项前沿进展为解决上述结构难题提供了关键工具：JEPA-Anything~\[16\] 提出正交预测分解（Orthogonal Predictive Factorization, OPF），通过正交投影约束将潜在空间划分为若干互不重叠的功能子空间，有效防止不同物理因素在表征维度上发生坍缩与复制；H-JEPA~\[17\] 构建了按时间粒度分层的世界模型，其线性探测证实高层表征会自然滤除快变瞬态噪声而保留慢变语义。二者分别对应 EEG 建模中亟待引入的"频段正交解耦"与"多时间尺度分层表达"。

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

// ══════════════════════════════════════════════
// 3  方法理解与比较
// ══════════════════════════════════════════════

= 现有方法的系统评估与比较基准确立 <sec:comparison>

== 四维比较框架与核心局限

我们从 (1) 输入统一能力、(2) 频段监督均衡度、(3) 读出与适配机制 以及 (4) 消融证据强度四个维度对现有方法进行综合评估（表~#ref(<tab:compare>, supplement: none)）。综合对比可见，REVE 具备最强的多布局几何泛化基座与 6 万小时预训练先验，而 FAME 与 Neuro-KE 的频段均衡与生理描述子监督最具互补价值。值得注意的是，FAME 论文分析显示 REVE（采用 L1 重建与全局辅助目标）的低频偏置已处于较低水平，因此"REVE 现有表征在各频段、各尺度上的真实信息保留度"不能仅凭推测，必须通过受控诊断实验予以实测回答。

#block[
  #set text(size: 8pt)
  #set par(justify: false)
  #figure(table(
    columns: (0.8fr, 1.5fr, 1.5fr, 1.5fr),
    inset: 4pt, stroke: none, align: left,
    table.hline(stroke: 0.8pt),
    table.header([*模型名称*], [*核心架构与训练思路*], [*已验证的较强证据*], [*核心局限与未解问题*]),
    table.hline(stroke: 0.5pt),
    [EEGNet \[1\]], [深度可分离时空卷积滤波器组], [参数极少，小样本范式下极其稳健], [空间核绑定固定导联数，无法利用无标注预训练],
    [LaBraM \[5\]], [神经 Tokenizer + 掩码离散码预测], [TUEV 上码本预测显著优于直接重建], [TUAB 上结论反转；冻结表征线性可分性弱],
    [CBraMod \[7\]], [时空分离 Criss-Cross 注意力 + ACPE], [时空分离注意力优于常规全局注意力], [高度依赖全量微调；跨基准自报分数波动大],
    [EEGPT \[6\]], [掩码重建 + 动量编码器潜在对齐], [潜在对齐损失带来明确的下游增益], ["线性探测"实含卷积积层，与其他工作不可比],
    [CSBrain \[9\]], [多尺度时空 Token + 脑区稀疏注意力], [16 个数据集宏平均准确率表现突出], [消融仅给出示意图；不支持短于 1 秒的窗口],
    [BrainOmni \[8\]], [传感器空间编码器 + 潜在脑源投影], [消融证实传感器三维嵌入不可或缺], [压缩至 16 源的信息瓶颈效应因任务而异],
    [REVE \[10\]], [4D Fourier PE + 块掩码 L1 + 6 万小时], [未见导联布局零样本适配；冻结基线最高], [下游对读出方式极度敏感；固定 1 秒 Patch 粒度],
    [FAME \[11\]], [按频段独立标准化的时频活动重建], [各频段表征恢复度均衡，显著抑制低频偏置], [整体涨点幅度有限；预训练语料未涵盖 SSVEP],
    table.hline(stroke: 0.8pt),
  ), caption: [主流 EEG 模型的四维方法学对比与局限性分析。]) <tab:compare>
]

== 为什么不直接采信公开榜单分数

由于各文献在被试划分方式、上下文窗口长度、微调学习率策略、早停验证集选取及额外导联先验等六类条件上存在不可比偏差，本方案规定：公开文献分数仅用于提出科学假设，所有关于"方法优劣与模块有效性"的最终判据，均严格以 OmniEEG 统一协议下的受控对照实验为准。

// ══════════════════════════════════════════════
// 4  研究见解与研究问题
// ══════════════════════════════════════════════

= 核心研究见解与研究问题（RQ） <sec:insight>

== 从文献调研提炼的五项核心见解

+ *下游表现不佳未必全因表征缺陷：* REVE 切换读出方式后的剧烈波动与 FAME 中间层最优现象表明，高维表征内部蕴含的信息常因粗糙的全局池化而被掩盖，必须先将"表征能力"与"读出瓶颈"剥离开来。
+ *神经生理先验兼具"诊断标尺"与"监督锚点"双重价值：* Neuro-KE 证实无需人工标注即可提取的频谱与节律描述子，既可用于探测黑盒表征的物理内涵，也可直接作为结构化预训练目标。
+ *频段与时间尺度信息在现有表征中高度混叠：* FAME 揭示了频段失衡，CSBrain 验证了多尺度价值，但现有模型将所有频段、尺度特征压缩进同一无结构向量，既易引发跨任务梯度冲突，也无法解释模型决策依据。
+ *频段与时间尺度正交相关但不等价：* 同一高频节律（如 $beta$ 或 $gamma$ 波段）的包络能量可在数秒尺度上缓慢调制，而短时间窗（如 0.25 秒）受时间–频率不确定性原理约束无法解析低频（$delta$ 波段）周期，因此二者必须在结构上解耦建模并尊重物理约束。
+ *方法学贡献应立足"无损嫁接"而非推翻最强基座：* REVE 的 4D 坐标编码与大规模预训练权重已构成当前最坚实的通用底座；最稳健的改进路径是保留其主体架构与权重，通过零初始化机制平稳注入结构化子空间与跨尺度交互。

== 研究问题定义 <sec:rq>

#block(inset: (left: 12pt, right: 12pt, top: 8pt, bottom: 8pt), fill: luma(245), radius: 3pt)[
  #set par(first-line-indent: 0em)
  *总科学问题：* 将通用 EEG 表征组织为"以生理频段为正交锚点、在多时间尺度上分层表达、并由下游任务通过可解释门控按需读取"的结构化空间，能否在不牺牲跨布局通用性的前提下，全面提升跨任务、跨被试下游解码性能并实现机理可查？
]

- *RQ1（表征与读出诊断）：* 冻结状态下，REVE 各 Transformer 层的表征在哪些频段、哪些时间尺度上保留了可线性恢复的神经生理描述子？其下游性能差距究竟有多少源于表征信息缺失，又有多少源于读出方式失配？
- *RQ2（方法有效性验证）：* 在继续预训练阶段引入"频段锚定 + 自由特征"的混合正交子空间与零初始化跨尺度注意力，能否在 14 个异构下游数据集上显著且稳定地超越原版 REVE 及纯领域适应基线？
- *RQ3（可解释性与先验边界）：* 不同下游任务学得的"子空间 $times$ 尺度"门控权重分布是否与已知神经生理学规律相吻合？此外，无先验约束的自由子空间是否捕捉到了经典手工描述子所无法解释的有效神经动力学信息？

RQ1 是"诊断"，RQ2 是"改进"，RQ3 检验可解释性。三者都可以在复赛中回答，结果决定决赛设计。

// ══════════════════════════════════════════════
// 5  方法设计
// ══════════════════════════════════════════════

= 方法设计：频段正交子空间预测学习 <sec:method>

== 整体技术框架 <sec:framework>

本方案以 22 层 REVE 编码器（隐藏维度 $d = 512$，8 头自注意力）为骨干底座，在其上无缝拼接三个核心结构模块：(1) 列切片可变长度 Patch 与零初始化门控跨尺度注意力、(2) 频段锚定与自由特征混合正交子空间、以及 (3) 任务感知门控读出头。所有新增交互路径均采用零初始化（Zero-Initialization）或零初值双曲正切门控接入，从而严格保证继续预训练第 0 步的前向输出与原版 REVE 数学等价，避免随机初始化参数在训练初期破坏已有的 6 万小时预训练表征。

#figure(
  image("figures/fig_method_arch.png", width: 95%),
  caption: [本方案架构。蓝：保留 REVE 权重；橙（虚线）：新增模块，零初始化；绿：仅预训练目标；紫：下游适配。],
) <fig:arch>

== 四大核心组件设计

#par(first-line-indent: 0em)[*组件一：兼容性改造的 REVE 编码器基座。*]
保留 REVE 原版 22 层 Transformer 权重与 4D Fourier 位置编码，仅实施两项轻量化兼容性扩展：其一，将位置编码中的离散 Patch 索引替换为以秒为单位的连续物理时间散 $t$，以统一不同采样长度的切片；其二，引入零初始化的尺度嵌入向量 $e_"scale"$，用于标识不同时间粒度的 Token 来源。

#par(first-line-indent: 0em)[*组件二：列切片可变长度 Patch 与门控跨尺度注意力。*]
针对 SSVEP、ERP 等短时瞬态任务在原版 1 秒 Patch 下序列退化为单 Token 的粒度瓶颈，我们在保留原版 1 秒 Patch 嵌入矩阵 $W in bb(R)^(512 times 200)$（200 Hz 采样率）的基础上，直接截取 $W$ 对应前 100 列与前 50 列的子矩阵生成 0.5 秒与 0.25 秒短尺度 Patch（等效于短片段右侧补零后送入 1 秒滤波器组），从而在无需重新随机初始化投影层的同时严格保持频域响应语义不变。在编码器内部，1 秒尺度执行全局时空注意力；短尺度 Patch 在同通道局部时间窗内执行尺度内注意力计算开销；同时，每隔 $k$ 层插入一层门控跨尺度交叉注意力，借鉴 Flamingo~\[21\] 思想引入可学习标量门控 $tanh(alpha)$（初始值 $alpha_0 = 0$），实现多尺度信息的渐进式融合，并在高层通过池化聚合生成 2 秒与 4 秒粗粒度表征以服务于睡眠分期等慢变状态任务。

#par(first-line-indent: 0em)[*组件三：频段锚定与自由特征混合正交子空间。*]
在编码器末层输出表征 $z in bb(R)^512$ 上学习一组线性正交投影矩阵 ${P_k in bb(R)^(512 times r)}$（初始子空间维度设为 $r = 48$），将潜在空间显式划分为三类功能区域：

- *5 个频段锚定子空间*（$k in {delta: 0.5 dash 4 "Hz", theta: 4 dash 8 "Hz", alpha: 8 dash 13 "Hz", beta: 13 dash 30 "Hz", gamma: 30 dash 99.5 "Hz"}$，共 240 维）：强制投影后的子空间表征 $z_k = P_k^top z$ 预测被掩码 Token 在对应频段下的神经生理描述子（融合 FAME 式标准化频带对数功率与 Neuro-KE 式谱熵、节律比值等无标注特征），监督损失记为 $cal(L)_"desc"^((k))$。遵循时间–频率不确定性原理，低频（$delta$、$theta$）描述子仅在 $gt.eq 1$ 秒的充分时间窗口上计算与监督，避免短窗口下的频谱泄漏误导。
- *4 个自由潜在子空间*（$j in {f_1, f_2, f_3, f_4}$，共 192 维）：不预设任何手工生理先验，采用指数移动平均（EMA）教师网络（以原版 REVE 权重初始化）在潜在空间执行 JEPA 式掩码状态预测（$cal(L)_"latent"^((j))$），并施加方差-协方差正则化防止表征坍缩，专职捕获波形细节、跨频段相位耦合等先验之外的隐含特征。
- *剩余自由维度*（80 维）：不施加显式投影约束，作为通用语义缓冲空间保留基础模型的原生表达灵活性。

为防止不同子空间在训练中退化为彼此的线性复制，借鉴 JEPA-Anything~\[16\] 施加子空间正交约束损失，强制各投影矩阵满足列正交且两两正交（注意：该约束保证子空间在几何投影上互不重叠，但不强求高阶统计独立，从而保留跨频段协同表达的可能）：

$ cal(L)_"orth" = sum_k norm(P_k^top P_k - I_r)_F^2 + sum_(i<j) norm(P_i^top P_j)_F^2 $ <eq:orth>

#par(first-line-indent: 0em)[*继续预训练阶段的总优化目标：*]

$ cal(L) = underbrace(sum_(k in "band") cal(L)_"desc"^((k)), "锚定") + lambda_f underbrace(sum_(j in "free") cal(L)_"latent"^((j)), "自由") + lambda_"orth" cal(L)_"orth" + lambda_"keep" cal(L)_"keep" $ <eq:loss>

其中 $cal(L)_"keep"$ 为面向冻结原版 REVE 的特征蒸馏防遗忘损失，防止骨干遗忘通用跨布局能力。

#par(first-line-indent: 0em)[*组件四：任务感知门控读出头。*]
针对每个下游任务，在 $K$ 个子空间与 $S$ 个时间尺度构成的二维特征张量上学习轻量级任务门控矩阵 $G in bb(R)^(K times S)$（经 Softmax 归一化使 $sum_(k,s) g_(k,s) = 1$），对各子空间–尺度切片加权聚合后送入线性或注意力分类头。收敛后的归一化权重矩阵 $G$ 即直接作为回答 RQ3 的可解释性生理拓纹。

== 复赛与决赛两阶段演进策略

*复赛阶段（基于 REVE 公开权重继续预训练）：* 严格遵循"三步走"流程：(1) 第 0 步（零训练诊断，回答 RQ1）：冻结原版 REVE 权重，在各层输出上执行"频段 $times$ 尺度"线性探测绘制信息可恢复性热力图，并对比不同复杂度读出头以定量剥离读出瓶颈；(2) 第 1 步（无标签继续预训练，回答 RQ2）：仅使用 14 个下游数据集训练集被试的无标签 EEG 信号（严格隔离验证集与测试集被试以防止任何形式的数据泄露），先冻结骨干热身新增模块，再按层衰减学习率解冻全网，每批次随机采样多尺度 Patch 组合；(3) 第 2 步（两阶段下游适配，回答 RQ3）：先冻结编码器训练任务门控 $G$ 与分类头，再进行端到端微调，所有超参严格依据验证集 BACC 选定。

#figure(
  image("figures/fig_pipeline.png", width: 92%),
  caption: [两阶段研究流程：复赛回答 RQ1–RQ3，决赛按结果设计。],
) <fig:pipeline>

*决赛阶段（严格从零预训练）：* 严格遵守决赛禁用外部预训练权重的规则，将复赛消融实验锁定的最优预训练目标组合、锚定/自由子空间维度配比以及有效尺度配置迁移至官方 21 个 OpenNeuro 预训练数据集上从零训练 REVE 式编码器，并将复赛中用于防遗忘的教师蒸馏损失 $cal(L)_"keep"$ 替换为面向原始信号的 L1 波形重建损失，以建立完整的底层时域建模能力。

== 设计依据与取舍

#block[
  #set text(size: 8pt)
  #set par(justify: false)
  #figure(table(
    columns: (1.2fr, 0.5fr, 2fr, 1.8fr),
    inset: 4pt, stroke: none, align: left,
    table.hline(stroke: 0.8pt),
    table.header([*核心设计模块*], [*对应 RQ*], [*理论依据与预期增益*], [*潜在代价与约束条件*]),
    table.hline(stroke: 0.5pt),
    [保留 REVE + 零初始化嫁接], [RQ1–3], [以当前最强通用基座为起点，第 0 步无损继承 6 万小时预训练先验], [仅适用于允许公开权重的复赛阶段],
    [频段锚定正交子空间], [RQ1, 2], [消除 $1 slash f$ 低频偏置（FAME），注入生理描述子监督（Neuro-KE +2.60%）], [需离线预计算描述子；短窗下无法解析低频],
    [自由子空间 + 潜在预测], [RQ2, 3], [突破手工先验天花板，捕获非线性波形与跨频段相位耦合等隐含特征], [存在表征坍缩风险，需方差正则与事后探测],
    [列切片可变 Patch + 跨尺度度], [RQ2], [细化短时任务粒度（如 SSVEP 1 s 由 1 Token 扩展为多 Token），继承滤波器语义], [短尺度 Token 增多会带来额外自注意力计算量],
    [任务感知门控读出（$K times S$）], [RQ3], [消除读出混叠瓶颈，显式输出各任务的频段-尺度依赖热力图], [训练初期若学习率过高可能导致门控早期坍塌],
    [特征蒸馏防遗忘（$cal(L)_"keep"$）], [—], [继续预训练语料规模远小于 6 万小时，防止骨干遗忘通用跨布局能力], [蒸馏权重 $lambda_"keep"$ 过大将限制新结构表征演化],
    table.hline(stroke: 0.8pt),
  ), caption: [核心模块设计依据、潜在代价与复赛向决赛的决策传导规则。]) <tab:design>
]

*复赛结果如何影响决赛：* 依据 A2/A3 的相对差距动态调整决赛锚定与自由子空间维度比例；若跨尺度注意力仅在短时/瞬态任务上有效，则决赛按任务类型条件启用短尺度切片；若统计差异小于跨种子标准差，则保持审慎不下过度结论。

// ══════════════════════════════════════════════
// 6  实验与消融计划
// ══════════════════════════════════════════════

= 实验与受控消融计划 <sec:experiment>

== 统一评测协议与基线矩阵

所有实验均在 OmniEEG 官方统一协议下执行：按被试严格划分 8:1:1（训练/验证/测试），固定 3 个官方随机种子，严格以验证集 BACC 筛选最优检查点，最终在测试集上报告 3 个种子的均值 $plus.minus$ 标准差（主指标为 BACC，同步报告 PR-AUC、ROC-AUC 与 Macro-F1；针对瞬时状态解码任务额外补充预测序列跳变率以评估时序平滑度）。单组完整评测涵盖 14 个数据集 $times$ 3 个种子 = 42 次独立运行。

基线对照涵盖四个递进层级：(1) 从零训练专用模型（EEGNet~\[1\]、EEG Conformer~\[2\]）；(2) 统一协议下的公开基础模型（LaBraM~\[5\]、CBraMod~\[7\]、原版 REVE~\[10\]）；(3) 核心领域适应对照（A1）——仅使用 REVE 原版重建目标在相同下游训练集无标签数据上继续预训练相同步数，用以严格区分"结构化方法创新"与"单纯过下游数据分布（Domain Adaptation）"的贡献；(4) 本方案完整模型。

== 受控消融矩阵（A0–A9）

#block[
  #set text(size: 8pt)
  #set par(justify: false)
  #figure(table(
    columns: (0.4fr, 1.5fr, 1.5fr, 1.5fr),
    inset: 4pt, stroke: none, align: left,
    table.hline(stroke: 0.8pt),
    table.header([*编号*], [*实验变体配置*], [*核心检验科学假设*], [*严格控制条件*]),
    table.hline(stroke: 0.5pt),
    [A0], [原版 REVE（无继续预训练）], [确立公开基座在统一协议下的性能基准下限], [官方公开权重直接微调],
    [A1], [REVE + 仅用原版 L1 目标继续预训练], [关键对照：区分"方法创新"与"下游无标签适应"], [相同无标签数据与预训练步数],
    [A2], [全锚定子空间（移除所有自由子空间）], [检验现有神经生理描述子先验是否已足够完备], [保持子空间总投影维度不变],
    [A3], [全自由子空间（移除频段锚定监督）], [检验显式频段生理锚定监督是否为涨点必要条件], [保持子空间总投影维度不变],
    [A4], [保留混合子空间，移除正交约束 $cal(L)_"orth"$], [检验几何正交约束对防止子空间特征混叠的作用], [保持子空间维度与监督一致],
    [A5], [固定 1 秒 Patch（移除 0.5s/0.25s 切片）], [检验多尺度时间切片对短时与瞬态任务的边际贡献], [保持总参数更新步数一致],
    [A6], [保留短尺度 Patch，移除跨尺度交叉注意力], [检验不同时间粒度之间是否必须存在深层特征交互], [保持输入 Token 序列一致],
    [A7], [全尺度 Token 合并执行无限制全局注意力], [测量门控稀疏跨尺度注意力相对全注意力的效率/性能比], [同步报告 FLOPs 与显存开销],
    [A8], [任务门控读出替换为常规全局平均池化], [剥离评估任务感知门控读出对消除读出混叠瓶颈的贡献], [基于同一继续预训练编码器],
    [A9], [防遗忘蒸馏 $cal(L)_"keep"$ 替换为 L1 波形重建], [比较特征蒸馏与原始波形重建在防遗忘上的优劣], [基于同一继续预训练流程],
    table.hline(stroke: 0.8pt),
  ), caption: [受控消融与对照实验矩阵（每次仅改变单一设计变量，其余超参、数据与训练步数严格对齐）。]) <tab:ablation>
]

== 可解释性验证与诚实判读准则

三项可解释性定量检验：(1) 带限频谱扰动实验（Band-Limited Perturbation）：对测试集输入施加数字带阻滤波器滤除特定频段（如 $alpha$ 波段 8–13 Hz），验证对应锚定子空间的表征 $L_2$ 变化幅信是否显著大于其余非目标子空间；(2) 自由子空间残差探测：以全套已知 EEG 生理描述子对自由子空间表征做岭回归拟合，以不可解释方差比例（$1 - R^2$）定量度量模型捕获的"先验之外新特征"；(3) 门控权重一致性对照：检验各分赛道收敛后的门控热力图 $G$ 是否符合合领域共识（例如 SSVEP 集中于高频率、短尺度，运动想象聚焦 $mu slash beta$ 频段，睡眠分期集中于 $delta slash theta$ 低频与长尺度）。

*实验结果判读与决赛决策规则：*(1) 强支持判据：完整方法相对 A1 在多数分赛道上稳定提升 BACC 且增益超过跨种子标准差，同时混合子空间优于全锚定（A2）与全自由（A3），且带限扰动呈现显著频段特异性；(2) 自我证伪与回退规则：若完整方法与 A1 表现持平，说明增益主要源于领域适应而非结构创新，决赛将果断剔除冗余模块退回简洁基线；(3) 决赛参数锁定规则：依据 A2/A3 的相对差距动态调整决赛锚定与自由子空间维度比例；若统计差异小于跨种子标准差，则保持审慎不下过度结论。

// ══════════════════════════════════════════════
// 7  算力需求
// ══════════════════════════════════════════════

= 算力需求估算与合规复现说明 <sec:compute>

#block[
  #set text(size: 8pt)
  #set par(justify: false)
  #figure(table(
    columns: (1.2fr, 2fr, 2fr),
    inset: 4pt, stroke: none, align: left,
    table.hline(stroke: 0.8pt),
    table.header([*赛程阶段*], [*核心计算任务*], [*算力与时间复杂度估算*]),
    table.hline(stroke: 0.5pt),
    [复赛第 0 步（诊断）], [冻结 REVE 各层表征提取、线性探测与读出对照], [仅前向推理与轻量回归，约数十 GPU 小时],
    [复赛第 1 步（继续预训练）], [14 个数据集训练集无标签继续预训练（3 种子）], [REVE-Base 全量预训练约需 260 A100h，继续预训练步数远小于此],
    [复赛第 2 步（下游适配）], [14 数据集 $times$ 3 种子 $times$ 约 15 组配置], [单次微调耗时轻量，可通过多卡并行高效完成],
    [决赛（从零预训练）], [官方 21 个 OpenNeuro 数据集从零预训练 + 全量评测], [依据复赛精简后的最优结构，匹配官方算力配额动态缩放],
    table.hline(stroke: 0.8pt),
  ), caption: [复赛与决赛各阶段算力需求预估（具体卡型与配额待官方进一步公布）。]) <tab:compute>
]

*数据合规与防泄露承诺：*复赛阶段仅使用官方指定的 14 个下游数据集及 MIT 许可的 REVE 公开权重，决赛阶段仅使用官方提供的 21 个预训练数据集，绝不引入任何私有或外部未授权语料。继续预训练与描述子归一化统计量严格限定在各数据集的训练集被试内部计算，验证集与测试集被试在微调测试前保持完全物理隔离。所有随机种子、超参数配置、早停规则与代码修改均基于 REVE 官方开源仓库构建，确保实验全流程 100% 可复现并随赛程完整提交。

// ══════════════════════════════════════════════
// 参考文献
// ══════════════════════════════════════════════

#heading(numbering: none)[#text(fill: accent)[参考文献]]

#set par(first-line-indent: 0em)
#set text(size: 9pt)

+ Lawhern, V. J., Solon, A. J., Waytowich, N. R., Gordon, S. M., Hung, C. P., & Lance, B. J. (2018). EEGNet: A compact convolutional neural network for EEG-based brain–computer interfaces. _Journal of Neural Engineering_, 15(5), 056013.
+ Song, Y., Zheng, Q., Liu, B., & Gao, X. (2023). EEG Conformer: Convolutional Transformer for EEG decoding and visualization. _IEEE Transactions on Neural Systems and Rehabilitation Engineering_, 31, 710–719.
+ Kostas, D., Aroca-Ouellette, S., & Rudzicz, F. (2021). BENDR: Using Transformers and a contrastive self-supervised learning task to learn from massive amounts of EEG data. _Frontiers in Human Neuroscience_, 15, 653659.
+ Yang, C., Westover, M. B., & Sun, J. (2023). BIOT: Biosignal Transformer for cross-data biosignal learning in the wild. In _Advances in Neural Information Processing Systems (NeurIPS)_, 36.
+ Jiang, W. B., Zhao, L. M., & Lu, B. L. (2024). Large Brain Model for learning generic representations with tremendous EEG data in BCI. In _International Conference on Learning Representations (ICLR)_.
+ Wang, G., Liu, W., He, Y., Xu, C., Ma, L., & Li, H. (2024). EEGPT: Pretrained Transformer for universal and reliable representation of EEG signals. In _Advances in Neural Information Processing Systems (NeurIPS)_, 37.
+ Wei, Z., et al. (2025). CBraMod: A Criss-Cross Brain Foundation Model for EEG decoding. In _International Conference on Learning Representations (ICLR)_.
+ BrainOmni: A Foundation Model for Any-to-Any Brain Signal Conversion. (2025).
+ CSBrain: Cross-Scale Brain Transformer for Universal EEG Decoding. (2025).
+ El Ouayas, A., et al. (2025). REVE: A Foundation Model for EEG Representation Learning across Arbitrary Electrode Layouts.
+ FAME: Understanding and Correcting Low-Frequency Bias in EEG Representation Learning. (2026).
+ NeuroLM: A Universal Multi-task Foundation Model for Bridging Language and EEG. (2025).
+ UniMind: Unified Multi-task Brain Decoding with Multi-level Alignment. (2025).
+ ECHO: EEG Channel-wise Hypernetwork Organization for In-context Learning. (2025).
+ Chen, Y., et al. (2026). Neuro-KE: Knowledge-Guided Interfaces for EEG Foundation Models. In _Advances in Neural Information Processing Systems (NeurIPS)_.
+ JEPA-Anything: Orthogonal Predictive Factorization for Joint-Embedding Predictive Architectures. (2025).
+ H-JEPA: Hierarchical World Model for Multi-Scale Time Series Prediction. (2025).
+ OmniEEG-Bench: A Comprehensive Multi-Paradigm Benchmark for EEG Foundation Models. (2026).
+ NeuralBench: A Unified Multi-task Benchmark for Neural Signal Decoding. (2025).
+ AdaBrain-Bench: Adaptive Evaluation Framework for Cross-Subject EEG BCIs. (2025).
+ Alayrac, J. B., et al. (2022). Flamingo: A visual language model for few-shot learning. In _Advances in Neural Information Processing Systems (NeurIPS)_, 35, 23716–23736.
