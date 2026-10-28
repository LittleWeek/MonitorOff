// monitor-off.zig —— 显示器关闭助手
// 功能：Win+Alt+L 关闭显示器；托盘常驻；设置窗口（快捷键/开机自启/托盘常驻 三开关）
// 编译: zig build-exe monitor-off.zig icon.res -O ReleaseSmall --subsystem windows -lgdi32 -lshell32 -ladvapi32 -ldwmapi
const std = @import("std");

// ================= Win32 常量 =================
const WM_CREATE: u32 = 0x0001;
const WM_DESTROY: u32 = 0x0002;
const WM_CLOSE: u32 = 0x0010;
const WM_PAINT: u32 = 0x000F;
const WM_ERASEBKGND: u32 = 0x0014;
const WM_TIMER: u32 = 0x0113;
const WM_SYSCOMMAND: u32 = 0x0112;
const WM_HOTKEY: u32 = 0x0312;
const WM_KEYDOWN: u32 = 0x0100;
const WM_SYSKEYDOWN: u32 = 0x0104;
const WM_APP: u32 = 0x8000;
const WM_USER: u32 = 0x0400;
const WM_NULL: u32 = 0x0000;
const WM_MOUSEMOVE: u32 = 0x0200;
const WM_LBUTTONUP: u32 = 0x0202;
const WM_RBUTTONUP: u32 = 0x0205;
const WM_MOUSELEAVE: u32 = 0x02A2;
const WM_NCCALCSIZE: u32 = 0x0083;
const WM_NCHITTEST: u32 = 0x0084;
const WM_ACTIVATE: u32 = 0x0006;
const WM_SYSKEYUP: u32 = 0x0105;

const HTCLIENT: isize = 1;
const HTCAPTION: isize = 2;

const CS_DROPSHADOW: u32 = 0x00020000;
const WS_EX_TOPMOST: usize = 0x00000008;
const HWND_TOPMOST: usize = ~@as(usize, 0);
const MONITOR_DEFAULTTONEAREST: u32 = 2;

const WND_STYLE: usize = 0x00CA0000; // CAPTION | SYSMENU | MINIMIZEBOX
const WS_POPUP: usize = 0x80000000;
const WS_EX_TOOLWINDOW: usize = 0x00000080;

const SW_HIDE: i32 = 0;
const SW_SHOWNOACTIVATE: i32 = 4;
const SW_SHOW: i32 = 5;
const SW_MINIMIZE: i32 = 6;
const SW_RESTORE: i32 = 9;

const MOD_ALT: u32 = 0x0001;
const MOD_WIN: u32 = 0x0008;
const MOD_CONTROL: u32 = 0x0002;
const MOD_SHIFT: u32 = 0x0004;
const MOD_NOREPEAT: u32 = 0x4000;
const HK_DEFAULT_MODS: u32 = 0x0009; // Alt | Win
const HK_DEFAULT_VK: u32 = 'L';

const SC_MONITORPOWER: usize = 0xF170;
const HWND_BROADCAST: usize = 0xFFFF;

const NIM_ADD: u32 = 0x0000;
const NIM_DELETE: u32 = 0x0002;
const NIF_MESSAGE: u32 = 0x0001;
const NIF_ICON: u32 = 0x0002;
const NIF_TIP: u32 = 0x0004;

const MB_ICONWARNING: u32 = 0x30;

const IDC_ARROW: usize = 32512;
const IDC_HAND: usize = 32649;
const ICON_RES_ID: usize = 1;

const TME_LEAVE: u32 = 0x0002;
const SWP_NOSIZE: u32 = 0x0001;
const SWP_NOMOVE: u32 = 0x0002;
const SWP_NOZORDER: u32 = 0x0004;

const DT_CENTER: u32 = 0x0001;
const DT_VCENTER: u32 = 0x0004;
const DT_SINGLELINE: u32 = 0x0020;
const DT_CALCRECT: u32 = 0x0400;

const PS_NULL: u32 = 5;
const PS_SOLID: u32 = 0;
const NULL_BRUSH: i32 = 5;
const SRCCOPY: u32 = 0x00CC0020;
const HALFTONE: i32 = 4;
const SS: i32 = 4; // 形状 4x 超采样倍率（抗锯齿）

const ERROR_ALREADY_EXISTS: u32 = 183;
const HKEY_CURRENT_USER: usize = 0x80000001;
const KEY_QUERY_VALUE: u32 = 0x0001;
const KEY_SET_VALUE: u32 = 0x0002;
const REG_SZ: u32 = 1;
const REG_DWORD: u32 = 4;

// ================= 配色（COLORREF 0x00BBGGRR） =================
const C_BG: u32 = 0x00FFFFFF; // #FFFFFF
const C_TEXT: u32 = 0x0037291F; // #1F2937
const C_MUT: u32 = 0x0080726B; // #6B7280
const C_DIV: u32 = 0x00EBE7E5; // #E5E7EB
const C_ACC: u32 = 0x0081B910; // #10B981
const C_ACC_H: u32 = 0x0071A30E; // #0EA371 悬停
const C_SW_OFF: u32 = 0x00DBD5D1; // #D1D5DB
const C_DOT_OFF: u32 = 0x00AFA39C; // #9CA3AF
const C_WHITE: u32 = 0x00FFFFFF;
const C_PILL_BG: u32 = 0x00F6F4F3; // #F3F4F6
const C_PILL_BD: u32 = 0x00EBE7E5; // #E5E7EB
const C_PILL_DIV: u32 = 0x00C1C6CD; // #CDC6C1 → 分隔线（比边框深一档）
const C_PILL_TX: u32 = 0x00514137; // #374151
const C_PILL_ON: u32 = 0x00EEF5E1; // #E1F5EE 录制态底色
const C_ACC_TX: u32 = 0x00566E0F; // #0F6E56 录制态文字
const C_MENU_HOV: u32 = 0x00F6F4F3; // #F3F4F6 菜单项悬停底色
const C_CLOSE_HOV: u32 = 0x00E3E3FA; // #FAE3E3 关闭按钮悬停底色
const C_BTN_HOV: u32 = 0x00F1EEED; // #EDEEF1 最小化按钮悬停底色

// ================= 字符串常量（UTF-16） =================
const CLASS_NAME = std.unicode.utf8ToUtf16LeStringLiteral("MonitorOffWnd");
const MENU_CLASS = std.unicode.utf8ToUtf16LeStringLiteral("MonitorOffMenu");
const WND_TITLE = std.unicode.utf8ToUtf16LeStringLiteral("显示器关闭助手");
const TIP_TEXT = std.unicode.utf8ToUtf16LeStringLiteral("显示器关闭助手 (Win+Alt+L)");
const MUTEX_NAME = std.unicode.utf8ToUtf16LeStringLiteral("Local\\MonitorOffSingleInstance");
const FONT_FACE = std.unicode.utf8ToUtf16LeStringLiteral("Microsoft YaHei UI");

const RUN_KEY = std.unicode.utf8ToUtf16LeStringLiteral("Software\\Microsoft\\Windows\\CurrentVersion\\Run");
const RUN_VALUE = std.unicode.utf8ToUtf16LeStringLiteral("MonitorOff");
const APP_KEY = std.unicode.utf8ToUtf16LeStringLiteral("Software\\MonitorOff");
const HOTKEY_VALUE = std.unicode.utf8ToUtf16LeStringLiteral("HotkeyEnabled");
const TRAY_VALUE = std.unicode.utf8ToUtf16LeStringLiteral("TrayResident");
const HIDE_VALUE = std.unicode.utf8ToUtf16LeStringLiteral("HideTray");
const HK_MODS_VALUE = std.unicode.utf8ToUtf16LeStringLiteral("HotkeyMods");
const HK_VK_VALUE = std.unicode.utf8ToUtf16LeStringLiteral("HotkeyVK");

// ================= 托盘菜单 ID =================
const ID_HOTKEY: i32 = 1;
const TRAY_CB_MSG: u32 = WM_APP + 1;
const WM_SHOW_SETTINGS: u32 = WM_USER + 1;
const WM_MENU_CMD: u32 = WM_USER + 2;

const MENU_OFF: i32 = 200;
const MENU_SETTINGS: i32 = 201;
const MENU_QUIT: i32 = 202;

// ================= 自绘菜单 / 自绘标题栏的尺寸（逻辑像素，走 sc() 缩放） =================
const CHROME_H: i32 = 40; // 标题栏高度（内容整体下移这么多）
const MENU_W: i32 = 152; // 菜单宽度
const MENU_ITEM_H: i32 = 32; // 菜单项高度
const MENU_SEP_H: i32 = 9; // 分隔条高度
const MENU_PAD: i32 = 6; // 菜单上下内边距

const MenuDef = struct { text: [*:0]const u16, cmd: i32, sep: bool };
const MENU_DEFS = [_]MenuDef{
    .{ .text = std.unicode.utf8ToUtf16LeStringLiteral("关闭显示器"), .cmd = MENU_OFF, .sep = false },
    .{ .text = std.unicode.utf8ToUtf16LeStringLiteral(""), .cmd = 0, .sep = true },
    .{ .text = std.unicode.utf8ToUtf16LeStringLiteral("设置…"), .cmd = MENU_SETTINGS, .sep = false },
    .{ .text = std.unicode.utf8ToUtf16LeStringLiteral(""), .cmd = 0, .sep = true },
    .{ .text = std.unicode.utf8ToUtf16LeStringLiteral("退出"), .cmd = MENU_QUIT, .sep = false },
};

// ================= 全局状态 =================
var g_hwnd: usize = 0;
var g_menu_hwnd: usize = 0; // 自绘菜单窗口（按需创建，一直复用）
var g_menu_font: usize = 0;
var g_menu_hover: usize = 0; // 0 无 / 1..5 对应 MENU_DEFS 下标 + 1
var g_menu_tracked: bool = false;
var g_menu_prev_fg: usize = 0; // 弹菜单前的前台窗口，关闭后还给它
var g_mm_mem: usize = 0;
var g_mm_bm: usize = 0;
var g_mm_mem4: usize = 0;
var g_mm_bm4: usize = 0;
var g_mm_w: i32 = 0;
var g_mm_h: i32 = 0;
var g_dpi: i32 = 96;
var g_cw: i32 = 360;
var g_ch: i32 = 252;
var g_font_title: usize = 0;
var g_font_status: usize = 0;
var g_font_btn: usize = 0;
var g_cursor_hand: usize = 0;
var g_hover: u8 = 0; // 0 无 / 1..3 开关 / 4 主按钮
var g_tracked: bool = false;
var g_auto_on: bool = false;
var g_tray_on: bool = true;
var g_hide_tray: bool = false;
var g_hk_mods: u32 = HK_DEFAULT_MODS;
var g_hk_vk: u32 = HK_DEFAULT_VK;
var g_recording: bool = false;
var g_pill: RECT = undefined; // 快捷键胶囊（两种形态：已设置 / 空）
var g_xrect: RECT = undefined; // 胶囊内 × 清除区域
var g_hotkey_text: [64]u16 = undefined;

