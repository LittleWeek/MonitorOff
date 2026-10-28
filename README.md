# monitor-off

Windows 上的显示器关闭小工具：一个快捷键把屏幕关掉，托盘常驻、无依赖，单个 exe 约 80 KB。

<img src="docs/settings.png" width="400" alt="设置窗口">

## 功能

- **一键关屏**：默认 `Win + Alt + L`，快捷键可在设置窗口里自己录（支持 Ctrl/Alt/Win + 任意键组合），也能清除或重置回默认
- **托盘常驻**：左键点图标打开设置窗口，右键弹出自绘菜单（关闭显示器 / 设置… / 退出）
- **四项设置**：快捷键、开机自启、托盘常驻、隐藏托盘（隐藏后图标不显示，快捷键照常可用，双击 exe 即打开设置窗口）
- **单实例**：重复启动不会开第二份，而是把已运行实例的设置窗口叫到前台
- 关闭设置窗口 = 收进托盘（常驻开启时）；关闭托盘常驻后，关闭窗口即退出
- 界面全自绘（标题栏、开关、菜单），跟随系统 DPI，Win11 下圆角

## 使用

直接运行 `monitor-off.exe`。开机自启开起来后，系统会以 `monitor-off.exe /tray` 静默启动（不弹设置窗口，只进托盘）。

托盘图标：

| 操作 | 结果 |
| --- | --- |
| 左键单击 | 打开设置窗口 |
| 右键单击 | 弹出菜单：关闭显示器 / 设置… / 退出 |
| 双击 exe（隐藏托盘时） | 打开设置窗口 |

设置窗口里四行依次是：快捷键（右侧按钮录制，× 清除 / ↺ 重置为默认）、开机自启、托盘常驻、隐藏托盘（后三行是开关）；下方「立即关闭显示器」等同于按一次快捷键。

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

## 说明

- 支持 Windows 10 / 11；Win10 下窗口是直角（圆角依赖 DWM 属性）
- 关屏调用 `WM_SYSCOMMAND` + `SC_MONITORPOWER`，只是关显示器，不会锁屏或休眠
- 快捷键注册失败（被别的程序占用）时会弹窗提示，不会静默失效

## License

见 [LICENSE](LICENSE)。
