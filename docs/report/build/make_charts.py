"""从 research/reve_route_20261113/benchmark_records.csv 生成报告用的 SVG 图表（无第三方依赖）。
配色：dataviz 参考调色板 slot1 蓝 #2a78d6、slot2 橙 #eb6834（已用 validate_palette.js 验证）。"""
import csv, html, pathlib
ROOT = pathlib.Path(__file__).resolve().parents[3]
OUT = ROOT / "docs/report/figures"
REC = list(csv.DictReader(open(ROOT / "research/reve_route_20261113/benchmark_records.csv", encoding="utf-8-sig")))
GAP = list(csv.DictReader(open(ROOT / "research/reve_route_20261113/reve_task_gaps.csv", encoding="utf-8-sig")))
S1, S2, S3 = "#2a78d6", "#eb6834", "#1baf7a"
SURF, TXT, TXT2, GRID = "#ffffff", "#0b0b0b", "#52514e", "#e6e5e1"
FONT = "Inter, WenQuanYi Zen Hei, sans-serif"
def esc(s): return html.escape(str(s))
def get(proto, task, model):
    for r in REC:
        if r["protocol"] == proto and r["task"] == task and r["model"] == model:
            return float(r["mean"]), float(r["dispersion"] or 0)
    raise KeyError((proto, task, model))

class SVG:
    def __init__(s, w, h): s.w, s.h, s.el = w, h, []
    def add(s, x): s.el.append(x)
    def text(s, x, y, t, size=12, color=TXT, anchor="start", weight="normal"):
        s.add(f'<text x="{x:.1f}" y="{y:.1f}" font-size="{size}" fill="{color}" text-anchor="{anchor}" font-weight="{weight}" font-family="{FONT}">{esc(t)}</text>')
    def line(s, x1, y1, x2, y2, color=GRID, w=1, dash=None):
        d = f' stroke-dasharray="{dash}"' if dash else ""
        s.add(f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" stroke="{color}" stroke-width="{w}"{d}/>')
    def rect(s, x, y, w, h, color, r=2):
        s.add(f'<rect x="{x:.1f}" y="{y:.1f}" width="{max(w,0.5):.1f}" height="{h:.1f}" rx="{r}" fill="{color}"/>')
    def circle(s, x, y, r, color):
        s.add(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r}" fill="{color}" stroke="{SURF}" stroke-width="2"/>')
    def save(s, name):
        body = "\n".join(s.el)
        (OUT / name).write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{s.w}" height="{s.h}" viewBox="0 0 {s.w} {s.h}">'
                                f'<rect width="100%" height="100%" fill="{SURF}"/>{body}</svg>', encoding="utf-8")

def header(svg, title, sub, legend):
    pass
    for _ in [0]:
        pass
    x = 20
    for lab, col in legend:
        svg.rect(x, 14, 10, 10, col, 2); svg.text(x + 16, 23, lab, 11, TXT2); x += 28 + 11 * len(lab)

def axis(svg, x0, x1, y0, y1, vmax, ticks, unit="%", title="平衡准确率（%）"):
    for t in ticks:
        x = x0 + (x1 - x0) * t / vmax
        svg.line(x, y0, x, y1, GRID)
        svg.text(x, y1 + 15, f"{t}", 10, TXT2, "middle")
    svg.text((x0 + x1) / 2, y1 + 32, title, 10.5, TXT2, "middle")

# ---------- 图 1：NeuralBench，REVE 与各任务最佳模型 ----------
CN = {"Schizophrenia":"精神分裂症","Audiovisual":"视听刺激","Seizure":"癫痫发作","Parkinson's":"帕金森病","Mental imagery":"心理想象",
      "Dementia":"痴呆","Sleep arousal":"睡眠觉醒","Pathology":"异常 EEG","Image":"图像（top-5）","MMN":"失匹配负波","P300":"P300",
      "ERN":"错误相关负波","N400":"N400","Emotion":"情绪","Depression":"抑郁","Sex":"性别","LRP":"LRP","N2pc":"N2pc","SSVEP":"SSVEP",
      "Motor imagery":"运动想象","c-VEP":"c-VEP","Workload":"认知负荷","Sleep stage":"睡眠分期","Typing":"打字解码","Motor execution":"运动执行","Mental arith.":"心算","N170":"N170"}
