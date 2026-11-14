# 报告图表索引

2026-11-14 晚生成。供后续润色会话使用：每张图的出处、数据来源与可改动范围。

## 自绘图表（数据图，SVG + PNG）

图中只保留标题、图例和数值，出处写在报告图注里。由 [`../build/make_charts.py`](../build/make_charts.py) 从 [`research/reve_route_20261113/benchmark_records.csv`](../../../research/reve_route_20261113/benchmark_records.csv) 与 `reve_task_gaps.csv` 生成；PNG 由 [`../build/svg2png.js`](../build/svg2png.js) 渲染（2 倍分辨率，供 PPT 使用）。配色为 dataviz 参考调色板前两个槽位（蓝 #2a78d6、橙 #eb6834），已用调色板校验脚本验证。

| 文件 | 报告中的编号 | 内容 | 数据来源 |
|---|---|---|---|
| `fig_neuralbench_reve_gap` | 图 1 | REVE 与各任务最佳模型的差距（平衡准确率任务） | NeuralBench 官方结果 JSON，提交 fe31393 |
| `fig_reve_readout` | 图 3 | REVE-Base 冻结表示：池化 vs 不池化读出 | REVE arXiv v1 Table 4 |
| `fig_seedvig_regression` | 图 4 | SEED-VIG 回归 R² | AdaBrain-Bench arXiv v2 Table 2（数值手工录入脚本） |
| `fig_reve_ssvep_protocols` | 图 5 | 同一个 REVE 在不同协议下的 SSVEP | OmniEEG-Bench、FAME（LP 表与附录 H）、NeuralBench |
| `fig_omnieeg_ssvep_lp_ft` | 图 6 | Benchmark-SSVEP 上 LP vs FT | OmniEEG-Bench 逐数据集表 |

**注意**：图 5 汇集了不同协议的结果，只用于说明“分数主要由协议决定”，不得当作排行榜。

## 自绘示意图（HTML → PNG）

| 文件 | 编号 | 内容 |
|---|---|---|
| `fig_method_arch.html/.png` | 图 20 | 本方案架构（保留 / 新增 / 目标 / 下游四类模块） |
| `fig_pipeline.html/.png` | 图 21 | 复赛三步 + 消融 → 判读规则 → 决赛 |

架构图中的门控热力图是**示意**，不是实验结果，图中已注明。修改 HTML 后运行 `node ../build/svg2png.js fig_method_arch.html` 重新生成 PNG。

## 引用的论文原图（`related/`）

均从 arXiv HTML 版下载，报告图注已写“图源：原论文 Fig. N”。正式提交前确认各论文的许可证允许转载；若有疑虑，可改为自绘示意。

| 文件 | 编号 | 论文 |
|---|---|---|
| `FAME_fig3.png` | 图 2 | FAME（arXiv 2608.01898）Fig. 3：低频偏置 |
| `REVE_fig1.png` | 图 7 | REVE（2510.21585）Fig. 1 |
| `CBraMod_fig2.png` | 图 8 | CBraMod（2412.07236）Fig. 2 |
| `LaBraM_fig1.png` | 图 9 | LaBraM（2405.18765）Fig. 1 |
| `CSBrain_fig2.png` | 图 10 | CSBrain（2506.23075）Fig. 2 |
| `BrainOmni_fig1.png` | 图 11 | BrainOmni（2505.18185）Fig. 1 |
| `BIOT_fig1.jpg` | 图 12 | BIOT（2305.10351）Fig. 1 |
| `FAME_fig2.png` | 图 13 | FAME Fig. 2 |
| `NeuroLM_fig3.png` | 图 14 | NeuroLM（2409.00101）Fig. 3 |
| `UniMind_fig2.png` | 图 15 | UniMind（2506.18962）Fig. 2 |
| `ECHO_fig2.png` | 图 16 | ECHO（2509.22556）Fig. 2 |
| `JEPA-Anything_fig1.png` | 图 17 | JEPA-Anything（2609.20800）Fig. 1（已缩小到 1600 px 宽） |
| `H-JEPA_fig1.png` | 图 18 | H-JEPA（2610.06805）Fig. 1 |
| `H-JEPA_fig4.png` | 图 19 | H-JEPA Fig. 4 |
| `CBraMod_fig1.png` | 未用 | CBraMod Fig. 1（不同建模策略对比，可用于 PPT） |

缺：EEGPT（只有 NeurIPS 正式版，arXiv 无 HTML）、Neuro-KE（正文未公开）。