var rc_sw: [4]RECT = undefined;
var rc_off: RECT = undefined;
var rc_btn_min: RECT = undefined; // 自绘标题栏：最小化
var rc_btn_close: RECT = undefined; // 自绘标题栏：关闭

// ---- 绘制缓存（全局复用，避免每次重绘分配/释放大块位图） ----
var g_mem: usize = 0; // 1x 成品缓存 DC
var g_bm: usize = 0;
var g_mem4: usize = 0; // 4x 超采样 DC
var g_bm4: usize = 0;
var g_buf_w: i32 = 0;
var g_buf_h: i32 = 0;
var g_cache_valid: bool = false;

// ================= 结构体 =================
const POINT = extern struct { x: i32, y: i32 };
const RECT = extern struct { left: i32, top: i32, right: i32, bottom: i32 };
const MSG = extern struct {
    hwnd: usize,
    message: u32,
    wParam: usize,
    lParam: isize,
    time: u32,
    pt: POINT,
};
const PAINTSTRUCT = extern struct {
    hdc: usize,
    fErase: i32,
    rcPaint: RECT,
    fRestore: i32,
    fIncUpdate: i32,
    rgbReserved: [32]u8,
};
const TRACKMOUSEEVENT = extern struct {
    cbSize: u32,
    dwFlags: u32,
    hwndTrack: usize,
    dwHoverTime: u32,
};
const MONITORINFO = extern struct {
    cbSize: u32,
    rcMonitor: RECT,
    rcWork: RECT,
    dwFlags: u32,
};
const WNDCLASSEXW = extern struct {
    cbSize: u32,
    style: u32,
    lpfnWndProc: *const fn (usize, u32, usize, isize) callconv(.c) isize,
    cbClsExtra: i32,
    cbWndExtra: i32,
    hInstance: usize,
    hIcon: usize,
    hCursor: usize,
    hbrBackground: usize,
    lpszMenuName: ?[*:0]const u16,
    lpszClassName: [*:0]const u16,
    hIconSm: usize,
};
const NOTIFYICONDATAW = extern struct {
    cbSize: u32,
    hWnd: usize,
    uID: u32,
    uFlags: u32,
    uCallbackMessage: u32,
    hIcon: usize,
    szTip: [128]u16,
    dwState: u32,
    dwStateMask: u32,
    szInfo: [256]u16,
    uTimeout: u32,
    szInfoTitle: [64]u16,
    dwInfoFlags: u32,
    guidItem: [16]u8,
    hBalloonIcon: usize,
};

// ================= Win32 API =================
extern "kernel32" fn GetModuleHandleW(lpModuleName: ?[*:0]const u16) usize;
extern "kernel32" fn GetModuleFileNameW(hModule: usize, lpFilename: [*]u16, nSize: u32) u32;
extern "kernel32" fn GetCommandLineW() [*]u16;
extern "kernel32" fn CreateMutexW(lpAttr: ?*anyopaque, bInitialOwner: i32, lpName: [*:0]const u16) usize;
extern "kernel32" fn GetLastError() u32;
extern "kernel32" fn Sleep(ms: u32) void;
extern "kernel32" fn MulDiv(a: i32, b: i32, c: i32) i32;
extern "kernel32" fn GetCurrentProcess() usize;
extern "kernel32" fn GetCurrentThreadId() u32;
extern "kernel32" fn SetProcessWorkingSetSize(hProcess: usize, min: isize, max: isize) i32;

extern "user32" fn RegisterClassExW(*const WNDCLASSEXW) u16;
extern "user32" fn CreateWindowExW(dwExStyle: usize, lpClassName: [*:0]const u16, lpWindowName: [*:0]const u16, dwStyle: usize, x: i32, y: i32, w: i32, h: i32, hWndParent: usize, hMenu: usize, hInstance: usize, lpParam: ?*anyopaque) usize;
extern "user32" fn DefWindowProcW(hwnd: usize, msg: u32, wp: usize, lp: isize) isize;
extern "user32" fn GetMessageW(*MSG, hwnd: usize, min: u32, max: u32) i32;
extern "user32" fn TranslateMessage(*MSG) i32;
extern "user32" fn DispatchMessageW(*MSG) isize;
extern "user32" fn PostQuitMessage(nExitCode: i32) void;
extern "user32" fn ShowWindow(hwnd: usize, nCmdShow: i32) i32;
extern "user32" fn SetForegroundWindow(hwnd: usize) i32;
extern "user32" fn GetForegroundWindow() usize;
extern "user32" fn GetWindowThreadProcessId(hwnd: usize, pid: ?*u32) u32;
extern "user32" fn AttachThreadInput(idAttach: u32, idAttachTo: u32, attach: i32) i32;
extern "user32" fn BringWindowToTop(hwnd: usize) i32;
extern "user32" fn SetActiveWindow(hwnd: usize) usize;
extern "user32" fn SetFocus(hwnd: usize) usize;
extern "user32" fn IsIconic(hwnd: usize) i32;
extern "user32" fn DestroyWindow(hwnd: usize) i32;
extern "user32" fn PostMessageW(hwnd: usize, msg: u32, wp: usize, lp: isize) i32;
extern "user32" fn SendMessageW(hwnd: usize, msg: u32, wp: usize, lp: isize) isize;
extern "user32" fn RegisterHotKey(hwnd: usize, id: i32, modifiers: u32, vk: u32) i32;
extern "user32" fn UnregisterHotKey(hwnd: usize, id: i32) i32;
extern "user32" fn LoadCursorW(hInstance: usize, lpCursorName: usize) usize;
extern "user32" fn LoadIconW(hInstance: usize, lpIconName: usize) usize;
extern "user32" fn MessageBoxW(hwnd: usize, text: [*:0]const u16, caption: [*:0]const u16, utype: u32) i32;
extern "user32" fn MonitorFromPoint(pt: POINT, flags: u32) usize;
extern "user32" fn GetMonitorInfoW(hMonitor: usize, lpmi: *MONITORINFO) i32;
extern "user32" fn ScreenToClient(hwnd: usize, pt: *POINT) i32;
extern "user32" fn GetCursorPos(*POINT) i32;
extern "user32" fn AdjustWindowRectEx(*RECT, style: usize, menu: i32, exStyle: usize) i32;
extern "user32" fn FindWindowW(lpClassName: [*:0]const u16, lpWindowName: ?[*:0]const u16) usize;
extern "user32" fn BeginPaint(hwnd: usize, *PAINTSTRUCT) usize;
extern "user32" fn EndPaint(hwnd: usize, *PAINTSTRUCT) i32;
extern "user32" fn GetClientRect(hwnd: usize, *RECT) i32;
extern "user32" fn FillRect(hdc: usize, *const RECT, hBrush: usize) i32;
extern "user32" fn InvalidateRect(hwnd: usize, lpRect: ?*const RECT, bErase: i32) i32;
extern "user32" fn ValidateRect(hwnd: usize, lpRect: ?*const RECT) i32;
extern "user32" fn DrawTextW(hdc: usize, text: [*:0]const u16, count: i32, *RECT, flags: u32) i32;
extern "user32" fn SetTextColor(hdc: usize, color: u32) u32;
extern "user32" fn SetBkMode(hdc: usize, mode: i32) i32;
extern "user32" fn SetCursor(hCursor: usize) usize;
extern "user32" fn TrackMouseEvent(*TRACKMOUSEEVENT) i32;
extern "user32" fn GetDpiForWindow(hwnd: usize) u32;
extern "user32" fn SetProcessDPIAware() i32;
extern "user32" fn SetWindowPos(hwnd: usize, after: usize, x: i32, y: i32, cx: i32, cy: i32, flags: u32) i32;
extern "user32" fn SetWindowRgn(hwnd: usize, hRgn: usize, bRedraw: i32) i32;
extern "user32" fn IsWindowVisible(hwnd: usize) i32;
extern "user32" fn SetTimer(hwnd: usize, id: usize, elapse: u32, proc: ?*const anyopaque) usize;
extern "user32" fn GetKeyState(vk: i32) i16;

extern "shell32" fn Shell_NotifyIconW(dwMessage: u32, lpData: *NOTIFYICONDATAW) i32;

extern "gdi32" fn CreateCompatibleDC(hdc: usize) usize;
extern "gdi32" fn CreateCompatibleBitmap(hdc: usize, w: i32, h: i32) usize;
extern "gdi32" fn SelectObject(hdc: usize, obj: usize) usize;
extern "gdi32" fn GetPixel(hdc: usize, x: i32, y: i32) u32;
extern "gdi32" fn SetPixel(hdc: usize, x: i32, y: i32, color: u32) u32;
extern "gdi32" fn DeleteObject(obj: usize) i32;
extern "gdi32" fn DeleteDC(hdc: usize) i32;
extern "gdi32" fn CreateSolidBrush(color: u32) usize;
extern "gdi32" fn CreateRoundRectRgn(x1: i32, y1: i32, x2: i32, y2: i32, w: i32, h: i32) usize;
extern "gdi32" fn CreatePen(style: u32, width: i32, color: u32) usize;
extern "gdi32" fn RoundRect(hdc: usize, l: i32, t: i32, r: i32, b: i32, w: i32, h: i32) i32;
extern "gdi32" fn Ellipse(hdc: usize, l: i32, t: i32, r: i32, b: i32) i32;
extern "gdi32" fn CreateFontW(height: i32, width: i32, escapement: i32, orientation: i32, weight: i32, italic: u32, underline: u32, strikeout: u32, charset: u32, outPrec: u32, clipPrec: u32, quality: u32, pitchFamily: u32, face: [*:0]const u16) usize;
extern "gdi32" fn BitBlt(hdcDst: usize, x: i32, y: i32, w: i32, h: i32, hdcSrc: usize, x2: i32, y2: i32, rop: u32) i32;
extern "gdi32" fn StretchBlt(hdcDst: usize, x: i32, y: i32, w: i32, h: i32, hdcSrc: usize, x2: i32, y2: i32, w2: i32, h2: i32, rop: u32) i32;
extern "gdi32" fn SetStretchBltMode(hdc: usize, mode: i32) i32;
extern "gdi32" fn GetStockObject(i: i32) usize;
extern "gdi32" fn MoveToEx(hdc: usize, x: i32, y: i32, old: ?*POINT) i32;
extern "gdi32" fn LineTo(hdc: usize, x: i32, y: i32) i32;
extern "gdi32" fn Polygon(hdc: usize, pt: [*]const POINT, n: i32) i32;
extern "gdi32" fn Polyline(hdc: usize, pt: [*]const POINT, n: i32) i32;
extern "gdi32" fn Arc(hdc: usize, l: i32, t: i32, r: i32, b: i32, x1: i32, y1: i32, x2: i32, y2: i32) i32;

