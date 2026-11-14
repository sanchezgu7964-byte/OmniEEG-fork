// 生成初赛 PPT：NODE_PATH=<含 pptxgenjs/react-icons/sharp 的 node_modules> node docs/report/build/make_deck.js
const path = require("path");
const pptxgen = require("pptxgenjs");
const React = require("react");
const ReactDOMServer = require("react-dom/server");
const sharp = require("sharp");
const fa = require("react-icons/fa");
const { applyTheme } = require(process.env.PPTX_SKILL + "/scripts/apply_theme.js");

const FIG = path.join(__dirname, "..", "figures");
const OUT = path.join(__dirname, "..", "proposal.pptx");

const THEME = {
  name: "Oracula",
  headFontFace: "Calibri",
  bodyFontFace: "Calibri",
  colors: {
    dk1: "1F2328", lt1: "FFFFFF", dk2: "1A4E8A", lt2: "EEF3F9",
    accent1: "1A4E8A", accent2: "D9822B", accent3: "3A8F5C",
    accent4: "7B5BA6", accent5: "6B7785", accent6: "C0392B",
    hlink: "1A4E8A", folHlink: "7B5BA6",
  },
};
const H = THEME.colors;
const BORDER = "D5DCE6";

const pres = new pptxgen();
pres.layout = "LAYOUT_WIDE";
pres.title = "面向跨任务 EEG 基础模型的频段正交子空间预测学习";
pres.author = "Oracula";
pres.theme = { headFontFace: THEME.headFontFace, bodyFontFace: THEME.bodyFontFace };
const C = pres.SchemeColor;

// ── 版式 ──
pres.defineSlideMaster({
  title: "COVER",
  background: { color: H.dk2 },
  objects: [
    { placeholder: { options: { name: "kicker", type: "body", x: 0.8, y: 0.9, w: 11.7, h: 0.45, fontSize: 14, bold: true, color: C.accent2, valign: "top", margin: 0 }, text: "" } },
    { placeholder: { options: { name: "title", type: "title", x: 0.8, y: 1.6, w: 11.7, h: 1.9, fontSize: 40, bold: true, color: C.background1, valign: "top", align: "left", margin: 0 }, text: "" } },
    { placeholder: { options: { name: "body", type: "body", x: 0.8, y: 3.55, w: 11.7, h: 0.9, fontSize: 18, italic: true, color: "CADCFC", valign: "top", margin: 0 }, text: "" } },
  ],
});
pres.defineSlideMaster({
  title: "CONTENT",
  background: { color: H.lt1 },
  margin: [0.6, 0.6, 0.7, 0.6],
  objects: [
    { placeholder: { options: { name: "kicker", type: "body", x: 0.6, y: 0.3, w: 12.1, h: 0.35, fontSize: 13, bold: true, color: C.accent5, valign: "top", margin: 0 }, text: "" } },
    { placeholder: { options: { name: "title", type: "title", x: 0.6, y: 0.62, w: 12.1, h: 0.75, fontSize: 30, bold: true, color: C.text2, valign: "top", align: "left", margin: 0 }, text: "" } },
    { text: { text: "Oracula · 频段正交子空间预测学习", options: { x: 0.6, y: 7.02, w: 8, h: 0.3, fontSize: 10, color: C.accent5, margin: 0 } } },
  ],
  slideNumber: { x: 12.1, y: 7.02, w: 0.6, h: 0.3, fontSize: 10, color: C.accent5, align: "right" },
});

// ── 工具 ──
async function icon(Comp, color = "#FFFFFF") {
  const svg = ReactDOMServer.renderToStaticMarkup(React.createElement(Comp, { color, size: 256 }));
  const buf = await sharp(Buffer.from(svg)).resize(256, 256).png().toBuffer();
  return "image/png;base64," + buf.toString("base64");
}
function iconCircle(slide, data, x, y, d, fill = C.accent1) {
  slide.addShape(pres.shapes.OVAL, { x, y, w: d, h: d, fill: { color: fill }, line: { color: fill } });
  const p = d * 0.24;
  slide.addImage({ data, x: x + p, y: y + p, w: d - 2 * p, h: d - 2 * p });
}
function card(slide, x, y, w, h, fill = C.background2, name) {
  slide.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w, h, rectRadius: 0.08, fill: { color: fill }, line: { color: fill }, objectName: name });
}
function text(slide, t, o) {
  slide.addText(t, { isTextBox: true, fontSize: 14, color: C.text1, valign: "top", margin: 0, paraSpaceAfter: 4, ...o });
}
function caption(slide, t, o) {
  text(slide, t, { fontSize: 10, color: C.accent5, ...o });
}
function bullets(items, size = 14) {
  return items.map((it, i) => {
    const runs = Array.isArray(it) ? it : [{ text: it }];
    return runs.map((r, j) => ({
      text: r.text,
      options: { ...(r.options || {}), fontSize: size, bullet: j === 0 ? { indent: 14 } : undefined, breakLine: j === runs.length - 1 && i < items.length - 1, paraSpaceAfter: 6 },
    }));
  }).flat();
}
function table(slide, header, rows, o) {
  const hdr = header.map((h) => ({ text: h, options: { bold: true, color: C.background1, fill: { color: C.text2 } } }));
  const body = rows.map((r, i) => r.map((c) => {
    const { fill, ...rest } = typeof c === "string" ? {} : c.options || {};
    return { text: typeof c === "string" ? c : c.text, options: { ...rest, fill: { color: fill || (i % 2 ? C.background2 : C.background1) } } };
  }));
  slide.addTable([hdr, ...body], { fontSize: 12, color: C.text1, valign: "middle", margin: [3, 6, 3, 6], border: { type: "solid", pt: 0.5, color: BORDER }, ...o });
}
function eq(spec, base = {}) {
  return spec.map((s) => {
    if (typeof s === "string") return { text: s, options: { ...base } };
    if (s.sub) return { text: s.sub, options: { ...base, subscript: true } };
    return { text: s.sup, options: { ...base, superscript: true } };
  });
}
function content(section, kicker, title) {
  const s = pres.addSlide({ masterName: "CONTENT", sectionTitle: section });
  s.addText(kicker, { placeholder: "kicker" });
  s.addText(title, { placeholder: "title" });
  return s;
}

