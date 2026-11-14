// OmniEEG Challenge 2026 初赛研究方案
// 编译：python3 -c "import typst; typst.compile('docs/report/proposal.typ', output='docs/report/proposal.pdf')"

#set document(
  title: "任务感知读出：释放 EEG 基础模型的跨任务表征潜力",
  author: ("团队成员姓名"),
)

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.2cm, right: 2.2cm),
  numbering: "1",
  number-align: center,
)

#set text(font: ("New Computer Modern", "Noto Serif CJK SC"), size: 11pt, lang: "zh")
#set par(leading: 0.8em, first-line-indent: 2em, justify: true)
#set heading(numbering: "1.1")

#show heading: it => {
  set text(font: ("New Computer Modern", "Noto Sans CJK SC"))
  set par(first-line-indent: 0em)
  v(0.6em)
  it
  v(0.3em)
}

#show heading.where(level: 1): it => {
  set text(size: 14pt, weight: "bold")
  v(0.8em)
  it
  v(0.4em)
}

// ── 封面 ──

#align(center)[
  #v(3cm)
  #text(size: 22pt, weight: "bold", font: ("New Computer Modern", "Noto Sans CJK SC"))[
    任务感知读出：释放 EEG 基础模型的跨任务表征潜力
  ]

  #v(1.5cm)
  #text(size: 13pt)[
    OmniEEG Challenge 2026 · 主赛道 \
    #v(0.8cm)
    队伍名称：#underline[________] \
    参赛成员：#underline[________] \
  ]

  #v(2cm)
  #text(size: 11pt, fill: luma(100))[
    2026 年 11 月
  ]
]

#pagebreak()

// ── 正文 ──

= 研究动机

EEG 基础模型的核心承诺是：一次预训练，多任务迁移。近年来，以 REVE、CBraMod、LaBraM 为代表的自监督模型在大规模 EEG 数据上学习通用表征，并在多种下游任务上取得了显著进展。然而，当我们从"平均排名"深入到逐任务证据时，一个系统性的现象浮现出来：

#par(first-line-indent: 0em)[
  *同一个强模型，在不同类型的任务上表现出巨大的、结构化的差距。*
]

以 NeuralBench 公开快照为例，REVE (Base) 总体 mean\_rank = 4.22，36 项 EEG 任务中 12 项排名第一。但在疾病诊断方向，精神分裂症识别仅 43.7%（最佳 ATCNet 72.9%），癫痫检测 77.6%（最佳 BDTCN 85.5%），睡眠觉醒 55.7%（最佳 LUNA 59.5%）。与此同时，它在运动想象（68.0%，第一）和 SSVEP（96.1%，第二）上保持领先。

这不是随机波动——它呈现出任务类型相关的模式（图 1）。我们的核心问题是：*这种差距究竟来自编码器的表征质量，还是来自表征到决策之间的读出方式？*

