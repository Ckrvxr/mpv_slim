# mpv_slim

精简但质量不低的 mpv 播放器。

## SOFA 空间音频

`models/sofas/` 下放 HRIR 文件自动识别。菜单里选 BYPASS 跳过，选文件启用。支持距离和增益微调。

内置 14 个 HRIR 文件：ClubFritz1–12、SADIEII D1/D2。

## 响度标准化

内置 14 种预设：

| 预设 | 适用 |
|------|------|
| EBU R128 | 欧洲广播 |
| ATSC A/85 | 北美广播 |
| Netflix Dialogue / Non-Dialogue | Netflix |
| Disney+ | Disney+ |
| Apple TV+ | Apple TV+ |
| Amazon Prime Video | Amazon Prime |
| YouTube | YouTube |
| Hulu | Hulu |
| Apple Music | Apple Music（Sound Check） |
| Spotify Normal / Loud / Quiet | Spotify |
| Tidal HiFi | Tidal |
| Dolby Cinema / Classical | 杜比影院 / 古典乐 |

## EQ 均衡器

`models/equalizers/` 下放 GraphicEQ 格式的 `.txt`，自动扫入菜单。BYPASS 跳过。

## 完美色调映射

完整 HDR 参数调节菜单：

- **Tone Map Method** — spline（推荐）、bt.2390（推荐）、bt.2446a（推荐）、hable、mobius、reinhard、clip、linear
- **Gamut Mapping** — perceptual（推荐）、auto、absolute、clp、darken、desaturate、linear、relative、saturation、warn
- **Target Peak** — 步进 ±1/±10/±100，quick-set =auto（推荐）、=203（推荐）、=1000
- **Compute Peak** — 开关，开时调节 peak percentile 和 peak decay rate

## RAVU + ArtCNN

升频器菜单，7 种运行时热切换（change-list append/remove，不卡顿）：

**RAVU** — ravu-zoom-ar-r3.hook

**ArtCNN** — C4F32、C4F32_DS、C4F32_DN、C4F16、C4F16_DS、C4F16_DN

菜单 radio 选择，选中即切换。

## NLMeans 降噪

一键 ON/OFF。an3223 三阶段 NLMeans shader，挂载在 LUMA+CHROMA。

## 快速开始

```bash
git clone https://github.com/Ckrvxr/mpv_slim.git portable_config
```

需要安装字体：
- TsukuARdGothic Std Medium
- modernz-icons.ttf（`script-opts/` 内）

SOFA 文件放 `models/sofas/`，EQ 预设放 `models/equalizers/`，菜单自动识别。

OSC 底栏三个按钮分别打开音频 / 视频 / 字幕菜单。菜单内可保存当前值为默认，下次启动自动加载。

## 快捷键

| 按键 | 功能 |
|------|------|
| T | 字幕放大 +0.1 |
| t | 字幕缩小 -0.1 |
| j | 字幕位置 -1 |
| k | 字幕位置 +1 |

## 依赖

- mpv ≥ 0.41.0
- ModernZ v0.3.3（已集成）
- thumbfast（已集成）
- alass（可选，字幕同步）

## 致谢

ModernZ、thumbfast、alass、an3223（NLMeans）、ArtCNN、RAVU 作者。
