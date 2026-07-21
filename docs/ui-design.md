# UI 设计系统规范

> 一句话系统：**暖中性纸面 UI + 单一陶土 accent + 全高地图，地图是内容、控制台面板是数据。**
> 原型：[`direction-c-atlas.html`](direction-c-atlas.html) · 独立页面：`index.html` ~ `api.html`（共 10 页）。

---

## 0. 为什么是 Atlas

产品战略已转向「地图优先 + i18n API 平台」，受众 = 开发者（API 接入）/ 贡献者（提交表达）/ 探索者（地图浏览）。地图是差异化，因此地图为封面、为工作面；UI 退到侧栏与控制台，不与地图抢彩。本规范定义这套唯一视觉语言。

---

## 1. 设计原则

1. **色少而准** — 中性暖灰为主（约 90% 界面），单一陶土 accent 仅用于：主 CTA、当前选中、链接、坐标读数。
2. **密度优先** — 行高桌面 36–44px；卡片内边距 `p-3/4` 而非 `p-6/8`；垂直节奏以 `gap-2/3` 为主。
3. **去装饰** — 无渐变背景、无渐变文字、无 blob 动画；阴影最多一层 hairline；圆角统一 4px。
4. **信息层级靠排版** — 正文 > 语言/地域 meta > 操作；数字一律 `tabular-nums` 或等宽。
5. **语言平等** — 所有语言地位相同，无源/目标语言层级。语言码一律 mono（`cmn` `nan` `yue`），彩色点仅作可选偏好。
6. **地图是内容不是海报** — 地图满宽全高；图例压缩为单行；热力用单色阶（同色相明度变化）。

## 2. 签名动作（反 AI 味道 · 不可模仿）

- **地图 pin 辉光** — hover/active 时 pin 放大 1.2× 并外扩 3px ring + 16px accent 辉光。
- **大字号坐标读数** — 详情头坐标以 14px mono、accent 色、`letter-spacing 0.06em`、`tabular-nums` 呈现，作为地理产品的「读数感」锚点。
- **dot-grid 控制台面板** — 侧栏/控制台底纹为 20px 网格的极浅暖灰圆点，配合 mono uppercase tab 标签，读作「GIS 控制台」而非「SaaS 卡片」。点阵背景现在应用于所有页面的主内容区。

---

## 3. 颜色系统

全部用 OKLch 定义。六枚基础 token 是全站唯一色源，其余均为派生。

### 3.1 基础 token

| Token | 值 | 用途 |
|---|---|---|
| `--bg` | `oklch(0.975 0.008 85)` | 页面底色（暖近白） |
| `--surface` | `oklch(1 0 0)` | 面板/卡片表面（纯白） |
| `--fg` | `oklch(0.20 0.015 55)` | 正文（暖近黑） |
| `--muted` | `oklch(0.52 0.010 200)` | 次要文字、meta、坐标码 |
| `--border` | `oklch(0.88 0.008 95)` | 全站 hairline 边框 |
| `--accent` | `oklch(0.64 0.16 35)` | 陶土 · 主 CTA/选中/链接/坐标 |
| `--accent-soft` | `oklch(0.96 0.04 35)` | accent 的浅底（选中行/芯片） |

### 3.2 地图色

| Token | 值 | 用途 |
|---|---|---|
| `--map-land` | `oklch(0.89 0.022 88)` | 陆地底色 |
| `--map-water` | `oklch(0.84 0.030 218)` | 水域底色（冷蓝灰，非营销蓝） |

### 3.3 热力色阶（单色相 · 明度递减）

| Token | 值 | 档位 | 圆点尺寸 |
|---|---|---|---|
| `--heat-1` | `oklch(0.84 0.08 55)` | `<5k` | 14px |
| `--heat-2` | `oklch(0.68 0.14 38)` | `<50k` | 22px |
| `--heat-3` | `oklch(0.54 0.18 28)` | `≥50k` | 32px |

### 3.4 语义状态色