extern "dwmapi" fn DwmSetWindowAttribute(hwnd: usize, attr: u32, value: *const u32, size: u32) i32;

extern "advapi32" fn RegOpenKeyExW(hKey: usize, lpSubKey: [*:0]const u16, ulOptions: u32, samDesired: u32, phkResult: *usize) i32;
extern "advapi32" fn RegCreateKeyExW(hKey: usize, lpSubKey: [*:0]const u16, reserved: u32, lpClass: ?[*:0]const u16, dwOptions: u32, samDesired: u32, lpSecAttr: ?*anyopaque, phkResult: *usize, lpdwDisposition: ?*u32) i32;
extern "advapi32" fn RegSetValueExW(hKey: usize, lpValueName: [*:0]const u16, reserved: u32, dwType: u32, lpData: ?*const anyopaque, cbData: u32) i32;
extern "advapi32" fn RegQueryValueExW(hKey: usize, lpValueName: [*:0]const u16, lpReserved: ?*u32, lpType: ?*u32, lpData: ?*anyopaque, lpcbData: ?*u32) i32;
extern "advapi32" fn RegDeleteValueW(hKey: usize, lpValueName: [*:0]const u16) i32;
extern "advapi32" fn RegCloseKey(hKey: usize) i32;

// ================= 工具 =================
// comptime UTF-8 → UTF-16 字面量转换
fn utf16(comptime s: []const u8) [*:0]const u16 {
    @setEvalBranchQuota(100000);
    return std.unicode.utf8ToUtf16LeStringLiteral(s);
}

fn sc(v: i32) i32 {
    return @divTrunc(v * g_dpi, 96);
}

fn inRect(r: RECT, x: i32, y: i32) bool {
    return x >= r.left and x < r.right and y >= r.top and y < r.bottom;
}

// ================= 核心功能：关闭显示器 =================
fn monitorOff() void {
    Sleep(300); // 等待按键/鼠标松开，避免刚关屏就被输入唤醒
    _ = SendMessageW(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, 2);
}

// ================= 注册表：开机自启 =================
fn isAutoRun() bool {
    var hk: usize = 0;
    if (RegOpenKeyExW(HKEY_CURRENT_USER, RUN_KEY, 0, KEY_QUERY_VALUE, &hk) != 0) return false;
    defer _ = RegCloseKey(hk);
    return RegQueryValueExW(hk, RUN_VALUE, null, null, null, null) == 0;
}

fn setAutoRun(enable: bool) bool {
    var hk: usize = 0;
    if (RegCreateKeyExW(HKEY_CURRENT_USER, RUN_KEY, 0, null, 0, KEY_SET_VALUE, null, &hk, null) != 0) return false;
    defer _ = RegCloseKey(hk);
    if (!enable) {
        const st = RegDeleteValueW(hk, RUN_VALUE);
        return st == 0 or st == 2; // 2 = 值本来就不存在，视为成功
    }
    var path: [300]u16 = undefined;
    const n = GetModuleFileNameW(0, &path, @intCast(path.len));
    if (n == 0 or n >= path.len) return false;
    var data: [320]u16 = undefined;
    data[0] = '"';
    @memcpy(data[1 .. 1 + n], path[0..n]);
    data[1 + n] = '"';
    const suffix = std.unicode.utf8ToUtf16LeStringLiteral(" /tray");
    @memcpy(data[2 + n .. 2 + n + suffix.len], suffix);
    const total = 2 + n + suffix.len;
    data[total] = 0;
    return RegSetValueExW(hk, RUN_VALUE, 0, REG_SZ, @ptrCast(&data), @intCast((total + 1) * 2)) == 0;
}

// ================= 注册表：应用开关（快捷键/托盘常驻） =================
fn readAppU32(comptime name: [*:0]const u16, default: u32) u32 {
    var hk: usize = 0;
    if (RegOpenKeyExW(HKEY_CURRENT_USER, APP_KEY, 0, KEY_QUERY_VALUE, &hk) != 0) return default;
    defer _ = RegCloseKey(hk);
    var v: u32 = default;
    var size: u32 = 4;
    if (RegQueryValueExW(hk, name, null, null, @ptrCast(&v), &size) != 0) return default;
    return v;
}

fn readAppBool(comptime name: [*:0]const u16, default: bool) bool {
    return readAppU32(name, if (default) 1 else 0) != 0;
}

fn writeAppBool(comptime name: [*:0]const u16, enable: bool) void {
    var hk: usize = 0;
    if (RegCreateKeyExW(HKEY_CURRENT_USER, APP_KEY, 0, null, 0, KEY_SET_VALUE, null, &hk, null) != 0) return;
    defer _ = RegCloseKey(hk);
    var v: u32 = if (enable) 1 else 0;
    _ = RegSetValueExW(hk, name, 0, REG_DWORD, @ptrCast(&v), 4);
}

fn readHotkeyCfg() void {
    g_hk_mods = readAppU32(HK_MODS_VALUE, HK_DEFAULT_MODS);
    g_hk_vk = readAppU32(HK_VK_VALUE, HK_DEFAULT_VK);
}

fn writeHotkeyCfg() void {
    var hk: usize = 0;
    if (RegCreateKeyExW(HKEY_CURRENT_USER, APP_KEY, 0, null, 0, KEY_SET_VALUE, null, &hk, null) != 0) return;
    defer _ = RegCloseKey(hk);
    _ = RegSetValueExW(hk, HK_MODS_VALUE, 0, REG_DWORD, @ptrCast(&g_hk_mods), 4);
    _ = RegSetValueExW(hk, HK_VK_VALUE, 0, REG_DWORD, @ptrCast(&g_hk_vk), 4);
}

fn hotkeySet() bool {
    return g_hk_vk != 0; // vk 为 0 = 未设置快捷键
}

fn trayResident() bool {
    return readAppBool(TRAY_VALUE, true);
}

fn hideTrayEnabled() bool {
    return readAppBool(HIDE_VALUE, false);
}

// ================= 快捷键注册 =================
fn applyHotkey(hwnd: usize) bool {
    if (hotkeySet()) {
        _ = UnregisterHotKey(hwnd, ID_HOTKEY);
        return RegisterHotKey(hwnd, ID_HOTKEY, g_hk_mods | MOD_NOREPEAT, g_hk_vk) != 0;
    }
    _ = UnregisterHotKey(hwnd, ID_HOTKEY);
    return true;
}

// ================= 快捷键文本 =================
fn putS(out: []u16, s: []const u16) usize {
    @memcpy(out[0..s.len], s);
    return s.len;
}

fn putNum(out: []u16, v: u32) usize {
    if (v == 0) {
        out[0] = '0';
        return 1;
    }
    var tmp: [12]u16 = undefined;
    var n: usize = 0;
    var x = v;
    while (x > 0) : (x /= 10) {
        tmp[n] = '0' + @as(u16, @intCast(x % 10));
        n += 1;
    }
    var i: usize = 0;
    while (i < n) : (i += 1) out[i] = tmp[n - 1 - i];
    return n;
}

const S_SPACE = std.unicode.utf8ToUtf16LeStringLiteral("Space");
const S_TAB = std.unicode.utf8ToUtf16LeStringLiteral("Tab");
const S_ENTER = std.unicode.utf8ToUtf16LeStringLiteral("Enter");
const S_BACK = std.unicode.utf8ToUtf16LeStringLiteral("Back");
const S_PGUP = std.unicode.utf8ToUtf16LeStringLiteral("PgUp");
const S_PGDN = std.unicode.utf8ToUtf16LeStringLiteral("PgDn");
const S_HOME = std.unicode.utf8ToUtf16LeStringLiteral("Home");
const S_END = std.unicode.utf8ToUtf16LeStringLiteral("End");
const S_INS = std.unicode.utf8ToUtf16LeStringLiteral("Ins");
const S_DEL = std.unicode.utf8ToUtf16LeStringLiteral("Del");
const S_PRTSC = std.unicode.utf8ToUtf16LeStringLiteral("PrtSc");
const S_LEFT = std.unicode.utf8ToUtf16LeStringLiteral("←");
const S_UP = std.unicode.utf8ToUtf16LeStringLiteral("↑");
const S_RIGHT = std.unicode.utf8ToUtf16LeStringLiteral("→");
const S_DOWN = std.unicode.utf8ToUtf16LeStringLiteral("↓");

fn vkName(vk: u32, out: []u16) usize {
    if (vk >= 'A' and vk <= 'Z') {
        out[0] = @intCast(vk);
        return 1;
    }
    if (vk >= '0' and vk <= '9') {
        out[0] = @intCast(vk);
        return 1;
    }
    if (vk >= 0x70 and vk <= 0x87) { // F1 ~ F24
        out[0] = 'F';
        return 1 + putNum(out[1..], vk - 0x70 + 1);
    }
    switch (vk) {
        0x08 => return putS(out, S_BACK),
        0x09 => return putS(out, S_TAB),
        0x0D => return putS(out, S_ENTER),
        0x20 => return putS(out, S_SPACE),
        0x21 => return putS(out, S_PGUP),
        0x22 => return putS(out, S_PGDN),
        0x23 => return putS(out, S_END),
        0x24 => return putS(out, S_HOME),
        0x25 => return putS(out, S_LEFT),
        0x26 => return putS(out, S_UP),
        0x27 => return putS(out, S_RIGHT),
        0x28 => return putS(out, S_DOWN),
        0x2C => return putS(out, S_PRTSC),
        0x2D => return putS(out, S_INS),
        0x2E => return putS(out, S_DEL),
        else => {},
    }
    const hexd = "0123456789ABCDEF";
    out[0] = '0';
    out[1] = 'x';
    out[2] = @as(u16, hexd[(vk >> 4) & 0xF]);
    out[3] = @as(u16, hexd[vk & 0xF]);
    return 4;
}

fn buildHotkeyText() void {
    var pos: usize = 0;
    if (g_hk_mods & MOD_CONTROL != 0) {
        pos += putS(g_hotkey_text[pos..], utf16("Ctrl + ")[0..7]);
    }
    if (g_hk_mods & MOD_SHIFT != 0) {
        pos += putS(g_hotkey_text[pos..], utf16("Shift + ")[0..8]);
    }
    if (g_hk_mods & MOD_ALT != 0) {
        pos += putS(g_hotkey_text[pos..], utf16("Alt + ")[0..6]);
    }
    if (g_hk_mods & MOD_WIN != 0) {
        pos += putS(g_hotkey_text[pos..], utf16("Win + ")[0..6]);
    }
    pos += vkName(g_hk_vk, g_hotkey_text[pos..]);
    g_hotkey_text[pos] = 0;
}