// ── 图1：REVE 跨任务性能差距 ──
#v(0.6em)
#figure(
  {
    let tasks = ("运动想象", "SSVEP", "癫痫检测", "睡眠觉醒", "精神分裂症")
    let reve =  (68.0, 96.1, 77.6, 55.7, 43.7)
    let best =  (68.0, 96.1, 85.5, 59.5, 72.9)
    let best_name = ("REVE", "SPaRCNet", "BDTCN", "LUNA", "ATCNet")
    let bar_w = 28pt
    let gap = 6pt
    let max_h = 120pt
    let col_reve = rgb("#4472C4")
    let col_best = rgb("#ED7D31")
    let col_gap  = rgb("#FF4444")

    set text(size: 8pt)
    box(width: 100%, height: 180pt, {
      // Y-axis
      place(dx: 30pt, dy: 0pt, line(start: (0pt, 0pt), end: (0pt, max_h + 2pt), stroke: 0.4pt))
      for pct in (0, 25, 50, 75, 100) {
        let y = max_h - max_h * pct / 100
        place(dx: 10pt, dy: y - 4pt, text(size: 7pt, str(pct) + "%"))
        place(dx: 30pt, dy: y, line(start: (0pt, 0pt), end: (380pt, 0pt), stroke: (paint: luma(220), thickness: 0.3pt)))
      }

      for (i, task) in tasks.enumerate() {
        let x_base = 45pt + i * 76pt
        let h_r = max_h * reve.at(i) / 100
        let h_b = max_h * best.at(i) / 100

        // REVE bar
        place(dx: x_base, dy: max_h - h_r,
          rect(width: bar_w, height: h_r, fill: col_reve, stroke: none))
        place(dx: x_base + 2pt, dy: max_h - h_r - 11pt,
          text(size: 6.5pt, weight: "bold", fill: col_reve, str(reve.at(i)) + "%"))

        // Best bar
        place(dx: x_base + bar_w + gap, dy: max_h - h_b,
          rect(width: bar_w, height: h_b, fill: col_best, stroke: none))
        place(dx: x_base + bar_w + gap + 1pt, dy: max_h - h_b - 11pt,
          text(size: 6.5pt, weight: "bold", fill: col_best, str(best.at(i)) + "%"))

        // Gap annotation for weak tasks
        if best.at(i) - reve.at(i) > 2 {
          let gap_val = calc.round(best.at(i) - reve.at(i), digits: 1)
          place(dx: x_base + 8pt, dy: max_h - h_b - 24pt,
            text(size: 7pt, weight: "bold", fill: col_gap, sym.Delta + str(gap_val)))
        }

        // Task label
        place(dx: x_base - 2pt, dy: max_h + 4pt,
          text(size: 7.5pt, task))
      }

      // Legend
      place(dx: 200pt, dy: max_h + 24pt, {
        box(inset: 4pt, {
          rect(width: 8pt, height: 8pt, fill: col_reve, stroke: none)
          h(2pt)
          text(size: 7.5pt, "REVE (Base)")
          h(10pt)
          rect(width: 8pt, height: 8pt, fill: col_best, stroke: none)
          h(2pt)
          text(size: 7.5pt, "各任务最佳模型")
        })
      })
    })
  },
  caption: [REVE 在 NeuralBench 上的逐任务表现：强项（运动想象、SSVEP）领先或持平，但疾病诊断类任务存在显著差距（红色标注）。数据来源：NeuralBench 官方快照 fe31393。],
) <fig-gap>

REVE 作者自身的 Table 4（图 2）提供了关键线索：pooled 与 unpooled 读出在多个数据集上产生了巨大的性能差异（FACED 24.0% vs. 42.2%，BCI-IV-2a 43.2% vs. 51.7%）。这意味着信息可能已经存在于编码器的分层表征中，但固定的读出方式未能为每种任务提取到最相关的模式。

#figure(
  image("reve-page-9.png", width: 95%),
  caption: [REVE 原文 Table 3–4（第 9 页）。Table 4 清晰展示 pooled 与 unpooled 读出在逐数据集上的性能差异：FACED pooled 仅 24.0%，unpooled 达 42.2%；多个数据集出现 10+ 百分点的差距，说明读出方式是性能的关键变量。],
) <fig-reve-table>

本方案围绕这一观察展开：与其改动已经被大规模预训练验证过的编码器，不如聚焦于*如何从同一套表征中，为不同任务提取不同的信息*。

= 相关工作与研究见解

== 异构输入的统一：不同模型选择了不同的层

跨数据集预训练面临的第一个问题是电极数、位置和片段长度各异。现有模型在不同层次上解决这一异构性，形成了两条路线：

*保留观测空间的路线。* REVE 保留原始电极，以三维坐标与时间位置共同编码每个 patch 的时空身份，通过 4D Fourier 位置编码让 Transformer 直接处理变长序列。CBraMod 类似地保留通道 $times$ 时间网格，但用条件卷积位置编码（ACPE）代替显式坐标。BIOT 和 LaBraM 则以导联身份 token 或神经词表标记每个通道。

*压缩到潜在空间的路线。* BrainOmni 在进入主模型前，先以传感器条件化的 cross-attention 将可变通道压缩为固定数量的潜在源，再离散化和建模。这意味着主模型处理的已不是电极信号，而是推断出的共同空间。

这两条路线的关键区分在于：接受不同通道数的输入形状，不等于获得了跨电极布局的不变性。通道排列、参考方式和坐标归一化仍然影响语义。本赛事 7 个分赛道的通道配置从 4 到 128 不等；选择哪条路线，直接约束了预训练权重的复用范围。

#figure(
  image("reve-arch.png", width: 95%),
  caption: [REVE 预训练框架总览（原文 Figure 1）。主路径（下方）：Patch Embedding → 结构化 Block Masking → Transformer Encoder → Decoder → L1 波形重建。辅助路径（上方）：跨层 Attention Pooling → Reconstruction MLP → L1 辅助重建。4D 位置编码（左上）将电极三维坐标与时间 patch 索引结合。本方案的改进聚焦于编码器之后的读出环节（图中未展示的下游适配部分）。],
) <fig-reve-arch>

