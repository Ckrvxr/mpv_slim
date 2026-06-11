# mpv_slim — mpv 配置项目 Skill

## 安装

### Windows
```powershell
scoop install mpv
git clone <repo> "$(scoop prefix mpv)/portable_config"
# 或
git clone <repo> "$env:APPDATA/mpv"
```

### Linux / macOS
```bash
brew install mpv
git clone <repo> ~/.config/mpv
```

## 脚本入口（script-message）

三个自定义菜单，通过 `modernz.lua` 的 OSC 按钮或快捷键调用：

| 菜单 | script-message | 主脚本 |
|------|---------------|--------|
| 音频 | `mpv_slim_audio-option-show-menu` | `scripts/mpv_slim_audio-option.lua` |
| 视频 | `mpv_slim_video-option-show-menu` | `scripts/mpv_slim_video-option.lua` |
| 字幕 | `mpv_slim_subtitle-option-show-menu` | `scripts/mpv_slim_subtitle-option.lua` |

快捷键调用示例（`input.conf`）：
```
A script-message mpv_slim_audio-option-show-menu
V script-message mpv_slim_video-option-show-menu
S script-message mpv_slim_subtitle-option-show-menu
```

## 跨平台差异

| 项目 | Windows | Linux | macOS |
|------|---------|-------|-------|
| 配置目录 | `scoop prefix mpv/portable_config` | `~/.config/mpv/` | `~/.config/mpv/` |
| 字体 | `~~/fonts/` 自动加载 (mpv ≥0.35) | 同左 | 同左 |
| alass 二进制 | `script-opts/alass/bin/alass-cli.exe` | `script-opts/alass/bin/alass-cli-linux` | `brew install alass` |
| hardware decode | `nvdec-copy` / `d3d11va-copy` | `vaapi-copy` | `videotoolbox-copy` |

## 依赖

- **alass-cli** — 字幕音频指纹同步（Windows/Linux 已打包，macOS `brew install alass`）
- **ffmpeg** — alass 需要，各平台包管理器安装

## AI 代理规则

1. **第三方脚本标记**：修改 `thumbfast.lua`、`modernz.lua` 等外部脚本必须用 `-- modified by mpv_slim: <section>` 包裹改动
2. **不碰字体**：不修改 `fonts/` 目录中的 `.ttf` 文件
3. **添加菜单流程**：
   - 在 `*option.lua` 的 `show_menu()` 加 `menu_state` 分支
   - 在 `submit()` handler 加对应逻辑
   - 在 `modernz.lua` 的按钮回调加 `script-message` 调用
4. **默认文件**：`script-opts/mpv_slim_*-defaults.lua` 由菜单的 Save 功能自动生成