rows = [g for g in GAP if g["protocol"] == "NeuralBench FT" and g["metric"] == "Balanced accuracy"]
rows.sort(key=lambda g: -float(g["gap"]))
W, top, rh = 860, 46, 21
H = top + rh * len(rows) + 44
svg = SVG(W, H)
header(svg, "NeuralBench：同一个 REVE，在不同任务上与最佳模型的差距",
       "统一微调协议，平衡准确率（%）；按差距从大到小排列。来源：NeuralBench 官方结果 JSON（提交 fe31393）",
       [("REVE", S1), ("该任务最佳模型", S2)])
x0, x1, vmax = 150, 740, 100
axis(svg, x0, x1, top - 6, top + rh * len(rows), vmax, [0, 20, 40, 60, 80, 100])
for i, g in enumerate(rows):
    y = top + rh * i + rh / 2
    r, b, gap = float(g["reve"]), float(g["best"]), float(g["gap"])
    svg.text(x0 - 10, y + 4, CN.get(g["task"], g["task"]), 11, TXT, "end")
    xr, xb = x0 + (x1 - x0) * r / vmax, x0 + (x1 - x0) * b / vmax
    if gap > 0:
        svg.line(xr, y, xb, y, "#c9c8c2", 1.5)
        svg.circle(xb, y, 4.5, S2)
        if gap >= 3: svg.text(xb + 9, y + 4, f'{g["best_model"]}  −{gap:.1f}', 10.5, TXT2)
    svg.circle(xr, y, 4.5, S1)
svg.save("fig_neuralbench_reve_gap.svg")

# ---------- 图 2：OmniEEG-Bench Benchmark-SSVEP，LP 与 FT ----------
models = ["REVE", "CBraMod", "LaBraM", "NeuroGPT", "BrainOmni", "BIOT", "NeuroLM", "EEGNet", "EEGConformer"]
W, top, gh = 760, 46, 30
H = top + gh * len(models) + 44
svg = SVG(W, H)
header(svg, "OmniEEG-Bench（Benchmark-SSVEP）：线性探测与全量微调的差距",
       "跨被试，平衡准确率（%）。来源：OmniEEG-Bench（arXiv 2606.00815）逐数据集结果表",
       [("线性探测 LP", S1), ("全量微调 FT", S2)])
x0, x1, vmax = 130, 690, 80
axis(svg, x0, x1, top - 6, top + gh * len(models), vmax, [0, 20, 40, 60, 80])
for i, m in enumerate(models):
    y = top + gh * i
    svg.text(x0 - 10, y + 16, "EEG Conformer" if m == "EEGConformer" else m, 11, TXT, "end")
    for j, (proto, col) in enumerate([("OmniEEG LP", S1), ("OmniEEG FT", S2)]):
        try: v, _ = get(proto, "Benchmark-SSVEP", m)
        except KeyError:
            continue
        svg.rect(x0, y + 4 + 11 * j, (x1 - x0) * v / vmax, 9, col, 2)
        if m in ("REVE", "CBraMod"): svg.text(x0 + (x1 - x0) * v / vmax + 5, y + 4 + 11 * j + 8.5, f"{v:.1f}", 10, TXT2)
svg.save("fig_omnieeg_ssvep_lp_ft.svg")

# ---------- 图 3：同一模型，不同协议下的 SSVEP ----------
items = [("OmniEEG-Bench LP", get("OmniEEG LP", "Benchmark-SSVEP", "REVE")[0]),
         ("FAME 论文 LP", get("FAME paper LP", "Benchmark SSVEP", "REVE")[0]),
         ("OmniEEG-Bench FT", get("OmniEEG FT", "Benchmark-SSVEP", "REVE")[0]),
         ("NeuralBench FT", float([g for g in GAP if g["task"] == "SSVEP"][0]["reve"])),
         ("FAME 论文 FT（附录 H）", get("FAME paper FT subset", "SSVEP", "REVE")[0])]