== 全局关系与局部结构：交互模式的设计选择

统一输入之后，模型需要决定 token 之间如何交互。

REVE 采用全局 attention，赋予所有 token 之间直接的信息通路。CBraMod 将空间与时间分配给不同的 attention head，沿两个轴分别计算关系后拼接——理论复杂度从 $O(C^2 N^2)$ 降至 $O(N C^2 + C N^2)$。CSBrain 进一步交替使用多尺度卷积（CST）和稀疏跨区域 attention（SSA）：CST 在 token 网格上以多种核尺度提取局部模式，SSA 通过区域代表 token 实现长程交互。

这些设计反映了对 EEG 信号结构的不同假设。但一个重要的观察是：*模块级别的优势无法从整模型排名中剥离*。CBraMod 在睡眠分期上超过 REVE（NeuralBench 72.9% vs. 71.2%），但这包含了编码器、训练数据、位置编码和读出方式的综合差异。要判断"空间-时间分离 attention"本身是否是关键因素，需要同编码器、同训练预算下的受控消融。

== 预训练目标：从波形重建到频段平衡

预训练让模型学习什么，直接塑造了表征中保留的信息。

REVE 使用波形 L1 重建，外加跨层 attention pooling 的辅助重建路径——后者迫使压缩表示也携带足够重建的信息。FAME 指出了波形重建的一个潜在偏差：EEG 不同频段功率相差很大，直接优化总误差时，强功率低频成分可能主导梯度。FAME 的解决方案是逐频段标准化目标后等权平均损失，使弱功率频段的信息保留受到同等约束。

FAME Table 7 的 13 任务平均，50M 版本 61.4% 对 REVE 60.9%，差距不大但方向一致。值得注意的是，精神分裂症从 47.2% 提升到 67.7%——这恰好是 REVE 在 NeuralBench 上最显著的弱项之一。但需要谨慎：REVE 使用 L1 而非 MSE，FAME 对 MSE 的 Parseval 频率偏差论证不能直接搬用；且 FAME 的 1B 版本（60.8%）反而低于 50M，说明这不是简单的"频段平衡必然更好"。

EEGPT 提供了第三种思路：用完整上下文的 target encoder 表征作为监督目标，减少对噪声原始波形的依赖。这在概念上与 REVE 的辅助路径形成互补——一个压缩当前编码器的输出，一个对齐到动量更新的参考表征。

#figure(
  image("fame-page-19.png", width: 95%),
  caption: [FAME 原文 Table 7 与 Figure 7（第 19 页）。上：13 任务 FT 对比，精神分裂症从 REVE 的 47.2% 提升到 FAME-50M 的 67.7%，但情绪任务反而下降。下：频率偏差与下游性能的相关性热力图，说明频段偏差的影响因任务而异。],
) <fig-fame-table>

#figure(
  image("fame_mae_comparison.png", width: 90%),
  caption: [FAME vs. 标准 MAE 的逐任务对比（42 个任务）。FAME 在 27/42 个任务上胜出，均值从 0.429 提升到 0.462，但优势集中在特定任务类型，非全面碾压。],
) <fig-fame-bar>

#par(first-line-indent: 0em)[
  *关键见解：* 不同预训练目标在不同任务类型上的优势各异，且不存在脱离具体协议的必然优劣。这强化了我们的核心判断——与其在编码阶段寻找单一最优目标，不如确保读出机制能从已有表征中充分提取任务相关信息。
]

== 从统一编码器到任务感知读出

当前的主流方案——共享编码器加线性分类头——在"读出"环节做了最简单的假设：对所有 token 取平均，或将最后一层拼接后投影。但多项证据提示这不够：

- REVE 自身 Table 4：pooled 与 unpooled 读出的差距在多个数据集超过 15 个百分点。
- UniMind 以时空 query 条件化地从编码器提取任务相关信息，在其评测中优于固定池化。
- ECHO 利用支持样本和标签作为上下文，在少样本场景下动态适配读出。
- REVE 的辅助路径本身就是一种"跨层聚合读出"——它从多个编码层收集 token 并做 attention pooling，说明不同层的信息对最终表示有不同贡献。

这些工作从不同角度指向同一结论：*读出不是编码的附属品，它是决定表征能否被特定任务充分利用的关键环节*。

= 方法设计与论证

== 总体思路