// ================= 快捷键录制 =================
fn handleRecKey(hwnd: usize, vk: u32) void {
    if (vk == 0x1B) { // Esc 取消（保持未设置）
        g_recording = false;
        invalidateRow(hwnd, 0);
        return;
    }
    // 纯修饰键按下时不做处理，等待主键
    if (vk == 0x10 or vk == 0x11 or vk == 0x12 or vk == 0x5B or vk == 0x5C or (vk >= 0xA0 and vk <= 0xA5)) return;
    var mods: u32 = 0;
    if (@as(u16, @bitCast(GetKeyState(0x11))) & 0x8000 != 0) mods |= MOD_CONTROL;
    if (@as(u16, @bitCast(GetKeyState(0x10))) & 0x8000 != 0) mods |= MOD_SHIFT;
    if (@as(u16, @bitCast(GetKeyState(0x12))) & 0x8000 != 0) mods |= MOD_ALT;
    if (@as(u16, @bitCast(GetKeyState(0x5B) | GetKeyState(0x5C))) & 0x8000 != 0) mods |= MOD_WIN;
    // 必须包含 Ctrl/Alt/Win 之一，避免误录普通按键
    if (mods & (MOD_CONTROL | MOD_ALT | MOD_WIN) == 0) return;
    if (RegisterHotKey(hwnd, ID_HOTKEY, mods | MOD_NOREPEAT, vk) != 0) {
        g_hk_mods = mods;
        g_hk_vk = vk;
        writeHotkeyCfg();
        buildHotkeyText();
        g_recording = false;
    } else {
        g_recording = false;
        _ = MessageBoxW(hwnd, utf16("快捷键注册失败，可能被其他程序占用。"), WND_TITLE, MB_ICONWARNING);
    }
    invalidateRow(hwnd, 0);
}

// ================= 托盘 =================
// ================= 自绘托盘菜单 =================
// 不用 TrackPopupMenu：菜单是程序自己的 WS_POPUP 工具窗口（不进任务栏、不进 Alt+Tab），
// 画什么、放哪、点哪全自己控制。它激活时用户只会看到这个菜单本身，
// 主窗口从不参与，所以不存在"右键把设置窗口顶到前台"的问题。
fn menuHeight() i32 {
    var h: i32 = 0;
    for (MENU_DEFS) |d| h += if (d.sep) sc(MENU_SEP_H) else sc(MENU_ITEM_H);
    return h + sc(MENU_PAD) * 2;
}

fn menuSlotRect(i: usize) RECT {
    var y: i32 = sc(MENU_PAD);
    var k: usize = 0;
    while (k < i) : (k += 1) y += if (MENU_DEFS[k].sep) sc(MENU_SEP_H) else sc(MENU_ITEM_H);
    const hh = if (MENU_DEFS[i].sep) sc(MENU_SEP_H) else sc(MENU_ITEM_H);
    return RECT{ .left = 0, .top = y, .right = sc(MENU_W), .bottom = y + hh };
}

// 返回点中的菜单命令 ID，未命中返回 0
fn menuHit(x: i32, y: i32) i32 {
    var i: usize = 0;
    while (i < MENU_DEFS.len) : (i += 1) {
        if (MENU_DEFS[i].sep) continue;
        if (inRect(menuSlotRect(i), x, y)) return MENU_DEFS[i].cmd;
    }
    return 0;
}

// 返回悬停项编号（1 起，对应 MENU_DEFS 下标 + 1），未命中返回 0
fn menuHoverIndex(x: i32, y: i32) usize {
    var i: usize = 0;
    while (i < MENU_DEFS.len) : (i += 1) {
        if (MENU_DEFS[i].sep) continue;
        if (inRect(menuSlotRect(i), x, y)) return i + 1;
    }
    return 0;
}

// 键盘上下移动时跳过分隔条
fn menuMoveHover(delta: i32) void {
    var idx: i32 = @intCast(g_menu_hover);
    const n: i32 = @intCast(MENU_DEFS.len);
    var k: i32 = 0;
    while (k < n) : (k += 1) {
        idx += delta;
        if (idx < 1) idx = n;
        if (idx > n) idx = 1;
        if (!MENU_DEFS[@intCast(idx - 1)].sep) {
            g_menu_hover = @intCast(idx);
            return;
        }
    }
}

fn freeMenuBuffers() void {
    if (g_mm_mem != 0) { _ = DeleteDC(g_mm_mem); g_mm_mem = 0; }
    if (g_mm_bm != 0) { _ = DeleteObject(g_mm_bm); g_mm_bm = 0; }
    if (g_mm_mem4 != 0) { _ = DeleteDC(g_mm_mem4); g_mm_mem4 = 0; }
    if (g_mm_bm4 != 0) { _ = DeleteObject(g_mm_bm4); g_mm_bm4 = 0; }
    g_mm_w = 0;
    g_mm_h = 0;
}

fn menuPaint(hwnd: usize) void {
    var ps: PAINTSTRUCT = undefined;
    const hdc = BeginPaint(hwnd, &ps);
    defer _ = EndPaint(hwnd, &ps);

    var rc: RECT = undefined;
    _ = GetClientRect(hwnd, &rc);
    const cw = rc.right;
    const ch = rc.bottom;
    if (cw <= 0 or ch <= 0) return;

    if (g_mm_mem == 0 or g_mm_w != cw or g_mm_h != ch) {
        freeMenuBuffers();
        g_mm_mem = CreateCompatibleDC(hdc);
        g_mm_bm = CreateCompatibleBitmap(hdc, cw, ch);
        _ = SelectObject(g_mm_mem, g_mm_bm);
        g_mm_mem4 = CreateCompatibleDC(hdc);
        g_mm_bm4 = CreateCompatibleBitmap(hdc, cw * SS, ch * SS);
        _ = SelectObject(g_mm_mem4, g_mm_bm4);
        _ = SetStretchBltMode(g_mm_mem, HALFTONE);
        g_mm_w = cw;
        g_mm_h = ch;
    }

    // 4x 超采样画形状：白底 + 1px 圆角描边 + 悬停底色 + 分隔线
    fillRectColor(g_mm_mem4, 0, 0, cw * SS, ch * SS, C_BG);
    const radius = sc(10);
    roundFill(g_mm_mem4, 0, 0, cw * SS, ch * SS, radius * SS, C_DIV);
    roundFill(g_mm_mem4, SS, SS, cw * SS - SS, ch * SS - SS, (radius - 1) * SS, C_BG);

    if (g_menu_hover > 0 and g_menu_hover <= MENU_DEFS.len) {
        const r = menuSlotRect(g_menu_hover - 1);
        roundFill(g_mm_mem4, sc(4) * SS, r.top * SS, (cw - sc(4)) * SS, r.bottom * SS, sc(6) * SS, C_MENU_HOV);
    }
    var i: usize = 0;
    while (i < MENU_DEFS.len) : (i += 1) {
        if (!MENU_DEFS[i].sep) continue;
        const r = menuSlotRect(i);
        const y = @divTrunc(r.top + r.bottom, 2) * SS;
        fillRectColor(g_mm_mem4, sc(10) * SS, y, (cw - sc(10)) * SS, y + SS, C_DIV);
    }

    _ = StretchBlt(g_mm_mem, 0, 0, cw, ch, g_mm_mem4, 0, 0, cw * SS, ch * SS, SRCCOPY);

    // 文字单独按原始尺寸绘制，保持 ClearType 锐利
    i = 0;
    while (i < MENU_DEFS.len) : (i += 1) {
        if (MENU_DEFS[i].sep) continue;
        const r = menuSlotRect(i);
        drawTextW16(g_mm_mem, MENU_DEFS[i].text, sc(16), r.top, cw - sc(24), r.bottom - r.top, C_TEXT, g_menu_font, 0);
    }

    _ = BitBlt(hdc, ps.rcPaint.left, ps.rcPaint.top, ps.rcPaint.right - ps.rcPaint.left, ps.rcPaint.bottom - ps.rcPaint.top, g_mm_mem, ps.rcPaint.left, ps.rcPaint.top, SRCCOPY);
}

fn hideTrayMenu() void {
    if (g_menu_hwnd == 0) return;
    if (IsWindowVisible(g_menu_hwnd) == 0) return;
    _ = ShowWindow(g_menu_hwnd, SW_HIDE);
    freeMenuBuffers(); // 菜单不常开，缓冲用完就还回去
    // 前台还给原来的窗口（比如刚才正在用的浏览器）
    if (g_menu_prev_fg != 0 and GetForegroundWindow() == g_menu_hwnd) {
        _ = SetForegroundWindow(g_menu_prev_fg);
    }
}

fn menuWndProc(hwnd: usize, msg: u32, wp: usize, lp: isize) callconv(.c) isize {
    switch (msg) {
        WM_CREATE => {
            g_menu_font = makeFont(10, 400);
            return 0;
        },
        WM_ERASEBKGND => return 1,
        WM_PAINT => {
            menuPaint(hwnd);
            return 0;
        },
        WM_MOUSEMOVE => {
            const x: i32 = @as(i16, @truncate(lp & 0xFFFF));
            const y: i32 = @as(i16, @truncate((lp >> 16) & 0xFFFF));
            const hv = menuHoverIndex(x, y);
            if (hv != g_menu_hover) {
                g_menu_hover = hv;
                _ = InvalidateRect(hwnd, null, 0);
            }
            _ = SetCursor(if (hv != 0) g_cursor_hand else LoadCursorW(0, IDC_ARROW));
            if (!g_menu_tracked) {
                g_menu_tracked = true;
                var tme = TRACKMOUSEEVENT{ .cbSize = @sizeOf(TRACKMOUSEEVENT), .dwFlags = TME_LEAVE, .hwndTrack = hwnd, .dwHoverTime = 0 };
                _ = TrackMouseEvent(&tme);
            }
            return 0;
        },
        WM_MOUSELEAVE => {
            g_menu_tracked = false;
            if (g_menu_hover != 0) {
                g_menu_hover = 0;
                _ = InvalidateRect(hwnd, null, 0);
            }
            return 0;
        },
        WM_LBUTTONUP => {
            const x: i32 = @as(i16, @truncate(lp & 0xFFFF));
            const y: i32 = @as(i16, @truncate((lp >> 16) & 0xFFFF));
            const cmd = menuHit(x, y);
            hideTrayMenu();
            if (cmd != 0) _ = PostMessageW(g_hwnd, WM_MENU_CMD, @intCast(cmd), 0);
            return 0;
        },
        WM_KEYDOWN => {
            switch (wp) {
                0x1B => { // Esc
                    hideTrayMenu();
                    return 0;
                },
                0x26 => { // ↑
                    menuMoveHover(-1);
                    _ = InvalidateRect(hwnd, null, 0);
                    return 0;
                },
                0x28 => { // ↓
                    menuMoveHover(1);
                    _ = InvalidateRect(hwnd, null, 0);
                    return 0;
                },
                0x0D => { // Enter
                    var i: usize = 0;
                    while (i < MENU_DEFS.len) : (i += 1) {
                        if (g_menu_hover == i + 1 and !MENU_DEFS[i].sep) {
                            const cmd = MENU_DEFS[i].cmd;
                            hideTrayMenu();
                            _ = PostMessageW(g_hwnd, WM_MENU_CMD, @intCast(cmd), 0);
                            return 0;
                        }
                    }
                    return 0;
                },
                else => {},
            }
        },
        WM_ACTIVATE => {
            if ((wp & 0xFFFF) == 0) hideTrayMenu(); // WA_INACTIVE：点到菜单外面了
            return 0;
        },
        WM_DESTROY => {
            freeMenuBuffers();
            if (g_menu_font != 0) { _ = DeleteObject(g_menu_font); g_menu_font = 0; }
            g_menu_hwnd = 0;
            return 0;
        },
        else => {},
    }
    return DefWindowProcW(hwnd, msg, wp, lp);
}

