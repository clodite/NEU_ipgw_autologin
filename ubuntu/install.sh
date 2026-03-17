#!/bin/bash
set -e

echo "========================================"
echo "IPGW 自动打包和自启动设置脚本"
echo "========================================"
echo ""

# 设置变量
SCRIPT_NAME="ipgw.py"
VENV_DIR="venv"
BUILD_DIR="build"
DIST_DIR="dist"
OUTPUT_DIR="ipgw_app"
CHROMIUM_DIR="chromium"

# 检查Python是否安装
if ! command -v python3 &> /dev/null; then
    echo "[错误] 未检测到Python，请先安装Python"
    read -p "按任意键退出..."
    exit 1
fi

echo "[1/8] 创建虚拟环境..."
if [ -d "$VENV_DIR" ]; then
    echo "虚拟环境已存在，删除旧环境..."
    rm -rf "$VENV_DIR"
fi
python3 -m venv "$VENV_DIR"
echo "虚拟环境创建成功"
echo ""

echo "[2/8] 激活虚拟环境并安装依赖..."
source "$VENV_DIR/bin/activate"
pip install --upgrade pip
pip install playwright pyinstaller
echo "依赖安装成功"
echo ""

echo "[3/8] 安装Playwright Chromium..."
playwright install chromium
echo "Chromium安装成功"
echo ""

echo "[4/8] 定位并复制Chromium文件..."
# 获取Playwright浏览器路径
CHROME_PATH=$(python3 -c "import playwright; from playwright.sync_api import sync_playwright; p = sync_playwright().start(); print(p.chromium.executable_path); p.stop()" 2>/dev/null)

if [ -z "$CHROME_PATH" ]; then
    echo "[错误] 无法定位Chromium路径"
    read -p "按任意键退出..."
    exit 1
fi

echo "找到Chromium路径: $CHROME_PATH"

# 获取Chromium所在目录
CHROME_PARENT_DIR=$(dirname "$CHROME_PATH")

# 创建chromium目录并复制文件
if [ -d "$CHROMIUM_DIR" ]; then
    rm -rf "$CHROMIUM_DIR"
fi
mkdir "$CHROMIUM_DIR"

# 复制整个Chromium目录
echo "正在复制Chromium文件，这可能需要几分钟..."
cp -r "$CHROME_PARENT_DIR"/* "$CHROMIUM_DIR"/
echo "Chromium文件复制完成"
echo ""

echo "[5/8] 打包程序..."
# 删除旧的构建目录
if [ -d "$BUILD_DIR" ]; then
    rm -rf "$BUILD_DIR"
fi
if [ -d "$DIST_DIR" ]; then
    rm -rf "$DIST_DIR"
fi
if [ -d "$OUTPUT_DIR" ]; then
    rm -rf "$OUTPUT_DIR"
fi

# 使用PyInstaller打包
pyinstaller --name "ipgw" --onedir --add-data "$CHROMIUM_DIR:chromium" "$SCRIPT_NAME"
echo "打包成功"
echo ""

echo "[6/8] 整理输出文件..."
# 将dist目录下的文件夹移动到当前目录并重命名
mv "$DIST_DIR/ipgw" "$OUTPUT_DIR"
echo "输出文件整理完成"
echo ""

echo "[7/8] 清理临时文件..."
# 删除虚拟环境、构建目录、dist目录、chromium目录、spec文件
rm -rf "$VENV_DIR"
rm -rf "$BUILD_DIR"
rm -rf "$DIST_DIR"
rm -rf "$CHROMIUM_DIR"
if [ -f "ipgw.spec" ]; then
    rm "ipgw.spec"
fi
echo "临时文件清理完成"
echo ""

echo "[8/8] 创建自启动配置..."
# 获取当前脚本所在目录
SCRIPT_DIR=$(pwd)
AUTOSTART_DIR="$HOME/.config/autostart"
DESKTOP_FILE="$AUTOSTART_DIR/ipgw.desktop"

# 创建autostart目录（如果不存在）
mkdir -p "$AUTOSTART_DIR"

# 创建.desktop文件
cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Type=Application
Name=IPGW登录工具
Exec="$SCRIPT_DIR/$OUTPUT_DIR/ipgw"
Path="$SCRIPT_DIR/$OUTPUT_DIR"
Terminal=true
EOF

# 设置执行权限
chmod +x "$DESKTOP_FILE"

if [ -f "$DESKTOP_FILE" ]; then
    echo "自启动配置创建成功"
else
    echo "[警告] 自启动配置创建可能失败，请手动检查"
fi
echo ""

echo "========================================"
echo "所有操作完成！"
echo "========================================"
echo ""
echo "程序位置: $SCRIPT_DIR/$OUTPUT_DIR"
echo "自启动配置已添加到: $DESKTOP_FILE"
echo ""
echo "你可以:"
echo "1. 直接运行 $OUTPUT_DIR/ipgw 测试程序"
echo "2. 重启电脑测试自启动功能"
echo ""
read -p "按任意键退出..."