我们的方案建立在一个务实的判断上：在比赛从零训练的约束下，编码器架构的改动必须与训练预算匹配。REVE 已在大规模数据上验证了其编码能力；大幅修改编码器意味着丢弃这些设计经验的指导价值。因此，我们将改进聚焦于编码器之后的读出与适配层。

核心设计包含三个互相配合的组件（图 2）：

// ── 图2：方法总体架构 ──
#v(0.4em)
#figure(
  {
    let box_h = 28pt
    let box_stroke = 0.6pt
    let c_enc = rgb("#DAE8FC")    // blue - encoder
    let c_read = rgb("#D5E8D4")   // green - our readout
    let c_pre = rgb("#FFF2CC")    // yellow - pretrain
    let c_input = rgb("#F8CECC")  // red - input
    let arrow_s = 0.8pt

    set text(size: 8pt)
    box(width: 100%, height: 260pt, {

      // ── Input ──
      place(dx: 20pt, dy: 10pt,
        rect(width: 90pt, height: box_h, fill: c_input, stroke: box_stroke, radius: 4pt,
          align(center + horizon, text(weight: "bold", "EEG  B×C×T"))))
      place(dx: 130pt, dy: 10pt,
        rect(width: 90pt, height: box_h, fill: c_input, stroke: box_stroke, radius: 4pt,
          align(center + horizon, text("电极坐标 C×3"))))

      // Arrows down
      place(dx: 62pt, dy: 38pt, line(start: (0pt, 0pt), end: (0pt, 14pt), stroke: arrow_s))
      place(dx: 58pt, dy: 51pt, text(size: 10pt, sym.arrow.b))

      // ── Patch + PE ──
      place(dx: 20pt, dy: 60pt,
        rect(width: 200pt, height: box_h, fill: c_enc, stroke: box_stroke, radius: 4pt,
          align(center + horizon, text("逐通道分段投影 + 4D 位置编码"))))

      place(dx: 118pt, dy: 88pt, line(start: (0pt, 0pt), end: (0pt, 14pt), stroke: arrow_s))
      place(dx: 114pt, dy: 101pt, text(size: 10pt, sym.arrow.b))

      // ── Encoder ──
      place(dx: 20pt, dy: 110pt,
        rect(width: 200pt, height: 36pt, fill: c_enc, stroke: box_stroke, radius: 4pt,
          align(center + horizon, {
            text(weight: "bold", "Transformer 编码器")
            linebreak()
            text(size: 7pt, fill: luma(80), "结构化 mask · L1 重建 · 辅助全局重建")
          })))

      // ── Pretrain branch (left) ──
      place(dx: 20pt, dy: 146pt, line(start: (40pt, 0pt), end: (40pt, 16pt), stroke: arrow_s))
      place(dx: 56pt, dy: 161pt, text(size: 10pt, sym.arrow.b))
      place(dx: 0pt, dy: 170pt,
        rect(width: 120pt, height: box_h, fill: c_pre, stroke: (paint: luma(180), thickness: box_stroke, dash: "dashed"), radius: 4pt,
          align(center + horizon, {
            text(size: 7.5pt, "预训练：波形重建 + 频段调节")
          })))

      // ── Our readout branch (right) ──
      // Arrow from encoder right side going right
      place(dx: 220pt, dy: 126pt, line(start: (0pt, 0pt), end: (30pt, 0pt), stroke: arrow_s))
      place(dx: 247pt, dy: 122pt, text(size: 10pt, sym.arrow.r))

      // Multi-layer aggregation
      place(dx: 260pt, dy: 60pt,
        rect(width: 160pt, height: box_h, fill: c_read, stroke: box_stroke, radius: 4pt,
          align(center + horizon, {
            text(weight: "bold", "多层表征聚合")
            linebreak()
            text(size: 7pt, "可学习层权重组合")
          })))

      // Arrows between layers and encoder
      place(dx: 220pt, dy: 118pt, {
        // dashed lines from encoder to multi-layer
        line(start: (0pt, 0pt), end: (40pt, -46pt), stroke: (paint: luma(140), thickness: 0.4pt, dash: "dotted"))
        line(start: (0pt, -4pt), end: (40pt, -50pt), stroke: (paint: luma(140), thickness: 0.4pt, dash: "dotted"))
        line(start: (0pt, -8pt), end: (40pt, -54pt), stroke: (paint: luma(140), thickness: 0.4pt, dash: "dotted"))
      })

      place(dx: 338pt, dy: 88pt, line(start: (0pt, 0pt), end: (0pt, 14pt), stroke: arrow_s))
      place(dx: 334pt, dy: 101pt, text(size: 10pt, sym.arrow.b))

      // Task query attention
      place(dx: 260pt, dy: 110pt,
        rect(width: 160pt, height: 36pt, fill: c_read, stroke: box_stroke, radius: 4pt,
          align(center + horizon, {
            text(weight: "bold", "任务条件化 Attention 读出")
            linebreak()
            text(size: 7pt, "Task Query × Cross-Attention")
          })))

      place(dx: 338pt, dy: 146pt, line(start: (0pt, 0pt), end: (0pt, 14pt), stroke: arrow_s))
      place(dx: 334pt, dy: 159pt, text(size: 10pt, sym.arrow.b))

      // Spatial-temporal separation
      place(dx: 260pt, dy: 168pt,
        rect(width: 160pt, height: box_h, fill: c_read, stroke: box_stroke, radius: 4pt,
          align(center + horizon, {
            text(weight: "bold", "空间-时间分离提取")
            linebreak()
            text(size: 7pt, "空间 query ⊕ 时间 query → 拼接")
          })))

      place(dx: 338pt, dy: 196pt, line(start: (0pt, 0pt), end: (0pt, 14pt), stroke: arrow_s))
      place(dx: 334pt, dy: 209pt, text(size: 10pt, sym.arrow.b))

      // Classification head
      place(dx: 290pt, dy: 218pt,
        rect(width: 100pt, height: box_h, fill: white, stroke: box_stroke, radius: 4pt,
          align(center + horizon, text(weight: "bold", "分类头"))))

      // ── Labels ──
      place(dx: 20pt, dy: 208pt,
        text(size: 7pt, fill: luma(120), "虚线框 = 仅预训练阶段"))
      place(dx: 260pt, dy: 248pt, {
        rect(width: 8pt, height: 8pt, fill: c_enc, stroke: box_stroke)
        h(3pt)
        text(size: 7.5pt, "编码器（REVE 框架）")
        h(10pt)
        rect(width: 8pt, height: 8pt, fill: c_read, stroke: box_stroke)
        h(3pt)
        text(size: 7.5pt, "本方案新增组件")
      })
    })
  },
  caption: [方法总体架构。左侧蓝色部分为基于 REVE 框架的编码器（预训练时含波形重建路径），右侧绿色部分为本方案提出的任务感知读出组件。编码器的多个中间层向读出模块提供分层表征（虚线）。],
) <fig-arch>