fn ensureMenuWindow() usize {
    if (g_menu_hwnd != 0) return g_menu_hwnd;
    const hInst = GetModuleHandleW(null);
    const wc = WNDCLASSEXW{
        .cbSize = @sizeOf(WNDCLASSEXW),
        .style = CS_DROPSHADOW, // 弹窗阴影
        .lpfnWndProc = menuWndProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = hInst,
        .hIcon = 0,
        .hCursor = LoadCursorW(0, IDC_ARROW),
        .hbrBackground = 0,
        .lpszMenuName = null,
        .lpszClassName = MENU_CLASS,
        .hIconSm = 0,
    };
    _ = RegisterClassExW(&wc);
    g_menu_hwnd = CreateWindowExW(WS_EX_TOOLWINDOW | WS_EX_TOPMOST, MENU_CLASS, MENU_CLASS, WS_POPUP, 0, 0, sc(MENU_W), menuHeight(), 0, 0, hInst, null);
    return g_menu_hwnd;
}

// 在鼠标位置弹出菜单：默认向上展开（光标落在菜单右下角），越界时自动翻转/贴边
fn showTrayMenu() void {
    const m = ensureMenuWindow();
    if (m == 0) return;

    const w = sc(MENU_W);
    const h = menuHeight();
    var pt: POINT = undefined;
    _ = GetCursorPos(&pt);

    var work = RECT{ .left = 0, .top = 0, .right = 0, .bottom = 0 };
    var mi = std.mem.zeroes(MONITORINFO);
    mi.cbSize = @sizeOf(MONITORINFO);
    const mon = MonitorFromPoint(pt, MONITOR_DEFAULTTONEAREST);
    if (mon != 0 and GetMonitorInfoW(mon, &mi) != 0) {
        work = mi.rcWork;
    } else {
        work = RECT{ .left = 0, .top = 0, .right = pt.x + w, .bottom = pt.y };
    }

    var x = pt.x;
    var y = pt.y - h;
    if (y < work.top) y = pt.y; // 上方放不下 → 改向下展开
    if (y + h > work.bottom) y = work.bottom - h;
    if (x + w > work.right) x = work.right - w;
    if (x < work.left) x = work.left;

    g_menu_prev_fg = GetForegroundWindow();
    g_menu_hover = 0;
    g_menu_tracked = false;
    _ = SetWindowPos(m, HWND_TOPMOST, x, y, w, h, 0x0040); // SWP_SHOWWINDOW
    // 圆角窗口区域：让系统裁掉四角（否则深色桌面下会看到白色直角）
    const rgn = CreateRoundRectRgn(0, 0, w + 1, h + 1, sc(10) * 2, sc(10) * 2);
    if (rgn != 0) _ = SetWindowRgn(m, rgn, 1);
    forceForeground(m);
    _ = SetFocus(m);
    _ = InvalidateRect(m, null, 1);
}


// 抢前台：本进程在后台时 SetForegroundWindow 会被 Windows 的前台锁直接拒绝（只闪任务栏），
// 所以先把本线程输入队列临时附加到当前前台窗口线程，借它的权限置前，设完立即解除。
fn forceForeground(hwnd: usize) void {
    const fg = GetForegroundWindow();
    const my_tid = GetCurrentThreadId();
    if (fg != 0 and fg != hwnd) {
        const fg_tid = GetWindowThreadProcessId(fg, null);
        if (fg_tid != 0 and fg_tid != my_tid) {
            _ = AttachThreadInput(my_tid, fg_tid, 1);
            _ = SetForegroundWindow(hwnd);
            _ = AttachThreadInput(my_tid, fg_tid, 0);
            return;
        }
    }
    _ = SetForegroundWindow(hwnd);
}

fn addTrayIcon(hwnd: usize) void {
    var nid = std.mem.zeroes(NOTIFYICONDATAW);
    nid.cbSize = @sizeOf(NOTIFYICONDATAW);
    nid.hWnd = hwnd;
    nid.uID = 1;
    nid.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP;
    nid.uCallbackMessage = TRAY_CB_MSG;
    nid.hIcon = LoadIconW(GetModuleHandleW(null), ICON_RES_ID);
    @memcpy(nid.szTip[0..TIP_TEXT.len], TIP_TEXT);
    _ = Shell_NotifyIconW(NIM_ADD, &nid);
}

fn removeTrayIcon(hwnd: usize) void {
    var nid = std.mem.zeroes(NOTIFYICONDATAW);
    nid.cbSize = @sizeOf(NOTIFYICONDATAW);
    nid.hWnd = hwnd;
    nid.uID = 1;
    _ = Shell_NotifyIconW(NIM_DELETE, &nid);
}

// 唤醒设置窗口并抢到前台。
fn showSettings(hwnd: usize) void {
    if (IsIconic(hwnd) != 0) {
        _ = ShowWindow(hwnd, SW_RESTORE); // 最小化时 SW_SHOW 不会还原
    } else {
        _ = ShowWindow(hwnd, SW_SHOW);
    }
    forceForeground(hwnd);
    _ = BringWindowToTop(hwnd);
    _ = SetActiveWindow(hwnd);
    _ = SetFocus(hwnd);
}

// ================= 自绘 UI =================
fn makeFont(pt: i32, weight: i32) usize {
    return CreateFontW(-MulDiv(pt, g_dpi, 72), 0, 0, 0, weight, 0, 0, 0, 1, 0, 0, 5, 0, FONT_FACE);
}

fn roundFill(hdc: usize, l: i32, t: i32, r: i32, b: i32, radius: i32, color: u32) void {
    const brush = CreateSolidBrush(color);
    const pen = CreatePen(PS_NULL, 0, color);
    const ob = SelectObject(hdc, brush);
    const op = SelectObject(hdc, pen);
    _ = RoundRect(hdc, l, t, r, b, radius * 2, radius * 2);
    _ = SelectObject(hdc, ob);
    _ = SelectObject(hdc, op);
    _ = DeleteObject(brush);
    _ = DeleteObject(pen);
}

fn ellipseFill(hdc: usize, l: i32, t: i32, r: i32, b: i32, color: u32) void {
    const brush = CreateSolidBrush(color);
    const pen = CreatePen(PS_NULL, 0, color);
    const ob = SelectObject(hdc, brush);
    const op = SelectObject(hdc, pen);
    _ = Ellipse(hdc, l, t, r, b);
    _ = SelectObject(hdc, ob);
    _ = SelectObject(hdc, op);
    _ = DeleteObject(brush);
    _ = DeleteObject(pen);
}

fn fillRectColor(hdc: usize, l: i32, t: i32, r: i32, b: i32, color: u32) void {
    const brush = CreateSolidBrush(color);
    const rc = RECT{ .left = l, .top = t, .right = r, .bottom = b };
    _ = FillRect(hdc, &rc, brush);
    _ = DeleteObject(brush);
}

fn drawTextW16(hdc: usize, text: [*:0]const u16, x: i32, y: i32, w: i32, h: i32, color: u32, font: usize, flags: u32) void {
    var rc = RECT{ .left = x, .top = y, .right = x + w, .bottom = y + h };
    _ = SelectObject(hdc, font);
    _ = SetTextColor(hdc, color);
    _ = SetBkMode(hdc, 1);
    _ = DrawTextW(hdc, text, -1, &rc, flags | DT_SINGLELINE | DT_VCENTER);
}

fn drawText(hdc: usize, comptime s: []const u8, x: i32, y: i32, w: i32, h: i32, color: u32, font: usize, flags: u32) void {
    drawTextW16(hdc, utf16(s), x, y, w, h, color, font, flags);
}

// 量一段文字的像素宽度（用于按内容自适应按钮尺寸）
fn textWidth(hdc: usize, font: usize, text: [*:0]const u16) i32 {
    var rc = RECT{ .left = 0, .top = 0, .right = 0, .bottom = 0 };
    const old = SelectObject(hdc, font);
    _ = DrawTextW(hdc, text, -1, &rc, DT_SINGLELINE | DT_CALCRECT);
    _ = SelectObject(hdc, old);
    return rc.right - rc.left;
}

// 带边框圆角胶囊（画在 4x 画布上，r 为 1x 逻辑坐标）
fn pillShape(hdc: usize, r: RECT, rec: bool) void {
    const fill: u32 = if (rec) C_PILL_ON else C_PILL_BG;
    const border: u32 = if (rec) C_ACC else C_PILL_BD;
    const brush = CreateSolidBrush(fill);
    const pen = CreatePen(PS_SOLID, SS, border);
    const ob = SelectObject(hdc, brush);
    const op = SelectObject(hdc, pen);
    _ = RoundRect(hdc, r.left * SS, r.top * SS, r.right * SS, r.bottom * SS, sc(8) * SS * 2, sc(8) * SS * 2);
    _ = SelectObject(hdc, ob);
    _ = SelectObject(hdc, op);
    _ = DeleteObject(brush);
    _ = DeleteObject(pen);
}

// 胶囊内部的竖分隔线（文字区与图标区之间，两种形态都有）
fn drawPillDivider(hdc: usize, pill: RECT) void {
    const div_x = (pill.right - sc(24)) * SS;
    const pen = CreatePen(PS_SOLID, SS, C_PILL_DIV);
    const op = SelectObject(hdc, pen);
    _ = MoveToEx(hdc, div_x, (pill.top + sc(7)) * SS, null);
    _ = LineTo(hdc, div_x, (pill.bottom - sc(7)) * SS);
    _ = SelectObject(hdc, op);
    _ = DeleteObject(pen);
}

