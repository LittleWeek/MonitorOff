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

需要 [Zig](https://ziglang.org/) 0.17.0，只依赖系统 DLL（user32/gdi32/shell32/advapi32/dwmapi）：

```bash
zig build-exe monitor-off.zig icon/icon.res -O ReleaseSmall --subsystem windows -lgdi32 -lshell32 -ladvapi32 -ldwmapi
```

产物是 `monitor-off.exe`（`icon/icon.res` 是预先编好的图标资源，链接时一起塞进 exe）。

改图标的话：`python icon/gen_icon.py` 会按原 SVG 的几何比例重绘显示器图标（脚本里 4x 超采样抗锯齿），生成多尺寸 `icon.ico` 和 `icon_preview.png`；再用资源编译器把 `icon.rc` 编成 `icon.res`，重新链接即可。

## 目录结构

```
monitor-off/
├── monitor-off.zig      源码（单文件，零依赖）
├── monitor-off.exe      构建产物
├── icon/                图标：生成脚本、ico、rc、res、预览图
├── docs/settings.png    设置窗口截图（README 用）
├── tools/shot.py        界面自检截图（开发用）
├── README.md
├── LICENSE
└── .gitignore
```
