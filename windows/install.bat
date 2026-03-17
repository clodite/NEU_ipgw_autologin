@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo IPGW 自动打包和自启动设置脚本
echo ========================================
echo.

:: 设置变量
set "SCRIPT_NAME=ipgw.py"
set "VENV_DIR=venv"
set "BUILD_DIR=build"
set "DIST_DIR=dist"
set "OUTPUT_DIR=ipgw_app"
set "CHROMIUM_DIR=chromium"

:: 检查Python是否安装
python --version >nul 2>&1
if errorlevel 1 (
    echo [错误] 未检测到Python，请先安装Python并添加到PATH
    pause
    exit /b 1
)

echo [1/8] 创建虚拟环境...
if exist "%VENV_DIR%" (
    echo 虚拟环境已存在，删除旧环境...
    rmdir /s /q "%VENV_DIR%"
)
python -m venv "%VENV_DIR%"
if errorlevel 1 (
    echo [错误] 创建虚拟环境失败
    pause
    exit /b 1
)
echo 虚拟环境创建成功
echo.

echo [2/8] 激活虚拟环境并安装依赖...
call "%VENV_DIR%\Scripts\activate.bat"
python -m pip install --upgrade pip
pip install --upgrade pip
pip install playwright pyinstaller
if errorlevel 1 (
    echo [错误] 安装依赖失败
    pause
    exit /b 1
)
echo 依赖安装成功
echo.

echo [3/8] 安装Playwright Chromium...
playwright install chromium
if errorlevel 1 (
    echo [错误] 安装Chromium失败
    pause
    exit /b 1
)
echo Chromium安装成功
echo.

echo [4/8] 定位并复制Chromium文件...
:: 获取Playwright浏览器路径
for /f "delims=" %%i in ('python -c "import playwright; from playwright.sync_api import sync_playwright; p = sync_playwright().start(); print(p.chromium.executable_path); p.stop()" 2^>nul') do (
    set "CHROME_PATH=%%i"
)

if not defined CHROME_PATH (
    echo [错误] 无法定位Chromium路径
    pause
    exit /b 1
)

echo 找到Chromium路径: !CHROME_PATH!

:: 获取Chromium所在目录
for %%i in ("!CHROME_PATH!") do set "CHROME_PARENT_DIR=%%~dpi"
set "CHROME_PARENT_DIR=!CHROME_PARENT_DIR:~0,-1!"

:: 创建chromium目录并复制文件
if exist "%CHROMIUM_DIR%" rmdir /s /q "%CHROMIUM_DIR%"
mkdir "%CHROMIUM_DIR%"

:: 复制整个Chromium目录
echo 正在复制Chromium文件，这可能需要几分钟...
xcopy /e /i /y /q "!CHROME_PARENT_DIR!\*" "%CHROMIUM_DIR%\"
if errorlevel 1 (
    echo [警告] Chromium文件复制可能不完整，请检查
)
echo Chromium文件复制完成
echo.

echo [5/8] 打包程序...
:: 删除旧的构建目录
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
if exist "%DIST_DIR%" rmdir /s /q "%DIST_DIR%"
if exist "%OUTPUT_DIR%" rmdir /s /q "%OUTPUT_DIR%"

:: 使用PyInstaller打包 - 移除了 --noconsole 选项
pyinstaller --name "ipgw" --onedir --add-data "%CHROMIUM_DIR%;chromium" "%SCRIPT_NAME%"
if errorlevel 1 (
    echo [错误] 打包失败
    pause
    exit /b 1
)
echo 打包成功
echo.

echo [6/8] 整理输出文件...
:: 将dist目录下的文件夹移动到当前目录并重命名
move "%DIST_DIR%\ipgw" "%OUTPUT_DIR%"
if errorlevel 1 (
    echo [错误] 移动文件失败
    pause
    exit /b 1
)
echo 输出文件整理完成
echo.

echo [7/8] 清理临时文件...
:: 删除虚拟环境、构建目录、dist目录、chromium目录、spec文件
rmdir /s /q "%VENV_DIR%"
rmdir /s /q "%BUILD_DIR%"
rmdir /s /q "%DIST_DIR%"
rmdir /s /q "%CHROMIUM_DIR%"
if exist "ipgw.spec" del "ipgw.spec"
echo 临时文件清理完成
echo.

echo [8/8] 创建自启动快捷方式...
:: 获取启动文件夹路径
set "STARTUP_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "EXE_PATH=%CD%\%OUTPUT_DIR%\ipgw.exe"
set "SHORTCUT_NAME=IPGW登录工具.lnk"

:: 使用PowerShell创建快捷方式
powershell -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%STARTUP_DIR%\%SHORTCUT_NAME%'); $s.TargetPath = '%EXE_PATH%'; $s.WorkingDirectory = '%CD%\%OUTPUT_DIR%'; $s.Save()"

if exist "%STARTUP_DIR%\%SHORTCUT_NAME%" (
    echo 自启动快捷方式创建成功
) else (
    echo [警告] 快捷方式创建可能失败，请手动检查
)
echo.

echo ========================================
echo 所有操作完成！
echo ========================================
echo.
echo 程序位置: %CD%\%OUTPUT_DIR%
echo 自启动快捷方式已添加到: %STARTUP_DIR%
echo.
echo 你可以:
echo 1. 直接运行 %OUTPUT_DIR%\ipgw.exe 测试程序
echo 2. 重启电脑测试自启动功能
echo.
pause