| Token | 值 | 语义 |
|---|---|---|
| `--ok` | `oklch(0.62 0.14 155)` | 已验证 / 接受 |
| `--warn` | `oklch(0.65 0.14 60)` | 警告 |
| `--nil` | `oklch(0.78 0.012 88)` | 空缺 |

### 3.5 代码终端深色调（API 接入页专用）

| 角色 | 背景 | 边框 | 文字 |
|---|---|---|---|
| code-block | `oklch(0.12 0.012 220)` | `oklch(0.22 0.020 220)` | `oklch(0.88 0.01 200)` |
| terminal | `oklch(0.11 0.014 215)` | `oklch(0.20 0.020 215)` | `oklch(0.86 0.010 200)` |

语法高亮：keyword `oklch(0.68 0.12 285)` · string `oklch(0.75 0.10 155)` · number `oklch(0.75 0.12 55)` · comment `oklch(0.46 0.015 200)` · attr/key `oklch(0.65 0.10 195)`。

### 3.6 用色规则

- accent 每屏至多出现 2 处；不得用作大面积底色或渐变。
- 禁止：紫/蓝渐变 Logo 与 CTA、彩虹热力、暖米默认画布。
- 来源标签（权威/AI/用户）用 **边框+文字**，不用三色块。

---

## 4. 字体与排版

### 4.1 字体栈

| Token | 栈 | 用途 |
|---|---|---|
| `--font` | `"Inter", system-ui, sans-serif` | 全部界面、正文 |
| `--mono` | `"IBM Plex Mono", ui-monospace, monospace` | 语言码、坐标、tab 标签、数字、代码 |

### 4.2 字号阶梯

| 角色 | 字号 | 字重 | 备注 |
|---|---|---|---|
| 详情标题 h1 | 18px | 600 | `letter-spacing -0.02em` |
| API 步骤标题 | 14px | 600 | `letter-spacing -0.02em` |
| 坐标读数 | 14px | — | mono · `tabular-nums` · `ls 0.06em` · accent 色 |
| 正文 | 13px | 400 | line-height 1.4 |
| 列表词条 | 13px | 500 | |
| 详情段落 | 12px | 400 | line-height 1.5 |
| 代码块 | 12px | — | mono · line-height 1.7 |
| 区块小标题 h2 | 10px | 600 | mono · uppercase · `ls 0.08em` · muted |
| tab 标签 | 10px | 500 | mono · uppercase · `ls 0.06em` |
| 语言码/坐标码 | 10–11px | — | mono |

### 4.3 数字与语言码

- 所有数字（计数、坐标、统计）启用 `font-variant-numeric: tabular-nums`。
- 语言一律用 ISO 短码 mono 呈现（`cmn` `nan` `yue` `en` `ja`），不用彩色胶囊。

---

## 5. 间距、圆角、层级

| Token | 值 |
|---|---|
| `--r`（圆角） | 4px |
| `--panel-w`（侧栏宽） | 380px |
| `--bar-h`（顶栏高） | 40px |

- 圆角统一 4px；芯片（filter chip）用全圆 `999px`。
- 阴影几乎无：靠 1px `--border` 分层；HUD 卡片允许 `0 1px 2px oklch(0 0 0 / 0.04)`。
- HUD/面板叠在地图上时用 `backdrop-filter: blur(8px)` + 92% surface。
- 触控目标 ≥ 44px（移动端）；桌面按钮高 28px。

---

## 6. 地图系统

- 满宽全高 `.map-stage`，背景 `--map-water`，陆地用 `--map-land` 抽象或 Leaflet 灰度底图。
- **热力 pin**：圆形，`transform: translate(-50%,-50%)`；hover/active 放大 1.2×，`box-shadow: 0 0 0 3px oklch(0.64 0.16 35 / 0.25), 0 0 16px oklch(0.64 0.16 35 / 0.45)` —— 签名辉光。
- **pin 标签**：深底（`--fg`）浅字（`--surface`）、mono 10px、2px 圆角，hover/active 显现。
- **HUD**：四角浮卡，单行图例（`<5k / <50k / ≥50k` 三色点），缩放为 30×28 双键栈。
- 图例/统计压缩为单行 pill 或纯文字，**不占独立大区块**。

