[English](README.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [日本語](README.ja.md) · **中文** · [हिन्दी](README.hi.md)

# Chordex FM

为 [monome norns](https://monome.org/docs/norns/) 设计的和弦乐器，搭载 4 算子 FM 引擎（DX / TX81Z 风格）。按一个键会奏出一个四音和弦加低音；按住的最低键决定根音。

![Chordex FM 的六个模型](docs/sheet.png)

**屏幕就是 FM**，用与发声相同的公式绘制：

- **左侧，算法：** 4 个算子以圆圈表示。亮度代表各自的包络，圆内旋转的点以其频率比的速度转动，连线代表调制（流动的粒子 = 调制指数的大小），算子 4 上的小环代表反馈。下方是 9 个推子。
- **中央，花朵：** 音符的真实波形，以极坐标绘制。调制指数低时是一个平滑的圆；指数高时会长满花瓣和尖刺。虚影轮廓代表 fatness，火花代表 shimmer 和噼啪声，中间是 12 音轮上的和弦。每个琶音音符都会像彗星一样飞出。
- **右侧：** 示波器（一个周期）和频谱（FM 产生的泛音与边带）；下方是琶音型。

## 功能

- **4 算子 FM**：8 种算法、频率比、算子 4 反馈、每个算子独立的包络，以及调制器「扫频」
- **10 个模型**：EPIANO（电钢琴）、CAMPANA（钟）、METAL（金属）、CORO（合唱）、BAJO（贝斯）、ORGANO（风琴）、MARIMBA（马林巴）、CUERDAS（弦乐）、FLAUTA（长笛）、VIDRIO（玻璃）
- **10 种和弦**：maj, min, dim, aug, 7, maj7, min7, m7b5, sus2, sus4
- **琶音器**：up, down, up-down, up x2, down x2, random 和 *arpa*（竖琴）；门限调到最大即为真正的连奏
- **和弦模式** 开/关（关 = 单音）以及**保持**
- 同时按住两个以上的键时，会出现老唱片的噼啪声
- 琶音速度跟随外部 MIDI 时钟
- 所有设置自动保存

属于 Chordex 系列：操作方式与 Chordex80 相同。

<!-- u-ma:family -->
## Chordex 系列

操作相同，引擎不同。也来试试其他几款：

| | |
|---|---|
| <a href="https://github.com/buenosairesfront/chordex80/blob/main/README.zh.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordex80/main/docs/1_d50.png" width="200" alt="Chordex 80"></a> | **[Chordex 80](https://github.com/buenosairesfront/chordex80/blob/main/README.zh.md)**<br>80 年代复音合成器，配 outrun 日落画面<br>`;install https://github.com/buenosairesfront/chordex80` |
| <a href="https://github.com/buenosairesfront/chordexstg/blob/main/README.zh.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexstg/main/docs/2_tutti.png" width="200" alt="ChordexSTG"></a> | **[ChordexSTG](https://github.com/buenosairesfront/chordexstg/blob/main/README.zh.md)**<br>管弦乐弦乐，呈现真实的拉弦运动<br>`;install https://github.com/buenosairesfront/chordexstg` |
| <a href="https://github.com/buenosairesfront/chordexwt/blob/main/README.zh.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexwt/main/docs/2_vocal.png" width="200" alt="Chordex WT"></a> | **[Chordex WT](https://github.com/buenosairesfront/chordexwt/blob/main/README.zh.md)**<br>波表：8 个库、每库 8 个波形，画成 3D 波表<br>`;install https://github.com/buenosairesfront/chordexwt` |
| <a href="https://github.com/buenosairesfront/chordexchip/blob/main/README.zh.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexchip/main/docs/1_nes.png" width="200" alt="Chordex CHIP"></a> | **[Chordex CHIP](https://github.com/buenosairesfront/chordexchip/blob/main/README.zh.md)**<br>芯片音乐：8 种游戏机芯片 × 8 个预设，画成 tracker<br>`;install https://github.com/buenosairesfront/chordexchip` |

**更多 U-MA 作品：** 所有乐器和工具汇集一处 → [U-MA 作品集](https://github.com/buenosairesfront/U-ma/blob/main/README.zh.md)
<!-- /u-ma:family -->

## 需求

- norns（shield、标准版或 fates）
- MIDI 键盘或控制器

## 安装

在 maiden 中输入：

```
;install https://github.com/buenosairesfront/chordexfm
```

然后**重启 norns**（SYSTEM > RESTART）以编译新引擎 `ChordexFM`，再从 SELECT 加载 **chordexfm**。

## 操作

| 操作 | 功能 |
|---|---|
| E1 | FM 调制指数（亮度） |
| E2 | 选择推子 |
| E3 | 调节推子 |
| K3 + E1 | 模型 |
| K3 + E2 | 算子 4 反馈 |
| K3 + E3 | 和弦类型 |
| 按住 K3（不转动旋钮） | 和弦模式 开/关 |
| K2（轻按） | 琶音器 开/关 |
| K2 + E1 | 琶音门限（最大 = 连奏） |
| K2 + E2 | 琶音型 |
| K2 + E3 | 琶音速度 |
| 按住 K1 | 保持 开/关（右上角的小点） |

**推子：** 起音、衰减、算子 2 频率比、算法、扫频（调制器衰减）、失真、摇摆（wobble）、fatness、shimmer。

**PARAMETERS 菜单：** MIDI 通道（0 = 全部，默认）、MIDI 时钟分频、大厅混响、音量，以及以上所有参数。

## 图库

| | |
|---|---|
| ![EPIANO](docs/1_epiano.png) EPIANO · maj7 | ![CAMPANA](docs/2_campana.png) CAMPANA（钟） |
| ![METAL](docs/3_metal.png) METAL · 高调制指数 | ![ORGANO](docs/4_organo.png) ORGANO（风琴） |
| ![CUERDAS](docs/5_cuerdas_arp.png) CUERDAS（弦乐）· 琶音 | ![VIDRIO](docs/6_vidrio.png) VIDRIO（玻璃） |

## 致谢

由 [Buenos Aires Front](https://github.com/buenosairesfront) / U-MA 制作。
MIT 许可证。