== 组件一：多层表征聚合

REVE 的辅助路径已经证明跨层信息有价值。我们将这一思路推广到下游读出：不仅使用最后一层的输出，而是从编码器的多个中间层收集 token 表示，通过可学习的层权重进行加权组合。

直觉是：浅层可能保留更多局部波形特征（对 SSVEP 等依赖精确频率的任务重要），深层提供更抽象的全局模式（对情绪、认知等高级任务重要）。让下游任务自行学习最优的层组合，比固定取最后一层更灵活。

== 组件二：任务条件化 attention 读出

取代固定的全局平均池化，引入一组可学习的 task query。每个 query 通过 cross-attention 机制从编码器输出中选择性地聚合信息：

$ bold(z)_k = "Attention"(bold(q)_k, bold(H), bold(H)) $

其中 $bold(q)_k$ 是第 $k$ 个 task query，$bold(H)$ 是编码器输出的 token 序列。不同 query 可以关注不同的时空位置和特征子空间。最终分类基于所有 query 输出的组合。

这与 UniMind 的思路一致，但我们强调：task query 的数量和初始化是需要消融验证的设计选择，不是越多越好。少量 query（4–8 个）可能已经足够，且计算开销远小于修改编码器。

== 组件三：空间-时间分离的信息提取

借鉴 CBraMod 的观察——空间依赖和时间依赖具有不同结构，我们在 task query 的 attention 中引入可选的轴分离模式：

- *空间模式*：在固定时间位置上，query 关注通道间的关系模式。
- *时间模式*：在固定通道上，query 追踪时间演化。

两种模式的输出拼接后形成最终表示。这不是对 CBraMod 整个编码器的复制，而是仅在读出层利用其结构化 attention 的思想，成本极低但可能为需要不同时空信息的任务提供更合适的特征。

== 预训练策略