---

## 7. 组件规范

- **顶栏（40px）**：logo `LangMap` + mono accent 徽标 `ATLAS`；居中搜索条（28px，`/` 唤起）；右侧统计 + 操作按钮。
- **导航（4 项）**：地图 · 语言 · 手册 · 贡献。mono uppercase tab 标签，选中态 accent-soft 底。
- **侧栏（380px）**：mono uppercase tab；底纹为 dot-grid；行列表 `grid 1fr auto`，选中行 accent-soft 底 + 左 2px accent 内边条。
- **filter chip**：24px、`999px`、muted；`on` 态 accent-soft 底 + accent 边。
- **对照表**：行式 `grid [lang 44px | text 1fr | region auto]`，lang/region 用 mono 10px muted。
- **按钮**：Primary（accent 实底白字）/ Ghost（surface 底 + border）/ btn-icon（28px 方形）；禁用渐变。
- **来源标签**：边框 + 文字（权威/AI/用户），不填色块。
- **点阵背景**：`radial-gradient(circle, oklch(0.86 0.010 88) 1px, transparent 1px); background-size: 20px 20px;` 应用于所有页面的 `.page`、`.content-page`、`.content-main` 容器。

---

## 8. 页面结构（10 页）

### 地图探索（封面/工作面）
1. **index.html** — 顶栏 + 侧栏（结果/详情/语言）+ 全高地图。详情侧栏内嵌不全页跳转，保留 deep link。
2. **search.html** — 搜索控制台，左输入 + 右结果列表，底部 dot-grid 面板。
3. **entry-detail.html** — 词条详情，左 rail（标题 + 坐标读数 + meta + 语义 + 对照表）+ 右地图。

### 语言
4. **languages.html** — 语言列表，按语系分组。
5. **language-detail.html** — 单语言详情，地理分布 + 表达列表 + 相关手册。

### 手册
6. **handbooks.html** — 手册列表，卡片网格。
7. **handbook-view.html** — 手册阅读 + 编辑合并，左 TOC 目录 + 右内容区，模式切换（查看/编辑）。

### 贡献
8. **collections.html** — 收藏列表 + 详情合并，面板切换。
9. **contribute.html** — 纯表达编辑器：语言→表达 表格 + 坐标输入 + 提交/草稿。无 tab、无审核队列。

### 开发者
10. **api.html** — 左步骤面板 + 右深色终端区。

移动端（≤800px）：地图全屏 + 面板缩为底部 sheet；隐藏顶栏统计。

---

## 9. 术语规范

- **表达（expression）**：用户提交的语言片段，不区分源/目标语言。
- **语言（language）**：所有语言地位平等，无源/目标层级。
- **区域（region）**：表达的使用地域。
- **手册（handbook）**：语言学习资料，支持多人协作编辑。

---

## 10. 协作模型

- **开放协作**：贡献直接发布，无审核队列。
- **手册编辑**：支持查看/编辑模式切换，页面级粒度。
- **收藏**：用户可收藏词条、表达、手册。

---

## 11. 暗色模式（P2）

同 token 反相，仍低彩：`--bg/surface` → 深炭 `oklch(0.16 0.008 260)` 一带；`--fg` ↔ `oklch(0.92 0.005 85)`；accent 明度提至约 `oklch(0.70 0.15 40)`；地图水域转深。不在首版实现。

---

## 12. 反 slop 红线（验收用）

- [ ] 无紫/蓝渐变 Logo、CTA、文字
- [ ] 无每卡不同渐变底、无大圆角重阴影 SaaS 卡
- [ ] 热力图例为单色阶，非彩虹
- [ ] 圆角统一 4px（芯片除外）；阴影最多一层 hairline
- [ ] accent 每屏 ≤ 2 处；来源标签为边框+文字
- [ ] 语言码 mono、数字 tabular；保留三处签名动作（pin 辉光/坐标读数/dot-grid 面板）
- [ ] 无源/目标语言层级；术语用「表达」不用「译文」

---

*基于仓库：`langmap` · 原型 `direction-c-atlas.html` · 独立页面 10 页。*
