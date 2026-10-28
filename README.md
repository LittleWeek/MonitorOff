# monitor-off

Windows 上的显示器关闭小工具：一个快捷键把屏幕关掉，托盘常驻、无依赖，单个 exe 约 0.08 MB。

<img src="docs/settings.png" width="400" alt="设置窗口">

## 功能

- **一键关屏**：默认 `Win + Alt + L`，快捷键可在设置窗口里自己录（支持 Ctrl/Alt/Win + 任意键组合），也能清除或重置回默认
- **托盘常驻**：左键点图标打开设置窗口，右键弹出自绘菜单（关闭显示器 / 设置… / 退出）
- **四项设置**：快捷键、开机自启、托盘常驻、隐藏托盘（隐藏后图标不显示，快捷键照常可用，双击 exe 即打开设置窗口）
- **单实例**：重复启动不会开第二份，而是把已运行实例的设置窗口叫到前台
- 关闭设置窗口 = 收进托盘（常驻开启时）；关闭托盘常驻后，关闭窗口即退出
- 界面全自绘（标题栏、开关、菜单），跟随系统 DPI，Win11 下圆角

## 资源占用

实测环境：Windows 11、`-O ReleaseSmall` 构建，内存数据取自 `GetProcessMemoryInfo` 与 `Win32_PerfFormattedData_PerfProc_Process`，各状态采样 5 次取范围。

| 指标 | 实测值 |
| --- | --- |
| exe 体积 | 0.081 MB |
| 任务管理器内存占用 | 0.6–3.6 MB |
| 空闲 CPU | 0.000%（20 秒累计 0 ms） |

托盘常驻时只等快捷键和托盘消息，不轮询；菜单用的位图缓冲在收起时释放，反复开合不会累积。

## 配置存放位置

全部在注册表 `HKEY_CURRENT_USER` 下，删掉即恢复默认：

- `Software\MonitorOff` —— 各项开关与快捷键组合（`HotkeyEnabled` / `HotkeyMods` / `HotkeyVK` / `TrayResident` / `HideTray`）
- `Software\Microsoft\Windows\CurrentVersion\Run\MonitorOff` —— 开机自启项

## 构建

需要 [Zig](https://ziglang.org/) 0.17.0，只依赖系统 DLL（user32/gdi32/shell32/advapi32/dwmapi）。

`icon/icon.res` 是构建产物（`*.res` 不入库），所以要先把它从 `icon.rc` 编出来，再链接：

```bash
# 1) 生成图标资源
zig rc icon/icon.rc icon/icon.res

# 2) 编译（把刚生成的 icon.res 一起链进去）
zig build-exe monitor-off.zig icon/icon.res -O ReleaseSmall --subsystem windows -lgdi32 -lshell32 -ladvapi32 -ldwmapi
```

`zig rc` 是 Zig 自带的资源编译器，不需要额外装 windres 之类的工具。产物是 `monitor-off.exe`，约 0.081 MB。

改图标的话：`python icon/gen_icon.py` 会按原 SVG 的几何比例重绘显示器图标（脚本里 4x 超采样抗锯齿），生成多尺寸 `icon.ico` 和 `icon_preview.png`；再重跑上面两步即可（第 1 步会把新的 `icon.ico` 重新打包进 `icon.res`）。

## 目录结构

```
monitor-off/
├── monitor-off.zig      源码（单文件，零依赖）
├── monitor-off.exe      构建产物
├── icon/                图标：生成脚本、ico、rc、预览图（res 由构建生成）
├── docs/settings.png    设置窗口截图（README 用）
├── tools/shot.py        界面自检截图（开发用）
├── README.md
├── LICENSE
└── .gitignore
```