在比赛的从零训练条件下，编码器采用 REVE 的 masked patch reconstruction 框架（L1 损失 + 4D 位置编码 + 结构化 mask），辅以频段感知的损失调节——在标准 L1 基础上，对不同频段的重建误差做归一化加权，避免低频主导。这一调节作为可开关的消融项，不改变编码器主体架构。

读出组件在下游微调阶段训练，预训练阶段不参与。

= 实验与消融计划

== 假设驱动的消融设计

我们的实验计划不是"去掉每个模块看掉多少分"的穷举，而是围绕三个可检验的假设展开：

*假设 1：读出方式是跨任务差距的主要来源。*

验证方法：固定编码器，仅改变读出方式（全局平均池化 → 多层加权 → task query attention），观察七类任务的性能变化。如果假设成立，预期在编码器不变的前提下，弱项任务（疾病诊断、睡眠分期）显著提升，强项任务（运动想象、SSVEP）不退化。

*假设 2：不同任务依赖不同层的信息。*

验证方法：在多层聚合读出中，记录各任务学到的层权重分布。如果假设成立，预期高频任务（SSVEP）更依赖浅层，语义任务（情绪、疾病）更依赖深层。这同时为选择"冻结哪些层、微调哪些层"提供定量依据。

*假设 3：频段平衡的预训练目标改善弱功率频段的表征。*

验证方法：对照标准 L1 和频段归一化 L1，在下游任务中比较。参照 FAME 的观察，预期疾病相关任务改善最大（这些任务可能依赖 beta/gamma 等弱功率频段的微妙模式）。但若结果不显著，也是重要的否定证据——说明弱项的原因不在频段偏差。

== 受控对比

每个消融仅改变一个变量，其余保持一致：

#table(
  columns: (auto, 1fr),
  stroke: 0.5pt,
  inset: 8pt,
  [*对比项*], [*控制条件*],
  [读出方式], [同一编码器、同一训练数据、同一微调轮数],
  [层聚合], [同一读出方式（均使用 task query），仅改变聚合层数],
  [预训练目标], [同一编码器架构、同一数据、同一下游读出],
  [空间-时间分离], [同一 query 数量，仅改变 attention 的轴限制],
)

== 评测对齐

按赛事要求，使用三个指定随机种子进行被试 8:1:1 划分，验证集选 checkpoint，报告测试集三次 BACC 均值。每个分赛道的两个数据集等权平均。辅助指标（PR-AUC、ROC-AUC、F1）同步记录。

== 算力需求估算

#par(first-line-indent: 0em)[
  编码器预训练（21 个 OpenNeuro 数据集）：Base 规模约 69M 参数，预计需要 [待根据官方 GPU 池配置估算] GPU 小时。下游微调与消融：14 个数据集 $times$ 3 种子 $times$ 主要消融配置，每次微调开销远小于预训练。读出组件参数量约为编码器的 1–2%，几乎不增加计算负担。
]

// ── 参考文献 ──

#pagebreak()

#heading(numbering: none)[参考文献]

#set par(first-line-indent: 0em)
#set text(size: 10pt)

+ El Ouayas _et al._ REVE: Robust EEG Vision Encoder. _NeurIPS_, 2025. arXiv:2510.21585.
+ Wei _et al._ CBraMod: Criss-cross Brain Modelling. _ICLR_, 2025. arXiv:2412.07236.
+ CSBrain: Cross-Scale Brain Transformer. _NeurIPS_, 2025. arXiv:2506.23075.
+ Understanding and Correcting Low-Frequency Bias in EEG Representation Learning (FAME). _Preprint_, 2026. arXiv:2608.01898.
+ EEGPT: Pretrained Transformer for Universal EEG Representation. _NeurIPS_, 2024.
+ BrainOmni. _Preprint_, 2025.
+ NeuroLM. _Preprint_, 2025.
+ UniMind: Unified Multi-task Brain Decoding. 2024.
+ ECHO: EEG Channel-wise Hypernetwork Organization. 2025.
+ LaBraM: Large Brain Model. _ICLR_, 2024.
+ BIOT: Cross-data Biosignal Learning. _NeurIPS_, 2024.
+ BENDR: Using Transformers and Contrastive Learning. 2021.
+ EEGNet: A Compact CNN. _J. Neural Eng._, 2018.
+ EEG Conformer. _IEEE TNSRE_, 2023.
+ NeuralBench. Facebook Research / NeuroAI, 2025.
+ OmniEEG-Bench. _Preprint_, 2026. arXiv:2606.00815.
