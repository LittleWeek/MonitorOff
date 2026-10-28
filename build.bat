@echo off
setlocal
cd /d "%~dp0"

rem ============================================================
rem  monitor-off 一键构建：结束旧进程 -> 生成图标资源 -> 编译 -> 启动
rem  用法：build.bat          构建后自动启动
rem        build.bat norun    只构建，不启动
rem  可选：set ZIG=D:\path\zig.exe 指定编译器
rem        （默认优先用 D:\Sdk\zig-0.17.0，其次 PATH 里的 zig）
rem ============================================================

if not defined ZIG (
    if exist "D:\Sdk\zig-0.17.0\zig.exe" (
        set "ZIG=D:\Sdk\zig-0.17.0\zig.exe"
    ) else (
        set "ZIG=zig"
    )
)

"%ZIG%" version >nul 2>nul
if errorlevel 1 (
    echo [错误] 找不到可用的 Zig：%ZIG%
    echo        请设置环境变量 ZIG 指向 zig.exe，或把 Zig 0.17.0 加入 PATH。
    goto :fail
)

echo [1/4] 结束正在运行的 monitor-off.exe
"%SystemRoot%\System32\taskkill.exe" /f /im monitor-off.exe >nul 2>nul
if errorlevel 128 (
    echo       没有在运行
) else if errorlevel 1 (
    echo [错误] 结束进程失败，可能是以管理员身份启动的。
    echo        请先手动关闭托盘图标，或用管理员身份运行本脚本。
    goto :fail
) else (
    ping -n 2 127.0.0.1 >nul
    echo       已结束
)

echo [2/4] 生成图标资源 icon\icon.res
"%ZIG%" rc "icon\icon.rc" "icon\icon.res"
if errorlevel 1 (
    echo [错误] icon.res 生成失败
    goto :fail
)

echo [3/4] 编译 monitor-off.exe
"%ZIG%" build-exe "monitor-off.zig" "icon\icon.res" -O ReleaseSmall --subsystem windows -lgdi32 -lshell32 -ladvapi32 -ldwmapi
if errorlevel 1 (
    echo [错误] 编译失败
    goto :fail
)
if not exist "monitor-off.exe" (
    echo [错误] 编译结束但没有找到 monitor-off.exe
    goto :fail
)
for %%A in ("monitor-off.exe") do set "SIZE=%%~zA"
set /a SIZE_KB=%SIZE%/1024
echo       完成：%SIZE% 字节（约 %SIZE_KB% KB）

echo [4/4] 启动
if /i "%~1"=="norun" (
    echo       跳过（norun）
    goto :done
)
rem start 用相对文件名：当前目录已 cd 到脚本所在目录，
rem 启动路径里不再拼脚本目录变量，避免中文/空格路径被拆开，
rem 系统弹「Windows 找不到 xx 文件」的对话框。
start "" "monitor-off.exe"
if errorlevel 1 (
    echo [错误] monitor-off.exe 启动失败
    goto :fail
)
echo       已启动

:done
endlocal
exit /b 0

:fail
echo.
echo 构建未完成，monitor-off.exe 保持上一次的版本。
endlocal
exit /b 1