// 图标区的 × （清除快捷键）
fn drawCross(hdc: usize, pill: RECT) void {
    const cx = (pill.right - sc(12)) * SS;
    const cy = @divTrunc((pill.top + pill.bottom), 2) * SS;
    const s = sc(5) * SS;
    const pen = CreatePen(PS_SOLID, SS, C_MUT);
    const op = SelectObject(hdc, pen);
    _ = MoveToEx(hdc, cx - s, cy - s, null);
    _ = LineTo(hdc, cx + s, cy + s);
    _ = MoveToEx(hdc, cx - s, cy + s, null);
    _ = LineTo(hdc, cx + s, cy - s);
    _ = SelectObject(hdc, op);
    _ = DeleteObject(pen);
}

// 胶囊右侧的 ↻ 图标：近乎整圈的圆弧（顶部留缺口）+ 端头实心箭头
// 图标区「重置为默认」：近乎整圈的圆弧（缺口在下方）+ 端头实心箭头
fn drawResetIcon(hdc: usize, cx1: i32, cy1: i32) void {
    const cx = cx1 * SS;
    const cy = cy1 * SS;
    const rad = sc(7) * SS;
    const fr: f64 = @floatFromInt(rad);
    const deg = std.math.pi / 180.0;

    // 屏幕坐标 y 向下：角度增大即顺时针。从 130°（左下）扫 280° 到 410°(≡50°，右下)，缺口留在下方 80°
    const a_start = 130.0 * deg;
    const a_sweep = 280.0 * deg;
    const a_end = a_start + a_sweep;
    const steps = 48;
    var pts: [49]POINT = undefined;
    var n: usize = 0;
    while (n <= steps) : (n += 1) {
        const f = @as(f64, @floatFromInt(n)) / @as(f64, @floatFromInt(steps));
        const a = a_start + a_sweep * f;
        pts[n] = POINT{
            .x = cx + @as(i32, @intFromFloat(@round(fr * @cos(a)))),
            .y = cy + @as(i32, @intFromFloat(@round(fr * @sin(a)))),
        };
    }

    const w: i32 = @max(2, sc(1) * SS + SS / 2);
    const pen = CreatePen(PS_SOLID, w, C_MUT);
    const op = SelectObject(hdc, pen);
    _ = Polyline(hdc, &pts, steps + 1);
    _ = SelectObject(hdc, op);
    _ = DeleteObject(pen);

    // 箭头：接在圆弧末端，沿顺时针切线方向，实心三角
    const px: f64 = fr * @cos(a_end);
    const py: f64 = fr * @sin(a_end);
    const tx = -@sin(a_end);
    const ty = @cos(a_end);
    const nx = -ty;
    const ny = tx;
    const alen = fr * 0.8;
    const awid = fr * 0.52;
    const tip = POINT{ .x = cx + @as(i32, @intFromFloat(@round(px + tx * alen))), .y = cy + @as(i32, @intFromFloat(@round(py + ty * alen))) };
    const b1 = POINT{ .x = cx + @as(i32, @intFromFloat(@round(px + nx * awid))), .y = cy + @as(i32, @intFromFloat(@round(py + ny * awid))) };
    const b2 = POINT{ .x = cx + @as(i32, @intFromFloat(@round(px - nx * awid))), .y = cy + @as(i32, @intFromFloat(@round(py - ny * awid))) };

    const brush = CreateSolidBrush(C_MUT);
    const npen = CreatePen(PS_NULL, 0, C_MUT);
    const ob = SelectObject(hdc, brush);
    const onp = SelectObject(hdc, npen);
    _ = Polygon(hdc, &[3]POINT{ tip, b1, b2 }, 3);
    _ = SelectObject(hdc, ob);
    _ = SelectObject(hdc, onp);
    _ = DeleteObject(brush);
    _ = DeleteObject(npen);
}

fn drawSwitch(hdc: usize, r: RECT, on_state: bool) void {
    const l = r.left * SS;
    const t = r.top * SS;
    const ri = r.right * SS;
    const bo = r.bottom * SS;
    roundFill(hdc, l, t, ri, bo, @divTrunc(bo - t, 2), if (on_state) C_ACC else C_SW_OFF);
    const d = (bo - t) - 2 * sc(3) * SS;
    const ktop = t + sc(3) * SS;
    const kleft = if (on_state) ri - sc(3) * SS - d else l + sc(3) * SS;
    ellipseFill(hdc, kleft, ktop, kleft + d, ktop + d, C_WHITE);
}

// 每行顶部 y：四行等高间距（快捷键按钮已移到标题行右侧，不再单独占一行）
// 顶部要让出自绘标题栏的 CHROME_H
fn rowTop(i: usize) i32 {
    return sc(18 + CHROME_H) + @as(i32, @intCast(i)) * sc(64);
}

// 自绘标题栏的两个按钮（最小化 / 关闭），右对齐；不含最大化
fn layoutChrome() void {
    const by = sc(6);
    const bh = sc(26);
    const bw = sc(28);
    const right = g_cw - sc(10);
    rc_btn_close = RECT{ .left = right - bw, .top = by, .right = right, .bottom = by + bh };
    rc_btn_min = RECT{ .left = rc_btn_close.left - sc(6) - bw, .top = by, .right = rc_btn_close.left - sc(6), .bottom = by + bh };
}

fn layout(hdc: usize) void {
    layoutChrome();
    const sw_w = sc(46);
    const sw_h = sc(24);
    const x2 = g_cw - sc(20);
    const x1 = x2 - sw_w;
    var i: usize = 1; // 快捷键行没有开关
    while (i < 4) : (i += 1) {
        const top = rowTop(i) + sc(4);
        rc_sw[i] = RECT{ .left = x1, .top = top, .right = x2, .bottom = top + sw_h };
    }

    // 快捷键按钮：按内容自适应宽度，右对齐到与各开关同一条竖线（标题行右侧）
    const label: [*:0]const u16 = if (g_recording)
        utf16("按下快捷键…")
    else if (g_hk_vk != 0)
        @ptrCast(&g_hotkey_text)
    else
        utf16("设置快捷键");
    const pw = sc(10) + textWidth(hdc, g_font_status, label) + sc(6) + (if (g_recording) 0 else sc(24));
    const ptop = rowTop(0) - sc(3);
    g_pill = RECT{ .left = x2 - pw, .top = ptop, .right = x2, .bottom = ptop + sc(26) };
    g_xrect = RECT{ .left = g_pill.right - sc(24), .top = g_pill.top, .right = g_pill.right, .bottom = g_pill.bottom };
    rc_off = RECT{ .left = sc(20), .top = sc(276 + CHROME_H), .right = g_cw - sc(20), .bottom = sc(316 + CHROME_H) };
}

// 把某个像素按覆盖率混入图标颜色（1x 直绘，配合下面的子采样实现抗锯齿）
fn blendGlyphPx(hdc: usize, px: i32, py: i32, cov: f32) void {
    const ink_r: f32 = @floatFromInt(C_MUT & 0xFF);
    const ink_g: f32 = @floatFromInt((C_MUT >> 8) & 0xFF);
    const ink_b: f32 = @floatFromInt((C_MUT >> 16) & 0xFF);
    const bg = GetPixel(hdc, px, py);
    const br: f32 = @floatFromInt(bg & 0xFF);
    const bgc: f32 = @floatFromInt((bg >> 8) & 0xFF);
    const bb: f32 = @floatFromInt((bg >> 16) & 0xFF);
    const r: u32 = @intFromFloat(@round(br + (ink_r - br) * cov));
    const g: u32 = @intFromFloat(@round(bgc + (ink_g - bgc) * cov));
    const b: u32 = @intFromFloat(@round(bb + (ink_b - bb) * cov));
    _ = SetPixel(hdc, px, py, r | (g << 8) | (b << 16));
}

// 图标像素框（以按钮中心为圆心，边长按半臂长 + 1px 余量）
const GlyphBox = struct { x0: i32, x1: i32, y0: i32, y1: i32, cx: f32, cy: f32 };

fn glyphBox(r: RECT, half: f32) GlyphBox {
    const cx: f32 = @as(f32, @floatFromInt(r.left + r.right)) / 2.0;
    const cy: f32 = @as(f32, @floatFromInt(r.top + r.bottom)) / 2.0;
    return .{
        .x0 = @as(i32, @intFromFloat(@floor(cx - half))) - 1,
        .x1 = @as(i32, @intFromFloat(@ceil(cx + half))) + 1,
        .y0 = @as(i32, @intFromFloat(@floor(cy - half))) - 1,
        .y1 = @as(i32, @intFromFloat(@ceil(cy + half))) + 1,
        .cx = cx,
        .cy = cy,
    };
}

// 标题栏按钮里的图形：关闭 × / 最小化 —。
// 两个都按 4x4 子采样自己算覆盖率，不用 GDI 画线或填充斜四边形 —— 它那套
// "终点不含、右/下边界不算"的光栅化规则会让两条斜臂差一档覆盖度，10px 的
// × 看上去就是歪的。子采样网格与形状都严格镜像对称，画出来上下左右完全一致。
fn drawCaptionGlyphs(hdc: usize) void {
    const half: f32 = @floatFromInt(sc(4)); // 半臂长
    const hw: f32 = 0.75; // 笔画半宽（≈1.5 逻辑像素）

    // 关闭 ×
    {
        const b = glyphBox(rc_btn_close, half);
        var py = b.y0;
        while (py <= b.y1) : (py += 1) {
            var px = b.x0;
            while (px <= b.x1) : (px += 1) {
                var hits: u32 = 0;
                var sy: u32 = 0;
                while (sy < 4) : (sy += 1) {
                    var sx: u32 = 0;
                    while (sx < 4) : (sx += 1) {
                        const fx = @as(f32, @floatFromInt(px)) + (@as(f32, @floatFromInt(sx)) + 0.5) * 0.25 - b.cx;
                        const fy = @as(f32, @floatFromInt(py)) + (@as(f32, @floatFromInt(sy)) + 0.5) * 0.25 - b.cy;
                        if (@abs(fx) <= half and @abs(fy) <= half) {
                            const d1 = @abs(fy - fx) * 0.70710678;
                            const d2 = @abs(fy + fx) * 0.70710678;
                            if (@min(d1, d2) <= hw) hits += 1;
                        }
                    }
                }
                if (hits == 0) continue;
                blendGlyphPx(hdc, px, py, @as(f32, @floatFromInt(hits)) / 16.0);
            }
        }
    }

    // 最小化 —
    {
        const b = glyphBox(rc_btn_min, half);
        var py = b.y0;
        while (py <= b.y1) : (py += 1) {
            var px = b.x0;
            while (px <= b.x1) : (px += 1) {
                var hits: u32 = 0;
                var sy: u32 = 0;
                while (sy < 4) : (sy += 1) {
                    var sx: u32 = 0;
                    while (sx < 4) : (sx += 1) {
                        const fx = @as(f32, @floatFromInt(px)) + (@as(f32, @floatFromInt(sx)) + 0.5) * 0.25 - b.cx;
                        const fy = @as(f32, @floatFromInt(py)) + (@as(f32, @floatFromInt(sy)) + 0.5) * 0.25 - b.cy;
                        if (@abs(fx) <= half and @abs(fy) <= hw) hits += 1;
                    }
                }
                if (hits == 0) continue;
                blendGlyphPx(hdc, px, py, @as(f32, @floatFromInt(hits)) / 16.0);
            }
        }
    }
}