W, top, rh = 760, 22, 28
H = top + rh * len(items) + 44
svg = SVG(W, H)
x0, x1, vmax = 190, 690, 100
axis(svg, x0, x1, top - 6, top + rh * len(items), vmax, [0, 25, 50, 75, 100])
for i, (lab, v) in enumerate(items):
    y = top + rh * i
    svg.text(x0 - 10, y + 18, lab, 11, TXT, "end")
    svg.rect(x0, y + 8, (x1 - x0) * v / vmax, 11, S1, 2)
    svg.text(x0 + (x1 - x0) * v / vmax + 6, y + 18, f"{v:.1f}", 10.5, TXT2)
svg.save("fig_reve_ssvep_protocols.svg")

# ---------- 图 4：REVE 读出方式（REVE Table 4） ----------
tasks = ["Faced", "BCIC2020-3", "BCIC-IV-2a", "TUEV", "HMC", "ISRUC", "PhysioNetMI", "Mumtaz", "M. Arithmetic", "TUAB"]
W, top, gh = 760, 46, 30
H = top + gh * len(tasks) + 44
svg = SVG(W, H)
header(svg, "REVE-Base 冻结表示：池化读出与不池化读出",
       "线性探测，平衡准确率（%）。同一表示，只换读出方式。来源：REVE（arXiv 2510.21585）Table 4",
       [("池化（pooled）", S1), ("不池化（全部 token 展平）", S2)])
x0, x1, vmax = 130, 690, 100
axis(svg, x0, x1, top - 6, top + gh * len(tasks), vmax, [0, 20, 40, 60, 80, 100])
for i, t in enumerate(tasks):
    y = top + gh * i
    svg.text(x0 - 10, y + 16, t, 11, TXT, "end")
    vals = []
    for j, (m, col) in enumerate([("REVE-B (Pool)", S1), ("REVE-B", S2)]):
        v, _ = get("REVE readout ablation LP", t, m); vals.append(v)
        svg.rect(x0, y + 4 + 11 * j, (x1 - x0) * v / vmax, 9, col, 2)
    d = vals[1] - vals[0]
    if abs(d) >= 5: svg.text(x0 + (x1 - x0) * max(vals) / vmax + 6, y + 18, f"{d:+.1f}", 10.5, TXT, weight="bold")
svg.save("fig_reve_readout.svg")

# ---------- 图 5：SEED-VIG 回归（AdaBrain-Bench） ----------
vig = [("BIOT", 27.09, 1), ("EEGNet", 26.65, 0), ("LaBraM", 25.35, 1), ("EEGPT", 23.47, 1), ("LDMA", 11.15, 0),
       ("ST-Tran", 3.98, 0), ("EEG Conformer", 2.55, 0), ("CBraMod", 2.40, 1)]
W, top, rh = 760, 46, 26
H = top + rh * len(vig) + 44
svg = SVG(W, H)
header(svg, "回归任务 SEED-VIG（警觉度估计）：基础模型没有明显优于从零训练",
       "跨被试，全量微调，R²（%）。来源：AdaBrain-Bench（arXiv 2507.09882）Table 2 / 官方 README",
       [("预训练基础模型", S1), ("从零训练的监督模型", S2)])
x0, x1, vmax = 130, 690, 30
axis(svg, x0, x1, top - 6, top + rh * len(vig), vmax, [0, 10, 20, 30], title="R²（%）")
for i, (m, v, fm) in enumerate(vig):
    y = top + rh * i
    svg.text(x0 - 10, y + 16, m, 11, TXT, "end")
    svg.rect(x0, y + 7, (x1 - x0) * v / vmax, 11, S1 if fm else S2, 2)
    if m in ("BIOT", "EEGNet", "CBraMod"): svg.text(x0 + (x1 - x0) * v / vmax + 6, y + 16.5, f"{v:.1f}", 10.5, TXT2)
svg.save("fig_seedvig_regression.svg")
print("ok")