(async () => {
  const I = {
    layer: await icon(fa.FaLayerGroup), cogs: await icon(fa.FaCogs), scale: await icon(fa.FaBalanceScale),
    search: await icon(fa.FaSearch), wave: await icon(fa.FaWaveSquare), filter: await icon(fa.FaFilter),
    th: await icon(fa.FaThLarge), db: await icon(fa.FaDatabase), shield: await icon(fa.FaUserShield),
    redo: await icon(fa.FaRedo), wrench: await icon(fa.FaWrench), chart: await icon(fa.FaChartBar),
  };

  // 1 封面
  pres.addSection({ title: "封面" });
  {
    const s = pres.addSlide({ masterName: "COVER", sectionTitle: "封面" });
    s.addText("OmniEEG Challenge 2026 · 主赛道 · 初赛研究方案", { placeholder: "kicker" });
    s.addText("面向跨任务 EEG 基础模型的\n频段正交子空间预测学习", { placeholder: "title" });
    s.addText("Frequency-Orthogonal Subspace Predictive Learning for Cross-Task EEG Foundation Models", { placeholder: "body" });
    const rows = [["队伍", "Oracula"], ["队员", "汪士楠    仇心妍    吴牧希"], ["提交日期", "2026 年 11 月 15 日"]];
    rows.forEach(([k, v], i) => {
      text(s, k, { x: 0.8, y: 4.9 + i * 0.5, w: 1.3, h: 0.4, fontSize: 16, bold: true, color: C.accent2 });
      text(s, v, { x: 2.1, y: 4.9 + i * 0.5, w: 6, h: 0.4, fontSize: 16, color: C.background1 });
    });
    ["δ", "θ", "α", "β", "γ"].forEach((b, i) => {
      s.addShape(pres.shapes.OVAL, { x: 8.3 + i * 0.85, y: 5.35, w: 0.7, h: 0.7, fill: { color: C.accent2, transparency: i * 15 }, line: { color: C.accent2 }, objectName: "band-" + b });
      text(s, b, { x: 8.3 + i * 0.85, y: 5.35, w: 0.7, h: 0.7, fontSize: 20, bold: true, color: C.background1, align: "center", valign: "middle" });
    });
  }

  // 2 为什么选主赛道
  const S1 = "研究动机";
  pres.addSection({ title: S1 });
  {
    const s = content(S1, "研究动机", "为什么选主赛道：一个模型同时服务七类任务");
    const tracks = [
      ["信号可靠性", "58 / 18 通道 · 2 s"], ["疾病诊断", "19 通道 · 2 s\n20 通道 · 10 s"], ["睡眠分期", "4 / 6 通道 · 30 s"], ["认知与情绪", "30 / 62 通道 · 10 s"],
      ["自然刺激解码", "128 通道 · 2 s"], ["运动想象", "64 / 22 通道 · 4 s"], ["SSVEP", "60 通道 · 1 s / 2 s"],
    ];
    tracks.forEach(([n, spec], i) => {
      const col = i % 4, row = Math.floor(i / 4);
      const x = 0.6 + col * 1.9, y = 1.65 + row * 1.65;
      card(s, x, y, 1.75, 1.45, C.background2, "track-" + i);
      text(s, n, { x: x + 0.15, y: y + 0.18, w: 1.5, h: 0.4, fontSize: 15, bold: true, color: C.text2 });
      text(s, spec, { x: x + 0.15, y: y + 0.65, w: 1.5, h: 0.7, fontSize: 12, color: C.accent5 });
    });
    [["14", "个下游数据集"], ["4–128", "通道"], ["1–30 s", "单样本时长"]].forEach(([n, l], i) => {
      text(s, n, { x: 0.6 + i * 2.5, y: 5.2, w: 2.3, h: 0.75, fontSize: 36, bold: true, color: C.accent2 });
      text(s, l, { x: 0.6 + i * 2.5, y: 5.95, w: 2.3, h: 0.35, fontSize: 13, color: C.accent5 });
    });
    card(s, 8.4, 1.65, 4.3, 1.25, C.background2, "sub-track");
    text(s, [{ text: "分赛道", options: { bold: true, color: C.accent5, breakLine: true } }, { text: "比拼特定范式下的单点上限" }], { x: 8.6, y: 1.8, w: 3.9, h: 1.0, fontSize: 15 });
    card(s, 8.4, 3.05, 4.3, 1.45, C.text2, "main-track");
    text(s, [{ text: "主赛道", options: { bold: true, color: C.accent2, breakLine: true } }, { text: "同一个基础模型能否同时跨布局、跨时间尺度、跨范式" }], { x: 8.6, y: 3.2, w: 3.9, h: 1.2, fontSize: 15, color: C.background1 });
    text(s, [
      { text: "我们想回答的三个问题", options: { bold: true, color: C.text2, breakLine: true } },
      { text: "模型学到了什么？", options: { bullet: { indent: 14 }, breakLine: true } },
      { text: "哪些设计真正起作用？", options: { bullet: { indent: 14 }, breakLine: true } },
      { text: "评测数字代表什么？", options: { bullet: { indent: 14 } } },
    ], { x: 8.4, y: 4.75, w: 4.3, h: 1.8, fontSize: 15 });
  }

  // 3 准确率
  {
    const s = content(S1, "研究动机 · 问题 1", "基础模型并不稳定地超过专用小模型");
    const gaps = [
      ["异常 EEG 筛查 · BENDR", 3.7], ["睡眠觉醒 · LUNA", 3.8], ["痴呆症 · 手工特征", 6.7], ["认知负荷 · ShallowFBCSPNet", 6.9],
      ["心理想象 · ShallowFBCSPNet", 7.5], ["帕金森病 · BIOT", 7.9], ["癫痫发作 · BDTCN", 7.9], ["c-VEP · LaBraM", 8.5],
      ["视听刺激 · 手工特征", 11.8], ["精神分裂症 · ATCNet", 29.2],
    ];
    s.addChart(pres.charts.BAR, [{ name: "落后幅度", labels: gaps.map((g) => g[0]), values: gaps.map((g) => g[1]) }], {
      x: 0.6, y: 1.55, w: 7.6, h: 5.0, barDir: "bar", chartColors: [H.accent6],
      showTitle: true, title: "REVE 落后该任务最佳模型的平衡准确率（百分点）", titleFontSize: 12, titleColor: H.dk1, titleFontFace: "+mn-lt",
      showValue: true, dataLabelPosition: "outEnd", dataLabelFontSize: 11, dataLabelColor: H.dk1, dataLabelFontFace: "+mn-lt", dataLabelFormatCode: "0.0",
      catAxisLabelFontSize: 11, catAxisLabelColor: H.dk1, catAxisLabelFontFace: "+mn-lt", valAxisHidden: true,
      valGridLine: { style: "none" }, catGridLine: { style: "none" }, showLegend: false, barGapWidthPct: 45,
    });
    caption(s, "数据：NeuralBench 统一微调协议，官方提交 fe31393；标签为“任务 · 该任务最佳模型”。", { x: 0.6, y: 6.6, w: 7.6, h: 0.3 });
    [["68.0%", "运动想象（第 1）"], ["96.1%", "SSVEP（第 2）"]].forEach(([n, l], i) => {
      text(s, n, { x: 8.7 + i * 2.1, y: 1.65, w: 2.0, h: 0.7, fontSize: 32, bold: true, color: C.accent3 });
      text(s, l, { x: 8.7 + i * 2.1, y: 2.35, w: 2.0, h: 0.35, fontSize: 12, color: C.accent5 });
    });
    text(s, bullets([
      "REVE 擅长节律性任务，但精神分裂症识别仅 43.7%，最佳专用网络 ATCNet 为 72.9%",
      "癫痫检测 77.6%，专用 BDTCN 为 85.5%",
      "规模不等于收益：LaBraM 500 小时预训练在 TUAB 上反而优于 2500 小时；FAME 扩大语料后下游表现波动",
    ], 14), { x: 8.7, y: 3.0, w: 4.0, h: 3.5 });
  }

  // 4 表征与读出
  {
    const s = content(S1, "研究动机 · 问题 2", "冻结表征偏弱，表征瓶颈与读出瓶颈混在一起");
    text(s, bullets([
      "冻结后普遍偏弱：LaBraM 在 TUEV 上线性探测 0.346，全量微调 0.641；CBraMod 冻结后 PhysioNet-MI 仅 0.385",
      "低频偏置：时域 MSE 重建按功率加权，编码器优先拟合低频（FAME）",
      "只换读出方式，REVE 在 Faced 上 +18.2，在 TUEV 上 −8.4；FAME 最佳探测层是第 9 层而非末层",
      "Neuro-KE：把无标注描述子作为预训练目标，平均 BAcc +2.60",
    ], 14), { x: 0.6, y: 1.65, w: 4.0, h: 5.0 });
    s.addImage({ path: path.join(FIG, "fig_reve_readout.png"), x: 4.9, y: 1.7, w: 4.9, h: 2.51, objectName: "fig-readout" });
    caption(s, "REVE-Base 同一冻结表示只换读出方式（不池化 − 池化）。数据：REVE Table 4。", { x: 4.9, y: 4.3, w: 4.9, h: 0.5 });
    s.addImage({ path: path.join(FIG, "related", "FAME_fig3.png"), x: 10.15, y: 1.7, w: 2.55, h: 3.53, objectName: "fig-fame3" });
    caption(s, "现有编码器偏向低频（图源：FAME Fig. 3）。", { x: 10.15, y: 5.3, w: 2.55, h: 0.5 });
    card(s, 4.9, 5.0, 4.9, 1.1, C.background2, "takeaway");
    text(s, "下游表现差，可能部分来自读出而不全是表征本身；目前没有工作系统区分两者。", { x: 5.1, y: 5.15, w: 4.5, h: 0.85, fontSize: 15, bold: true, color: C.text2 });
  }

  // 5 泛化与评测
  {
    const s = content(S1, "研究动机 · 问题 3、4", "跨被试泛化验证不足，分数随评测协议剧变");
    s.addChart(pres.charts.BAR, [{ name: "R²", labels: ["EEGNet", "BIOT", "LaBraM", "EEGPT", "CBraMod"], values: [26.65, 27.09, 25.35, 23.47, 2.4] }], {
      x: 0.6, y: 1.55, w: 5.6, h: 3.6, barDir: "col", chartColors: [H.accent1],
      showTitle: true, title: "SEED-VIG 跨被试回归 R²（%）", titleFontSize: 12, titleColor: H.dk1, titleFontFace: "+mn-lt",
      showValue: true, dataLabelPosition: "outEnd", dataLabelFontSize: 11, dataLabelColor: H.dk1, dataLabelFontFace: "+mn-lt", dataLabelFormatCode: "0.0",
      catAxisLabelFontSize: 12, catAxisLabelColor: H.dk1, catAxisLabelFontFace: "+mn-lt", valAxisHidden: true,
      valGridLine: { style: "none" }, catGridLine: { style: "none" }, showLegend: false, barGapWidthPct: 60,
    });
    caption(s, "数据：AdaBrain-Bench Table 2。从零训练的 EEGNet 与基础模型持平；CBraMod 原文自报 33.7%。", { x: 0.6, y: 5.2, w: 5.6, h: 0.5 });
    text(s, bullets(["EEG Conformer 在 BCI IV-2a 上被试内 78.7%，跨被试 47.0%", "UniMind 未考察完全未见被试；ECHO 推理时需测试被试本人的带标签样本"], 14), { x: 0.6, y: 5.8, w: 5.6, h: 1.1 });
    s.addImage({ path: path.join(FIG, "fig_reve_ssvep_protocols.png"), x: 6.7, y: 1.7, w: 6.0, h: 1.63, objectName: "fig-ssvep" });
    caption(s, "同一个 REVE 在不同评测协议下的 SSVEP 平衡准确率（仅说明协议影响，不作排行）。", { x: 6.7, y: 3.4, w: 6.0, h: 0.3 });
    [["5.6%", "线性探测\nOmniEEG-Bench"], ["67.4%", "全量微调\nOmniEEG-Bench"], ["96.1%", "全量微调\nNeuralBench"]].forEach(([n, l], i) => {
      text(s, n, { x: 6.7 + i * 2.05, y: 3.95, w: 1.95, h: 0.7, fontSize: 32, bold: true, color: C.accent2 });
      text(s, l, { x: 6.7 + i * 2.05, y: 4.65, w: 1.95, h: 0.6, fontSize: 12, color: C.accent5 });
    });
    card(s, 6.7, 5.5, 6.0, 1.1, C.background2, "takeaway");
    text(s, "公开分数只用于提出假设；所有优劣判断以 OmniEEG 统一协议下的受控实验为准。", { x: 6.9, y: 5.65, w: 5.6, h: 0.85, fontSize: 15, bold: true, color: C.text2 });
  }

  // 6 先诊断后改进
  {
    const s = content(S1, "研究动机 · 切入点", "先诊断，后改进：三层诊断");
    const cols = [
      [I.layer, "表征层", "各层表示保留了哪些频段、哪些时间尺度的生理信息？", "对应 RQ1：冻结表征的频段 × 尺度探测与读出对照"],
      [I.cogs, "设计层", "哪些模块契合 EEG 的物理特性并有依据，哪些只是冗余？", "对应 RQ2：混合正交子空间、跨尺度注意力及 A2–A8 消融"],
      [I.scale, "评测层", "增益来自表征质量提升，还是读出调整或下游分布适应？", "对应 A1 对照：相同数据与步数下只用原目标继续预训练"],
    ];
    cols.forEach(([ic, t, q, a], i) => {
      const x = 0.6 + i * 4.13;
      card(s, x, 1.7, 3.83, 3.4, C.background2, "layer-" + i);
      iconCircle(s, ic, x + 0.3, 1.95, 0.75);
      text(s, t, { x: x + 1.2, y: 2.1, w: 2.4, h: 0.5, fontSize: 22, bold: true, color: C.text2 });
      text(s, q, { x: x + 0.3, y: 2.95, w: 3.25, h: 1.3, fontSize: 15 });
      text(s, a, { x: x + 0.3, y: 4.2, w: 3.25, h: 0.8, fontSize: 13, color: C.accent1 });
    });
    text(s, "主赛道提供了受控实验场：统一被试划分、固定随机种子、7 类频段与时间尺度差异很大的任务。只对某类任务有效的改进会在这里暴露出来。", { x: 0.6, y: 5.45, w: 12.1, h: 0.8, fontSize: 16, color: C.text1 });
  }

  // 7 输入统一
  const S2 = "相关工作与研究见解";
  pres.addSection({ title: S2 });
  {
    const s = content(S2, "相关工作 · 输入统一", "EEG 基础模型如何统一异构输入");
    table(s, ["工作", "输入如何统一", "位置 / 通道信息"], [
      ["BIOT [4]", "逐通道 FFT 能量 token，线性注意力", "通道查表嵌入"],
      ["LaBraM [5]", "通道 × 1 s patch", "电极编号查表"],
      ["CBraMod [7]", "通道 × 时间 patch，空间 / 时间注意力并行", "条件位置编码 ACPE"],
      ["EEGPT [6]", "先跨通道、再跨时间的分层结构", "通道名码本"],
      ["BrainOmni [8]", "传感器编码器 → 16 个潜在源", "三维坐标、朝向、类型"],
      ["CSBrain [9]", "跨尺度 token + 结构化稀疏注意力", "解剖脑区分组"],
      [{ text: "REVE [10]", options: { bold: true } }, "保留全部观测通道（1 s patch），全局注意力", { text: "4D Fourier 位置编码", options: { bold: true } }],
    ], { x: 0.6, y: 1.65, w: 7.3, colW: [1.6, 3.4, 2.3], rowH: 0.6, fontSize: 13 });
    s.addImage({ path: path.join(FIG, "related", "REVE_fig1.png"), x: 8.2, y: 1.7, w: 4.5, h: 1.75, objectName: "fig-reve" });
    caption(s, "REVE 预训练框架（图源：REVE Fig. 1）。", { x: 8.2, y: 3.5, w: 4.5, h: 0.3 });
    card(s, 8.2, 4.0, 4.5, 2.45, C.background2, "note");
    text(s, bullets([
      "早期模型多在 TUH 固定 19/21 导联上训练，查表式位置编码难以覆盖未见布局",
      "REVE 用电极坐标 + 时间的连续编码，在 92 个数据集、约 6 万小时上预训练",
      "但 4D 编码相对可学习编码仅高 0.006，读出方式的影响更大",
    ], 14), { x: 8.4, y: 4.15, w: 4.1, h: 2.25 });
  }

  // 8 预训练目标
  {
    const s = content(S2, "相关工作 · 预训练目标", "预训练预测什么，各频段得到的监督是否均衡");
    table(s, ["预测对象", "代表工作", "要点与局限"], [
      ["原始波形", "REVE、CBraMod", "简单直接；MSE 按功率加权，放大低频监督"],
      ["离散码", "LaBraM、BrainOmni", "需额外 tokenizer；消融结论不一致"],
      [{ text: "频段标准化时频活动", options: { bold: true } }, "FAME", "各频段对数功率分别标准化、等权监督"],
      ["潜在表示", "EEGPT、S-JEPA", "表示空间对齐；去掉后 BCIC-2A 0.585 → 0.529"],
      ["对比预测", "BENDR、BIOT", "避免逐点重建；多数任务不及专用方法"],
    ], { x: 0.6, y: 1.65, w: 7.3, colW: [1.9, 1.8, 3.6], rowH: 0.52, fontSize: 13 });
    s.addImage({ path: path.join(FIG, "related", "FAME_fig2.png"), x: 8.2, y: 1.7, w: 4.5, h: 2.52, objectName: "fig-fame2" });
    caption(s, "波形重建 vs 按频段平衡的重建（图源：FAME Fig. 2）。", { x: 8.2, y: 4.27, w: 4.5, h: 0.3 });
    card(s, 0.6, 5.0, 12.1, 1.6, C.background2, "note");
    text(s, [
      { text: "把领域知识写进监督：", options: { bold: true, color: C.text2 } },
      { text: "FAME 让高低频等权；Neuro-KE 把无标注描述子作为掩码预训练目标，平均 BAcc +2.60。", options: { breakLine: true } },
      { text: "本方案的区别：", options: { bold: true, color: C.accent2 } },
      { text: "不只增加知识目标，而是把目标按“频段 × 尺度”组织进可检查的正交子空间，并让下游任务以可读的门控权重选择子空间。" },
    ], { x: 0.8, y: 5.15, w: 11.7, h: 1.35, fontSize: 15 });
  }

  // 9 非 EEG 借鉴与多任务解码
  {
    const s = content(S2, "相关工作 · 结构化潜在预测", "从非 EEG 领域借两件工具：正交子空间与按尺度分层");
    s.addImage({ path: path.join(FIG, "related", "JEPA-Anything_fig1.png"), x: 0.6, y: 1.6, w: 3.55, h: 4.28, objectName: "fig-jepa" });
    caption(s, "JEPA-Anything 正交预测分解（图源）。", { x: 0.6, y: 5.93, w: 3.55, h: 0.3 });
    s.addImage({ path: path.join(FIG, "related", "H-JEPA_fig1.png"), x: 4.5, y: 1.6, w: 4.6, h: 2.07, objectName: "fig-hjepa" });
    caption(s, "H-JEPA 按时间分层的世界模型（图源）。", { x: 4.5, y: 3.72, w: 4.6, h: 0.3 });
    const pts = [
      [I.th, "正交子空间", "潜在空间分成互相正交的可学习子空间，各自预测，防止因素混叠 → 频段可分离、可检查"],
      [I.wave, "按尺度分层", "高层逐步丢弃快变特征、保留慢变语义 → 不同时间尺度各有位置"],
    ];
    pts.forEach(([ic, t, d], i) => {
      const y = 1.6 + i * 1.3;
      iconCircle(s, ic, 9.4, y, 0.6);
      text(s, t, { x: 10.15, y, w: 2.55, h: 0.35, fontSize: 15, bold: true, color: C.text2 });
      text(s, d, { x: 10.15, y: y + 0.38, w: 2.55, h: 0.9, fontSize: 12 });
    });
    card(s, 4.5, 4.3, 8.2, 1.95, C.background2, "decoders");
    text(s, [
      { text: "多任务解码器分支", options: { bold: true, color: C.text2, breakLine: true } },
      { text: "NeuroLM 把 EEG 码并入 GPT-2 词表，所有任务低于 LaBraM；UniMind 接入 7B LLM，平均仅高 0.94；ECHO 需带标签支持样本。", options: { breakLine: true } },
      { text: "它们共同指向一个未回答的问题：下游表现差，是表征瓶颈还是读出瓶颈？" },
    ], { x: 4.7, y: 4.45, w: 7.8, h: 1.7, fontSize: 14 });
  }

  // 10 方法比较
  {
    const s = content(S2, "方法理解与比较", "主要方法的核心思路、证据与局限");
    table(s, ["方法", "核心思路", "较强证据", "局限 / 未证明"], [
      ["EEGNet", "深度可分离时空卷积滤波器组", "参数极少，小样本稳健", "空间核绑定导联数；无预训练"],
      ["LaBraM", "神经 tokenizer + 掩码码预测", "TUEV 上码本目标更优", "TUAB 上结论相反；冻结弱"],
      ["CBraMod", "criss-cross 时空注意力 + ACPE", "优于常规全注意力", "依赖全量微调；跨论文数值不一致"],
      ["EEGPT", "掩码重建 + 动量编码器对齐", "对齐损失有明确增益", "“线性探测”含卷积层，不可比"],
      ["CSBrain", "多尺度 token + 脑区稀疏注意力", "16 个数据集宏平均高", "消融只有示意图；不支持 < 1 s 窗口"],
      ["BrainOmni", "传感器编码器 + 潜在源", "去掉传感器嵌入后下降", "16 源压缩效果因任务而异"],
      [{ text: "REVE", options: { bold: true } }, "4D Fourier PE + 块掩码 L1 + 6 万小时", "未见布局可用；冻结基线最高", "对读出方式敏感；固定 1 s patch"],
      [{ text: "FAME", options: { bold: true } }, "按频段标准化的时频活动重建", "各频段恢复度更均衡", "涨幅有限；预训练未含 SSVEP"],
    ], { x: 0.6, y: 1.6, w: 12.1, colW: [1.4, 3.4, 3.3, 4.0], rowH: 0.47, fontSize: 13 });
    card(s, 0.6, 6.05, 12.1, 0.75, C.background2, "takeaway");
    text(s, "REVE 是最强的通用基座，FAME 与 Neuro-KE 的频段监督最具互补性；两者架构不同，收益不能直接相比。", { x: 0.8, y: 6.17, w: 11.7, h: 0.55, fontSize: 15, bold: true, color: C.text2 });
  }

  // 11 五项见解
  {
    const s = content(S2, "研究见解", "从调研中形成的五项见解");
    const ins = [
      ["下游表现差，未必全是表征的问题", "REVE 换读出方式后差异明显；FAME 最佳层在中间层"],
      ["生理描述子既能检查、也能监督表示", "Neuro-KE：无标注描述子作为预训练目标有效"],
      ["关键信息分布在不同频段和尺度上，却被混在一起", "FAME 证明监督不均衡，CSBrain 证明尺度重要；没人能说清某任务用了哪个频段、哪个尺度"],
      ["频段与尺度相关但不等价", "β/γ 包络可在秒级缓慢变化；0.25 s 窗口受时频不确定性限制，无法表示 δ 周期"],
      ["贡献应来自方法，而不是推翻最强基座", "保留 REVE 权重，在其上零初始化拼接新结构"],
    ];
    ins.forEach(([h, d], i) => {
      const y = 1.6 + i * 1.0;
      s.addShape(pres.shapes.OVAL, { x: 0.6, y: y + 0.05, w: 0.6, h: 0.6, fill: { color: C.accent1 }, line: { color: C.accent1 } });
      text(s, String(i + 1), { x: 0.6, y: y + 0.05, w: 0.6, h: 0.6, fontSize: 18, bold: true, color: C.background1, align: "center", valign: "middle" });
      text(s, h, { x: 1.45, y, w: 11.2, h: 0.4, fontSize: 17, bold: true, color: C.text2 });
      text(s, d, { x: 1.45, y: y + 0.42, w: 11.2, h: 0.45, fontSize: 14, color: C.accent5 });
    });
  }

  // 12 研究问题
  {
    const s = content(S2, "研究问题", "总问题与三个可在复赛中回答的研究问题");
    card(s, 0.6, 1.6, 12.1, 1.3, C.text2, "main-question");
    text(s, "把 EEG 表征组织成“以频段为锚、在多个尺度上表达、由任务按需读取”的结构，能否在不牺牲通用性的前提下提高跨任务、跨被试的下游表现，并让表征可以被检查？", { x: 0.85, y: 1.75, w: 11.6, h: 1.05, fontSize: 16, color: C.background1, valign: "middle" });
    const rq = [
      [I.search, "RQ1 · 诊断", "REVE 各层在哪些频段、哪些尺度上保留了可恢复的生理描述子？下游差距多少来自表征、多少来自读出？"],
      [I.wrench, "RQ2 · 改进", "继续预训练中加入混合正交子空间与跨尺度注意力，能否在 14 个数据集上稳定超过原版 REVE 与 A1 对照？"],
      [I.chart, "RQ3 · 可解释", "各任务的“子空间 × 尺度”门控权重是否符合神经生理规律？自由子空间是否学到描述子之外的信息？"],
    ];
    rq.forEach(([ic, t, d], i) => {
      const x = 0.6 + i * 4.13;
      card(s, x, 3.15, 3.83, 2.95, C.background2, "rq-" + i);
      iconCircle(s, ic, x + 0.3, 3.4, 0.65);
      text(s, t, { x: x + 1.1, y: 3.5, w: 2.6, h: 0.45, fontSize: 19, bold: true, color: C.text2 });
      text(s, d, { x: x + 0.3, y: 4.25, w: 3.25, h: 1.75, fontSize: 15 });
    });
  }

  // 13 方法总览
  const S3 = "方法设计";
  pres.addSection({ title: S3 });
  {
    const s = content(S3, "方法设计 · 整体框架", "保留 REVE，零初始化拼接三个模块");
    s.addImage({ path: path.join(FIG, "fig_method_arch.png"), x: 1.35, y: 1.5, w: 10.6, h: 4.81, objectName: "fig-arch" });
    caption(s, "蓝：保留 REVE 权重；橙（虚线）：新增模块，零初始化；绿：仅预训练目标；紫：下游适配。门控热力图为示意。", { x: 1.35, y: 6.35, w: 10.6, h: 0.3, align: "center" });
    text(s, "所有新增模块零初始化或门控残差接入：继续预训练第 0 步的输出与原版 REVE 完全一致。", { x: 1.35, y: 6.62, w: 10.6, h: 0.35, fontSize: 14, bold: true, color: C.text2, align: "center" });
  }

  // 14 可变 patch + 门控读出
  {
    const s = content(S3, "方法设计 · 组件二与组件四", "可变长度 patch、跨尺度注意力与任务门控读出");
    card(s, 0.6, 1.6, 6.3, 5.05, C.background2, "patch-card");
    text(s, "列切片可变长度 patch", { x: 0.85, y: 1.78, w: 5.8, h: 0.4, fontSize: 17, bold: true, color: C.text2 });
    const rows = [["1 s", 1, C.accent1], ["0.5 s", 2, C.accent2], ["0.25 s", 4, C.accent2]];
    rows.forEach(([l, n, col], r) => {
      const y = 2.35 + r * 0.6;
      text(s, l, { x: 0.85, y, w: 0.8, h: 0.45, fontSize: 13, color: C.accent5, valign: "middle" });
      const W0 = 4.6, g = 0.06, bw = (W0 - g * (n - 1)) / n;
      for (let k = 0; k < n; k++) s.addShape(pres.shapes.RECTANGLE, { x: 1.75 + k * (bw + g), y, w: bw, h: 0.45, fill: { color: col, transparency: r === 2 ? 30 : 0 }, line: { color: col } });
    });
    text(s, bullets([
      "复用原嵌入矩阵 W ∈ ℝ⁵¹²ˣ²⁰⁰：0.5 s 取前 100 列，0.25 s 取前 50 列，频率语义不变",
      "SSVEP 1 s 输入从 1 个 token 变为多个",
      "每隔 k 层插入跨尺度交叉注意力，门控 tanh(α)，α₀ = 0",
    ], 14), { x: 0.85, y: 4.25, w: 5.85, h: 2.3 });

    card(s, 7.2, 1.6, 5.5, 5.05, C.background2, "gate-card");
    text(s, "任务门控读出：子空间 × 尺度权重 G", { x: 7.45, y: 1.78, w: 5.0, h: 0.4, fontSize: 17, bold: true, color: C.text2 });
    const rowsK = ["δ", "θ", "α", "β", "γ", "f₁", "f₂", "f₃", "f₄"], colsS = ["0.25 s", "0.5 s", "1 s", "2 s", "4 s"];
    const vals = [
      [0.05, 0.05, 0.10, 0.15, 0.20], [0.05, 0.10, 0.15, 0.20, 0.15], [0.20, 0.35, 0.30, 0.15, 0.10], [0.45, 0.55, 0.35, 0.15, 0.05],
      [0.75, 0.60, 0.30, 0.10, 0.05], [0.25, 0.20, 0.15, 0.10, 0.05], [0.10, 0.15, 0.20, 0.10, 0.05], [0.05, 0.10, 0.10, 0.05, 0.05], [0.05, 0.05, 0.05, 0.05, 0.05],
    ];
    const mix = (t) => { const a = [0xEE, 0xF3, 0xF9], b = [0x1A, 0x4E, 0x8A]; return a.map((v, i) => Math.round(v + (b[i] - v) * t).toString(16).padStart(2, "0")).join("").toUpperCase(); };
    const gx = 8.1, gy = 2.45, cw = 0.66, ch = 0.33;
    colsS.forEach((c, j) => text(s, c, { x: gx + j * cw, y: gy - 0.32, w: cw, h: 0.28, fontSize: 10, color: C.accent5, align: "center" }));
    rowsK.forEach((k, i) => {
      text(s, k, { x: gx - 0.5, y: gy + i * ch, w: 0.4, h: ch, fontSize: 11, color: C.accent5, align: "right", valign: "middle" });
      vals[i].forEach((v, j) => s.addShape(pres.shapes.RECTANGLE, { x: gx + j * cw, y: gy + i * ch, w: cw - 0.03, h: ch - 0.03, fill: { color: mix(v) }, line: { color: mix(v) } }));
    });
    caption(s, "示意（类似 SSVEP 的分布），非实验结果。", { x: gx, y: gy + 9 * ch + 0.05, w: 3.4, h: 0.3 });
    text(s, "每个下游任务学习 K 个子空间 × S 个尺度的 softmax 权重，加权后送入分类头；收敛后的 G 直接回答 RQ3。", { x: 7.45, y: 5.75, w: 5.0, h: 0.85, fontSize: 13 });
  }

  // 15 混合正交子空间
  {
    const s = content(S3, "方法设计 · 组件三", "混合正交子空间：频段锚定 + 自由预测");
    const x0 = 0.6, W0 = 12.1, per = W0 / 512, y0 = 1.65, hb = 0.6;
    let x = x0;
    const blocks = [["δ", 48, C.accent2, 0], ["θ", 48, C.accent2, 12], ["α", 48, C.accent2, 24], ["β", 48, C.accent2, 36], ["γ", 48, C.accent2, 48],
      ["f₁", 48, C.accent4, 0], ["f₂", 48, C.accent4, 15], ["f₃", 48, C.accent4, 30], ["f₄", 48, C.accent4, 45], ["未约束 80 维", 80, C.accent5, 40]];
    blocks.forEach(([l, d, col, tr]) => {
      const w = d * per;
      s.addShape(pres.shapes.RECTANGLE, { x, y: y0, w: w - 0.03, h: hb, fill: { color: col, transparency: tr }, line: { color: col, transparency: tr } });
      text(s, l, { x, y: y0, w: w - 0.03, h: hb, fontSize: 15, bold: true, color: C.background1, align: "center", valign: "middle" });
      x += w;
    });
    text(s, "锚定子空间：5 × 48 = 240 维", { x: x0, y: y0 + 0.68, w: 240 * per, h: 0.32, fontSize: 13, bold: true, color: C.accent2, align: "center" });
    text(s, "自由子空间：4 × 48 = 192 维", { x: x0 + 240 * per, y: y0 + 0.68, w: 192 * per, h: 0.32, fontSize: 13, bold: true, color: C.accent4, align: "center" });
    text(s, "通用缓冲", { x: x0 + 432 * per, y: y0 + 0.68, w: 80 * per, h: 0.32, fontSize: 13, bold: true, color: C.accent5, align: "center" });
    caption(s, "编码器输出 z ∈ ℝ⁵¹² 上的线性投影 Pₖ ∈ ℝ^(512×r)，初始 r = 48。", { x: x0, y: y0 + 1.03, w: W0, h: 0.3 });
    card(s, 0.6, 3.05, 5.95, 2.2, C.background2, "anchor-card");
    text(s, [{ text: "锚定子空间（δ θ α β γ）", options: { bold: true, color: C.accent2, breakLine: true } },
      ...bullets(["预测被遮 token 在对应频段的描述子：FAME 式标准化对数功率 + Neuro-KE 式谱熵、节律比值", "低频（δ、θ）描述子只在 ≥ 1 s 窗口上计算与监督"], 14)], { x: 0.8, y: 3.2, w: 5.55, h: 1.95, fontSize: 15 });
    card(s, 6.75, 3.05, 5.95, 2.2, C.background2, "free-card");
    text(s, [{ text: "自由子空间（f₁–f₄）", options: { bold: true, color: C.accent4, breakLine: true } },
      ...bullets(["不预设先验，做 JEPA 式掩码潜在预测；复赛中 EMA 教师以 REVE 初始化", "加方差正则防止坍缩，事后用描述子探测其含义"], 14)], { x: 6.95, y: 3.2, w: 5.55, h: 1.95, fontSize: 15 });
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 0.6, y: 5.45, w: 12.1, h: 1.25, rectRadius: 0.08, fill: { color: C.background1 }, line: { color: BORDER, width: 1 } });
    const b = { fontSize: 16, color: C.text1 };
    text(s, [
      { text: "正交约束（JEPA-Anything）：", options: { bold: true, color: C.text2, fontSize: 14 } },
      ...eq(["L", { sub: "orth" }, " = Σ", { sub: "k" }, " ‖P", { sub: "k" }, { sup: "⊤" }, "P", { sub: "k" }, " − I", { sub: "r" }, "‖", { sub: "F" }, { sup: "2" }, " + Σ", { sub: "i<j" }, " ‖P", { sub: "i" }, { sup: "⊤" }, "P", { sub: "j" }, "‖", { sub: "F" }, { sup: "2" }, "      几何上不重叠，不强求统计独立"], b).map((r, i, a) => (i === a.length - 1 ? { ...r, options: { ...r.options, breakLine: true } } : r)),
      { text: "总损失：", options: { bold: true, color: C.text2, fontSize: 14 } },
      ...eq(["L = Σ", { sub: "k∈频段" }, " L", { sub: "desc" }, { sup: "(k)" }, " + λ", { sub: "f" }, " Σ", { sub: "j∈自由" }, " L", { sub: "latent" }, { sup: "(j)" }, " + λ", { sub: "orth" }, " L", { sub: "orth" }, " + λ", { sub: "keep" }, " L", { sub: "keep" }, "      L", { sub: "keep" }, "：对冻结原版 REVE 的特征蒸馏，防止遗忘"], b),
    ], { x: 0.85, y: 5.58, w: 11.7, h: 1.05, fontSize: 16 });
  }

  // 16 训练与适配流程
  {
    const s = content(S3, "方法设计 · 训练与适配流程", "复赛三步回答 RQ1–RQ3，决赛按结果从零训练");
    s.addImage({ path: path.join(FIG, "fig_pipeline.png"), x: 0.95, y: 1.5, w: 11.4, h: 3.19, objectName: "fig-pipeline" });
    const steps = [
      ["第 0 步 · 诊断（RQ1）", "冻结 REVE，做频段 × 尺度探测与读出对照"],
      ["第 1 步 · 继续预训练（RQ2）", "只用训练集被试的无标签数据；先热身新模块，再分层解冻"],
      ["第 2 步 · 下游适配（RQ3）", "先训练门控与分类头，再端到端微调；超参按验证集 BACC 选择"],
      ["决赛 · 从零训练", "迁移锁定的目标与配比；EMA 教师在内的全部参数随机初始化"],
    ];
    steps.forEach(([h, d], i) => {
      const x = 0.6 + i * 3.08;
      card(s, x, 4.9, 2.9, 1.8, i === 3 ? C.text2 : C.background2, "step-" + i);
      text(s, h, { x: x + 0.15, y: 5.0, w: 2.6, h: 0.65, fontSize: 14, bold: true, color: i === 3 ? C.accent2 : C.text2 });
      text(s, d, { x: x + 0.15, y: 5.68, w: 2.6, h: 0.95, fontSize: 13, color: i === 3 ? C.background1 : C.text1 });
    });
  }

  // 17 设计依据
  {
    const s = content(S3, "方法设计 · 设计依据与取舍", "每个设计为什么可能有效，代价是什么");
    table(s, ["设计", "RQ", "为什么可能有效", "代价 / 条件"], [
      ["保留 REVE + 零初始化", "1–3", "起点为当前最强公开模型，第 0 步无损继承", "只适用于允许公开权重的复赛"],
      ["频段锚定子空间", "1、2", "各频段独立监督（FAME）；描述子目标 +2.60（Neuro-KE）", "描述子需预计算；短窗口无法表示低频"],
      ["自由子空间 + 潜在预测", "2、3", "学习手工先验之外的信息", "有坍缩风险；含义需事后探测"],
      ["正交约束", "2", "防止子空间互相复制", "只约束几何关系"],
      ["可变 patch + 跨尺度注意力", "2", "短时任务获得更细粒度，继承滤波器语义", "短尺度 token 增加注意力计算量"],
      ["任务门控读出", "3", "直接输出各任务的频段 × 尺度依赖", "学习率过高时门控可能过早塌缩"],
      ["特征蒸馏防遗忘", "—", "继续预训练数据远少于 6 万小时", "λ_keep 过大会限制新结构"],
    ], { x: 0.6, y: 1.6, w: 12.1, colW: [2.6, 0.8, 4.6, 4.1], rowH: 0.5, fontSize: 13 });
    card(s, 0.6, 5.95, 12.1, 0.85, C.background2, "decision");
    text(s, [{ text: "复赛 → 决赛：", options: { bold: true, color: C.text2 } },
      { text: "按 A2/A3 差距调整锚定与自由维度比例；跨尺度注意力只在短时任务有效时按任务启用；若与 A1 持平，决赛剔除冗余模块。" }],
    { x: 0.8, y: 6.05, w: 11.7, h: 0.7, fontSize: 14 });
  }

  // 18 协议与基线
  const S4 = "实验与消融计划";
  pres.addSection({ title: S4 });
  {
    const s = content(S4, "实验 · 统一协议与基线", "统一协议下的四层基线");
    [["8 : 1 : 1", "按被试划分训练 / 验证 / 测试"], ["3", "个官方随机种子，报告均值 ± 标准差"], ["42", "次运行 / 配置（14 数据集 × 3 种子）"], ["BACC", "主指标；另报 PR-AUC、ROC-AUC、F1"]].forEach(([n, l], i) => {
      const x = 0.6 + i * 3.08;
      card(s, x, 1.6, 2.9, 1.6, C.background2, "stat-" + i);
      text(s, n, { x: x + 0.2, y: 1.72, w: 2.5, h: 0.7, fontSize: 32, bold: true, color: C.text2 });
      text(s, l, { x: x + 0.2, y: 2.45, w: 2.5, h: 0.7, fontSize: 13, color: C.accent5 });
    });
    const lv = [
      ["① 从零训练专用模型", "EEGNet、EEG Conformer", C.background2, C.text1],
      ["② 统一协议下的公开基础模型", "LaBraM、CBraMod、原版 REVE（A0）", C.background2, C.text1],
      ["③ 领域适应对照 A1", "相同数据与步数，只用 REVE 原目标继续预训练；区分方法创新与单纯见过下游数据", C.accent2, C.background1],
      ["④ 本方案完整模型", "混合正交子空间 + 跨尺度注意力 + 任务门控读出", C.text2, C.background1],
    ];
    lv.forEach(([h, d, f, tc], i) => {
      const x = 0.6 + i * 3.08, y = 4.75 - i * 0.4;
      card(s, x, y, 2.9, 6.7 - y, f, "level-" + i);
      text(s, h, { x: x + 0.15, y: y + 0.12, w: 2.6, h: 0.6, fontSize: 14, bold: true, color: tc });
      text(s, d, { x: x + 0.15, y: y + 0.75, w: 2.6, h: 6.6 - y - 0.8, fontSize: 13, color: tc });
    });
  }

  // 19 消融矩阵
  {
    const s = content(S4, "实验 · 消融与对照", "A0–A9：每次只改变一个变量");
    const hl = { fill: "FBEBDD" };
    table(s, ["编号", "变体", "检验的问题", "控制条件"], [
      ["A0", "原版 REVE（不继续预训练）", "统一协议下的基准下限", "官方权重直接微调"],
      [{ text: "A1", options: { bold: true, ...hl } }, { text: "只用 REVE 原目标继续预训练", options: hl }, { text: "收益来自方法还是额外训练", options: { bold: true, ...hl } }, { text: "数据、步数相同", options: hl }],
      ["A2", "全锚定（无自由子空间）", "已知描述子先验是否够用", "子空间总维度相同"],
      ["A3", "全自由（无频段锚定）", "频段锚定是否必要", "子空间总维度相同"],
      ["A4", "混合子空间，去掉正交约束", "正交约束是否必要", "维度与监督一致"],
      ["A5", "固定 1 s patch", "可变 patch 的贡献", "更新步数一致"],
      ["A6", "有短 patch，无跨尺度注意力", "尺度间是否需要交互", "输入 token 一致"],
      ["A7", "全尺度 token 做全局注意力", "门控跨尺度的效率 / 性能比", "另报 FLOPs 与显存"],
      ["A8", "门控读出 → 全局平均池化", "门控读出的贡献", "同一继续预训练编码器"],
      ["A9", "特征蒸馏 → L1 波形重建", "防遗忘方式的选择", "同一训练流程"],
    ], { x: 0.6, y: 1.55, w: 12.1, colW: [0.9, 4.0, 4.1, 3.1], rowH: 0.42, fontSize: 13 });
    text(s, "算力受限时：A1、A2、A3、A5 跑全部 14 个数据集；其余先在每个分赛道各选 1 个数据集。", { x: 0.6, y: 6.4, w: 12.1, h: 0.4, fontSize: 14, color: C.text2, bold: true });
  }

  // 20 判读与可解释性
  {
    const s = content(S4, "实验 · 判读思路", "可解释性检验与不同结果对应的判断");
    text(s, "三项可解释性检验", { x: 0.6, y: 1.6, w: 5.6, h: 0.4, fontSize: 17, bold: true, color: C.text2 });
    const tests = [
      [I.filter, "带限扰动", "滤掉某频段（如 α 8–13 Hz），对应锚定子空间的变化应显著大于其他子空间"],
      [I.search, "自由子空间探测", "用全套描述子岭回归，不可解释方差 1 − R² 度量“先验之外”的信息"],
      [I.th, "门控与生理规律对照", "SSVEP 应偏高频短尺度，运动想象偏 μ/β，睡眠偏 δ/θ 长尺度"],
    ];
    tests.forEach(([ic, h, d], i) => {
      const y = 2.15 + i * 1.5;
      iconCircle(s, ic, 0.6, y, 0.65);
      text(s, h, { x: 1.45, y, w: 4.8, h: 0.4, fontSize: 15, bold: true, color: C.text1 });
      text(s, d, { x: 1.45, y: y + 0.42, w: 4.8, h: 0.95, fontSize: 13 });
    });
    table(s, ["实验结果", "判断与后续动作"], [
      [{ text: "完整方法在多数分赛道超过 A1，且差距大于标准差；A2、A3 均低于混合", options: { bold: true } }, "支持假设；按 A2/A3 差距锁定决赛子空间配比"],
      ["完整方法与 A1 持平", "收益来自领域适应而非结构；决赛退回简洁基线"],
      ["只对部分分赛道有效", "按分赛道报告；决赛按任务启用短 patch 或门控"],
      ["差异小于跨种子标准差", "不下结论，不据此调整决赛设计"],
    ], { x: 6.6, y: 1.65, w: 6.1, colW: [3.2, 2.9], rowH: [0.45, 1.1, 0.9, 0.9, 0.9], fontSize: 13 });
  }

  // 21 结果分析与算力
  const S5 = "结果分析与算力需求";
  pres.addSection({ title: S5 });
  {
    const s = content(S5, "结果分析与算力需求", "暂无已完成实验结果；算力按阶段估算");
    card(s, 0.6, 1.55, 12.1, 0.75, C.background2, "results-note");
    text(s, [{ text: "结果分析：", options: { bold: true, color: C.text2 } }, { text: "暂无已完成实验结果。初赛不开放训练数据，实验将在复赛开放 14 个下游数据集后按上述计划执行。" }], { x: 0.8, y: 1.68, w: 11.7, h: 0.55, fontSize: 14 });
    table(s, ["阶段", "任务", "运行次数", "估算"], [
      ["复赛第 0 步", "冻结表征探测与读出对照", "14 数据集 × 3 种子", "以前向推理为主，约数十 GPU 小时"],
      ["复赛第 1 步", "完整方法及 A1–A7、A9 继续预训练", "约 9 个配置", "远小于 REVE-Base 完整预训练的约 260 A100 小时"],
      ["复赛第 2 步", "各配置在 14 数据集 × 3 种子上微调", "约 15 × 42 = 630 次", "单次分钟至小时级，多卡并行"],
      ["决赛", "21 个 OpenNeuro 数据集从零预训练 + 评测", "1 次预训练 + 42 次微调", "按复赛锁定结构与官方配额缩放"],
    ], { x: 0.6, y: 2.5, w: 12.1, colW: [1.7, 3.9, 2.6, 3.9], rowH: 0.5, fontSize: 13 });
    const hw = [[I.cogs, "硬件", "以单卡 80 GB 显存的 A100 级 GPU 估算，复赛约 4–8 卡并行；以官方配额为准"], [I.db, "存储", "REVE-Base 约 69M 参数，单个检查点约 280 MB；630 个检查点约 180 GB，另需描述子缓存"]];
    hw.forEach(([ic, h, d], i) => {
      const x = 0.6 + i * 6.15;
      iconCircle(s, ic, x, 5.45, 0.6);
      text(s, h, { x: x + 0.8, y: 5.42, w: 5.0, h: 0.38, fontSize: 15, bold: true, color: C.text2 });
      text(s, d, { x: x + 0.8, y: 5.82, w: 5.0, h: 0.9, fontSize: 13 });
    });
  }

  // 22 数据与复现
  {
    const s = content(S5, "数据来源与复现", "只用官方数据与公开权重，按被试隔离，全程可复现");
    const items = [
      [I.db, "数据来源", "复赛：官方 14 个下游数据集 + REVE 公开权重（MIT 许可）。决赛：官方 21 个 OpenNeuro 数据集，所有参数随机初始化。不使用任何私有数据或私有权重。"],
      [I.shield, "防泄漏", "继续预训练与描述子归一化统计量只在训练集被试内计算；验证、测试被试不参与任何预训练或调参。"],
      [I.redo, "复现", "固定 3 个官方种子；超参数、步数与模型选择规则写入配置文件；代码基于 REVE 官方仓库修改，随复赛提交。"],
    ];
    items.forEach(([ic, h, d], i) => {
      const y = 1.75 + i * 1.65;
      card(s, 0.6, y, 12.1, 1.45, C.background2, "item-" + i);
      iconCircle(s, ic, 0.85, y + 0.38, 0.7);
      text(s, h, { x: 1.85, y: y + 0.2, w: 10.6, h: 0.4, fontSize: 17, bold: true, color: C.text2 });
      text(s, d, { x: 1.85, y: y + 0.65, w: 10.6, h: 0.75, fontSize: 14 });
    });
  }

  // 23 参考文献
  pres.addSection({ title: "参考文献" });
  {
    const s = content("参考文献", "参考文献", "参考文献");
    const refs = [
      "Lawhern et al. EEGNet. J. Neural Eng., 2018",
      "Song et al. EEG Conformer. IEEE TNSRE, 2023",
      "Kostas et al. BENDR. Front. Hum. Neurosci., 2021",
      "Yang et al. BIOT. NeurIPS 2023",
      "Jiang et al. LaBraM. ICLR 2024",
      "Wang G. et al. EEGPT. NeurIPS 2024",
      "Wang J. et al. CBraMod. ICLR 2025",
      "Xiao et al. BrainOmni. arXiv:2505.18185",
      "Zhou et al. CSBrain. arXiv:2506.23075",
      "El Ouahidi et al. REVE. arXiv:2510.21585",
      "Yu et al. FAME. arXiv:2608.01898",
      "Jiang et al. NeuroLM. ICLR 2025",
      "Lu W. et al. UniMind. arXiv:2506.18962",
      "Liu et al. ECHO. arXiv:2509.22556",
      "Chen et al. Neuro-KE. NeurIPS 2026",
      "JEPA-Anything. arXiv:2609.20800",
      "H-JEPA. arXiv:2610.06805",
      "Lu Z. et al. OmniEEG-Bench. arXiv:2606.00815",
      "Banville et al. NeuralBench. arXiv:2605.08495",
      "Wu et al. AdaBrain-Bench. arXiv:2507.09882",
      "Alayrac et al. Flamingo. NeurIPS 2022",
    ];
    const col = (arr, start) => arr.map((r, i) => ({ text: `[${start + i}]  ${r}`, options: { breakLine: i < arr.length - 1 } }));
    text(s, col(refs.slice(0, 11), 1), { x: 0.6, y: 1.6, w: 5.9, h: 5.2, fontSize: 13, paraSpaceAfter: 5 });
    text(s, col(refs.slice(11), 12), { x: 6.8, y: 1.6, w: 5.9, h: 5.2, fontSize: 13, paraSpaceAfter: 5 });
  }

  await pres.writeFile({ fileName: OUT });
  await applyTheme(OUT, THEME);
  console.log("wrote " + OUT);
})();