const RowDef = struct {
    title: [*:0]const u16,
    status_on: [*:0]const u16,
    status_off: [*:0]const u16,
    on: bool,
};

fn freeBuffers() void {
    if (g_mem != 0) { _ = DeleteDC(g_mem); g_mem = 0; }
    if (g_bm != 0) { _ = DeleteObject(g_bm); g_bm = 0; }
    if (g_mem4 != 0) { _ = DeleteDC(g_mem4); g_mem4 = 0; }
    if (g_bm4 != 0) { _ = DeleteObject(g_bm4); g_bm4 = 0; }
    g_buf_w = 0;
    g_buf_h = 0;
    g_cache_valid = false;
}

// 空闲工作集修剪：把暂时不用的物理页交还给系统，任务管理器占用降到 1~3MB
fn trimWS() void {
    _ = SetProcessWorkingSetSize(GetCurrentProcess(), -1, -1);
}

// 只重绘某一行（状态文字/圆点/开关变化时）
fn invalidateRow(hwnd: usize, i: usize) void {
    const top = rowTop(i);
    // 上下留余量：胶囊比标题行略高、圆角描边也会溢出 1px，不留余量会残留旧图形
    const r = RECT{ .left = 0, .top = top - sc(12), .right = g_cw, .bottom = top + sc(56) };
    g_cache_valid = false;
    _ = InvalidateRect(hwnd, &r, 0);
}

fn paint(hwnd: usize) void {
    // 隐藏/托盘状态不分配绘制缓冲，也不绘制（避免空闲时白占内存）
    if (IsWindowVisible(hwnd) == 0) {
        _ = ValidateRect(hwnd, null);
        return;
    }
    var ps: PAINTSTRUCT = undefined;
    const hdc = BeginPaint(hwnd, &ps);
    defer _ = EndPaint(hwnd, &ps);

    var rc: RECT = undefined;
    _ = GetClientRect(hwnd, &rc);
    g_cw = rc.right;
    g_ch = rc.bottom;
    layout(hdc);

    // ---- #1 缓冲区复用：只在首次绘制或尺寸变化时创建，之后一直复用 ----
    if (g_mem == 0 or g_buf_w != g_cw or g_buf_h != g_ch) {
        freeBuffers();
        g_mem = CreateCompatibleDC(hdc);
        g_bm = CreateCompatibleBitmap(hdc, g_cw, g_ch);
        _ = SelectObject(g_mem, g_bm);
        g_mem4 = CreateCompatibleDC(hdc);
        g_bm4 = CreateCompatibleBitmap(hdc, g_cw * SS, g_ch * SS);
        _ = SelectObject(g_mem4, g_bm4);
        _ = SetStretchBltMode(g_mem, HALFTONE);
        g_buf_w = g_cw;
        g_buf_h = g_ch;
        g_cache_valid = false;
    }

    // ---- 缓存失效时才重画内容（状态变化时置 false） ----
    if (!g_cache_valid) {
        const hk_on = hotkeySet();
        const rows = [4]RowDef{
            .{ .title = utf16("快捷键"), .status_on = utf16("已设置"), .status_off = utf16("未设置"), .on = hk_on },
            .{ .title = utf16("开机自启"), .status_on = utf16("已注册 · 下次登录自动在托盘运行"), .status_off = utf16("未注册"), .on = g_auto_on },
            .{ .title = utf16("托盘常驻"), .status_on = utf16("已开启"), .status_off = utf16("已关闭"), .on = g_tray_on },
            .{ .title = utf16("隐藏托盘"), .status_on = utf16("已隐藏 · 快捷键仍有效，双击 exe 打开本窗口"), .status_off = utf16("已显示"), .on = g_hide_tray },
        };

        // 4x 超采样：形状画在 4 倍画布上，再缩小回去获得平滑边缘
        fillRectColor(g_mem4, 0, 0, g_cw * SS, g_ch * SS, C_BG);

        // 标题栏按钮的悬停底色
        if (g_hover == 9) {
            roundFill(g_mem4, rc_btn_min.left * SS, rc_btn_min.top * SS, rc_btn_min.right * SS, rc_btn_min.bottom * SS, sc(6) * SS, C_BTN_HOV);
        } else if (g_hover == 10) {
            roundFill(g_mem4, rc_btn_close.left * SS, rc_btn_close.top * SS, rc_btn_close.right * SS, rc_btn_close.bottom * SS, sc(6) * SS, C_CLOSE_HOV);
        }

        var i: usize = 0;
        while (i < 4) : (i += 1) {
            const row = rows[i];
            const top = rowTop(i);
            if (i > 0) drawSwitch(g_mem4, rc_sw[i], row.on);
            const dot_d = sc(7) * SS;
            const dot_y = (top + sc(26)) * SS + @divTrunc(sc(16) * SS - dot_d, 2);
            ellipseFill(g_mem4, sc(20) * SS, dot_y, sc(20) * SS + dot_d, dot_y + dot_d, if (row.on) C_ACC else C_DOT_OFF);
            if (i < 3) {
                const div_y = top + sc(48);
                fillRectColor(g_mem4, sc(20) * SS, div_y * SS, (g_cw - sc(20)) * SS, div_y * SS + SS, C_DIV);
            }
        }
        // 快捷键小胶囊（两种形态）+ 分隔线 + 图标
        pillShape(g_mem4, g_pill, g_recording);
        if (!g_recording) {
            drawPillDivider(g_mem4, g_pill);
            if (hk_on) {
                drawCross(g_mem4, g_pill);
            } else {
                drawResetIcon(g_mem4, g_pill.right - sc(12), @divTrunc(g_pill.top + g_pill.bottom, 2));
            }
        }
        const hov_off = g_hover == 7;
        roundFill(g_mem4, rc_off.left * SS, rc_off.top * SS, rc_off.right * SS, rc_off.bottom * SS, sc(9) * SS, if (hov_off) C_ACC_H else C_ACC);

        // HALFTONE 缩小回 1x
        _ = StretchBlt(g_mem, 0, 0, g_cw, g_ch, g_mem4, 0, 0, g_cw * SS, g_ch * SS, SRCCOPY);

        // 文字按原始尺寸绘制（ClearType 保持锐利，不参与缩放）
        // ---- 自绘标题栏：标题 + 最小化 / 关闭 ----
        drawTextW16(g_mem, WND_TITLE, sc(20), 0, g_cw - sc(96), sc(CHROME_H), C_TEXT, g_font_title, 0);
        drawCaptionGlyphs(g_mem);

        var j: usize = 0;
        while (j < 4) : (j += 1) {
            const row = rows[j];
            const top = rowTop(j);
            drawTextW16(g_mem, row.title, sc(20), top, sc(200), sc(20), C_TEXT, g_font_title, 0);
            const dot_d = sc(7);
            drawTextW16(g_mem, if (row.on) row.status_on else row.status_off, sc(20) + dot_d + sc(6), top + sc(26), sc(280), sc(16), C_MUT, g_font_status, 0);
        }
        // 胶囊文字（三种形态）：左内边距 10，右侧留出图标区
        const icon_w: i32 = if (g_recording) 0 else sc(24);
        const txt_left = g_pill.left + sc(10);
        const txt_w = (g_pill.right - icon_w - sc(6)) - txt_left;
        if (g_recording) {
            drawTextW16(g_mem, utf16("按下快捷键…"), txt_left, g_pill.top, txt_w, g_pill.bottom - g_pill.top, C_ACC_TX, g_font_status, 0);
        } else if (hk_on) {
            drawTextW16(g_mem, @ptrCast(&g_hotkey_text), txt_left, g_pill.top, txt_w, g_pill.bottom - g_pill.top, C_PILL_TX, g_font_status, 0);
        } else {
            drawTextW16(g_mem, utf16("设置快捷键"), txt_left, g_pill.top, txt_w, g_pill.bottom - g_pill.top, C_PILL_TX, g_font_status, 0);
        }
        drawText(g_mem, "立即关闭显示器", rc_off.left, rc_off.top, rc_off.right - rc_off.left, rc_off.bottom - rc_off.top, C_WHITE, g_font_btn, DT_CENTER);
        g_cache_valid = true;
    }

    // ---- #2 脏区域：只把需要更新的区域从缓存拷到屏幕 ----
    _ = BitBlt(hdc, ps.rcPaint.left, ps.rcPaint.top, ps.rcPaint.right - ps.rcPaint.left, ps.rcPaint.bottom - ps.rcPaint.top, g_mem, ps.rcPaint.left, ps.rcPaint.top, SRCCOPY);
}

// 悬停时有视觉变化的命中项：主按钮 7、标题栏按钮 9/10
fn isVisualHit(h: u8) bool {
    return h == 7 or h == 9 or h == 10;
}

fn hitTest(x: i32, y: i32) u8 {
    if (inRect(rc_btn_close, x, y)) return 10; // 标题栏：关闭
    if (inRect(rc_btn_min, x, y)) return 9; // 标题栏：最小化
    var i: usize = 1; // 快捷键行没有开关
    while (i < 4) : (i += 1) {
        if (inRect(rc_sw[i], x, y)) return @intCast(i + 1);
    }
    if (!g_recording and inRect(g_xrect, x, y)) return if (hotkeySet()) 5 else 8; // × 清除 / ↺ 重置为默认
    if (inRect(g_pill, x, y)) return 6; // 录制/重新录制（点文字部分）
    if (inRect(rc_off, x, y)) return 7; // 主按钮
    return 0;
}

// ================= 窗口过程 =================
fn wndproc(hwnd: usize, msg: u32, wp: usize, lp: isize) callconv(.c) isize {
    switch (msg) {
        WM_CREATE => {
            g_dpi = @intCast(GetDpiForWindow(hwnd));
            if (g_dpi == 0) g_dpi = 96;
            g_font_title = makeFont(10, 500);
            g_font_status = makeFont(9, 400);
            g_font_btn = makeFont(10, 500);
            g_cursor_hand = LoadCursorW(0, IDC_HAND);

            // 窗口尺寸随 DPI 缩放。客户区 = 整个窗口（自绘标题栏，WM_NCCALCSIZE 已去掉非客户区），
            // 所以这里直接用内容尺寸，不再 AdjustWindowRectEx。
            g_cw = sc(360);
            g_ch = sc(336 + CHROME_H);
            _ = SetWindowPos(hwnd, 0, 0, 0, g_cw, g_ch, SWP_NOMOVE | SWP_NOZORDER);
            layoutChrome();

            g_auto_on = isAutoRun();
            g_tray_on = trayResident();
            g_hide_tray = hideTrayEnabled();
            readHotkeyCfg();
            buildHotkeyText();

            if (!applyHotkey(hwnd)) {
                _ = MessageBoxW(hwnd, utf16("快捷键 Win+Alt+L 注册失败，可能被其他程序占用。"), WND_TITLE, MB_ICONWARNING);
            }
            // 空闲修剪兜底：启动后/交互后陆续被触碰的页面，每 30 秒还一次给系统
            _ = SetTimer(hwnd, 1, 30000, null);
            return 0;
        },
        WM_TIMER => {
            trimWS();
            return 0;
        },
        WM_ERASEBKGND => return 1,
        // 自绘标题栏：把非客户区整个去掉，客户区铺满窗口（系统标题栏随之消失，
        // 最大化按钮也就根本不存在了），再由 WM_NCHITTEST 把标题栏区域交给拖动
        WM_NCCALCSIZE => {
            if (wp != 0) return 0;
        },
        WM_NCHITTEST => {
            const sx: i32 = @as(i16, @truncate(lp & 0xFFFF));
            const sy: i32 = @as(i16, @truncate((lp >> 16) & 0xFFFF));
            var pt = POINT{ .x = sx, .y = sy };
            _ = ScreenToClient(hwnd, &pt);
            if (pt.y < sc(CHROME_H)) {
                // 按钮区域要留给点击，其余部分当标题栏拖动
                if (inRect(rc_btn_min, pt.x, pt.y) or inRect(rc_btn_close, pt.x, pt.y)) return HTCLIENT;
                return HTCAPTION;
            }
            return HTCLIENT;
        },
        WM_PAINT => {
            paint(hwnd);
            return 0;
        },
        WM_MOUSEMOVE => {
            const x: i32 = @as(i16, @truncate(lp & 0xFFFF));
            const y: i32 = @as(i16, @truncate((lp >> 16) & 0xFFFF));
            const h = hitTest(x, y);
            if (h != g_hover) {
                // 主按钮 / 标题栏按钮有悬停变色。只要新旧任一项"有视觉变化"就要重画：
                // 之前写成两者都比对，导致从最小化直接移到关闭（都是可视项）时不刷新，
                // 关闭按钮的高亮因此一直画不出来。
                if (isVisualHit(h) or isVisualHit(g_hover)) {
                    g_cache_valid = false;
                    _ = InvalidateRect(hwnd, null, 0);
                }
                g_hover = h;
            }
            _ = SetCursor(if (h != 0) g_cursor_hand else LoadCursorW(0, IDC_ARROW));
            if (h != 0 and !g_tracked) {
                g_tracked = true;
                var tme = TRACKMOUSEEVENT{ .cbSize = @sizeOf(TRACKMOUSEEVENT), .dwFlags = TME_LEAVE, .hwndTrack = hwnd, .dwHoverTime = 0 };
                _ = TrackMouseEvent(&tme);
            }
            return 0;
        },
        WM_MOUSELEAVE => {
            g_tracked = false;
            if (g_hover != 0) {
                const was_visual = isVisualHit(g_hover);
                g_hover = 0;
                if (was_visual) {
                    g_cache_valid = false;
                    _ = InvalidateRect(hwnd, null, 0);
                }
            }
            trimWS();
            return 0;
        },
        WM_LBUTTONUP => {
            const x: i32 = @as(i16, @truncate(lp & 0xFFFF));
            const y: i32 = @as(i16, @truncate((lp >> 16) & 0xFFFF));
            switch (hitTest(x, y)) {
                2 => { // 开机自启
                    _ = setAutoRun(!g_auto_on);
                    g_auto_on = isAutoRun();
                    invalidateRow(hwnd, 1);
                },
                3 => { // 托盘常驻
                    g_tray_on = !g_tray_on;
                    writeAppBool(TRAY_VALUE, g_tray_on);
                    invalidateRow(hwnd, 2);
                },
                4 => { // 隐藏托盘
                    g_hide_tray = !g_hide_tray;
                    writeAppBool(HIDE_VALUE, g_hide_tray);
                    if (g_hide_tray) {
                        removeTrayIcon(hwnd);
                    } else {
                        addTrayIcon(hwnd);
                    }
                    invalidateRow(hwnd, 3);
                },
                5 => { // ×：清除快捷键（空 = 不设置）
                    g_hk_vk = 0;
                    writeHotkeyCfg();
                    _ = UnregisterHotKey(hwnd, ID_HOTKEY);
                    invalidateRow(hwnd, 0);
                },
                6 => { // 设置快捷键：进入 / 取消录制
                    if (g_recording) {
                        g_recording = false;
                    } else {
                        g_recording = true;
                        _ = UnregisterHotKey(hwnd, ID_HOTKEY);
                    }
                    invalidateRow(hwnd, 0);
                },
                7 => monitorOff(),
                8 => { // ↺：重置为默认快捷键 Win + Alt + L
                    g_hk_mods = HK_DEFAULT_MODS;
                    g_hk_vk = HK_DEFAULT_VK;
                    writeHotkeyCfg();
                    buildHotkeyText();
                    if (!applyHotkey(hwnd)) {
                        _ = MessageBoxW(hwnd, utf16("快捷键 Win+Alt+L 注册失败，可能被其他程序占用。"), WND_TITLE, MB_ICONWARNING);
                    }
                    invalidateRow(hwnd, 0);
                },
                9 => _ = ShowWindow(hwnd, SW_MINIMIZE), // 标题栏：最小化
                10 => _ = PostMessageW(hwnd, WM_CLOSE, 0, 0), // 标题栏：关闭
                else => {},
            }
            return 0;
        },
        WM_KEYDOWN, WM_SYSKEYDOWN => {
            if (g_recording) {
                handleRecKey(hwnd, @intCast(wp));
                return 0;
            }
        },
        WM_HOTKEY => {
            monitorOff();
            return 0;
        },
        WM_SHOW_SETTINGS => {
            showSettings(hwnd);
            return 0;
        },
        WM_CLOSE => {
            if (g_tray_on) {
                _ = ShowWindow(hwnd, SW_HIDE); // 常驻：关闭 = 最小化到托盘
                freeBuffers(); // 窗口隐藏期间用不到绘制缓冲，整体释放（约 9MB）
                trimWS();
            } else {
                _ = DestroyWindow(hwnd); // 不常驻：关闭 = 退出
            }
            return 0;
        },
        TRAY_CB_MSG => {
            const ev: u32 = @intCast(lp & 0xFFFF);
            if (ev == WM_RBUTTONUP) {
                showTrayMenu(); // 自绘菜单，主窗口不参与
            } else if (ev == WM_LBUTTONUP) {
                _ = PostMessageW(hwnd, WM_SHOW_SETTINGS, 0, 0);
            }
            return 0;
        },
        WM_MENU_CMD => {
            switch (@as(i32, @intCast(wp))) {
                MENU_OFF => monitorOff(),
                MENU_SETTINGS => _ = PostMessageW(hwnd, WM_SHOW_SETTINGS, 0, 0),
                MENU_QUIT => _ = DestroyWindow(hwnd),
                else => {},
            }
            return 0;
        },
        WM_DESTROY => {
            if (g_menu_hwnd != 0) _ = DestroyWindow(g_menu_hwnd);
            var nid = std.mem.zeroes(NOTIFYICONDATAW);
            nid.cbSize = @sizeOf(NOTIFYICONDATAW);
            nid.hWnd = hwnd;
            nid.uID = 1;
            _ = Shell_NotifyIconW(NIM_DELETE, &nid);
            _ = UnregisterHotKey(hwnd, ID_HOTKEY);
            _ = DeleteObject(g_font_title);
            _ = DeleteObject(g_font_status);
            _ = DeleteObject(g_font_btn);
            PostQuitMessage(0);
            return 0;
        },
        else => {},
    }
    return DefWindowProcW(hwnd, msg, wp, lp);
}

// ================= 入口 =================
pub fn main() u8 {
    _ = SetProcessDPIAware();
    const hInst = GetModuleHandleW(null);

    // 单实例：重复启动时把已运行实例的设置窗口唤到前台
    const mutex = CreateMutexW(null, 0, MUTEX_NAME);
    if (GetLastError() == ERROR_ALREADY_EXISTS) {
        const old = FindWindowW(CLASS_NAME, null);
        if (old != 0) _ = SendMessageW(old, WM_SHOW_SETTINGS, 0, 0);
        return 0;
    }
    _ = mutex;

    // 开机自启时带 /tray 参数静默启动；手动双击则弹出设置窗口
    var silent = false;
    const cmd = std.mem.span(@as([*:0]const u16, @ptrCast(GetCommandLineW())));
    if (std.mem.indexOf(u16, cmd, std.unicode.utf8ToUtf16LeStringLiteral("/tray")) != null) silent = true;

    const wc = WNDCLASSEXW{
        .cbSize = @sizeOf(WNDCLASSEXW),
        .style = 0,
        .lpfnWndProc = wndproc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = hInst,
        .hIcon = LoadIconW(hInst, ICON_RES_ID),
        .hCursor = LoadCursorW(0, IDC_ARROW),
        .hbrBackground = 16, // (HBRUSH)(COLOR_BTNFACE+1)
        .lpszMenuName = null,
        .lpszClassName = CLASS_NAME,
        .hIconSm = LoadIconW(hInst, ICON_RES_ID),
    };
    _ = RegisterClassExW(&wc);

    // 客户区 = 整个窗口（自绘标题栏），初始尺寸就是内容尺寸
    const w = 360;
    const h = 336 + CHROME_H;

    g_hwnd = CreateWindowExW(0, CLASS_NAME, WND_TITLE, WND_STYLE, 300, 300, w, h, 0, 0, hInst, null);

    // Win11 圆角（失败则忽略，Win10 为直角）
    const pref: u32 = 2; // DWMWCP_ROUND
    _ = DwmSetWindowAttribute(g_hwnd, 33, &pref, 4);

    _ = ShowWindow(g_hwnd, if (silent) SW_HIDE else SW_SHOW);
    if (!g_hide_tray) addTrayIcon(g_hwnd); // 隐藏托盘模式下不显示图标
    trimWS(); // 启动完成后把工作集交还给系统

    var msg: MSG = undefined;
    while (GetMessageW(&msg, 0, 0, 0) > 0) {
        _ = TranslateMessage(&msg);
        _ = DispatchMessageW(&msg);
    }
    return 0;
}
