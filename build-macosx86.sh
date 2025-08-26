#!/bin/bash

echo "========================================"
echo "Claude Code Switcher - macOS Build Script (x86)"
echo "========================================"
echo

# 检查 Rust 环境
if ! command -v cargo &> /dev/null; then
    echo "❌ Error: Cargo not found. Please install Rust first."
    echo "Visit: https://rustup.rs/"
    exit 1
fi

# 检查 macOS x86 目标是否安装
if ! rustup target list --installed | grep -q "x86_64-apple-darwin"; then
    echo "📦 Installing x86_64-apple-darwin target..."
    rustup target add x86_64-apple-darwin
fi

echo "[1/4] Cleaning previous build..."
cargo clean

echo
echo "[2/4] Building release version for macOS (Intel x86)..."
cargo build --release --target x86_64-apple-darwin

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo
echo "[3/4] Creating distribution directory..."
mkdir -p dist

echo
echo "[4/7] Copying executable..."
cp target/x86_64-apple-darwin/release/claude-code-switcher dist/claude-code-switcher-macos-x86

echo
echo "[5/7] Creating macOS App Bundle..."
APP_NAME="Claude Code Switcher"
APP_DIR="dist/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

# 创建 App Bundle 目录结构
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

echo
echo "[6/7] Setting up App Bundle contents..."
# 复制可执行文件
cp target/x86_64-apple-darwin/release/claude-code-switcher "${MACOS_DIR}/claude-code-switcher"

# 复制 Info.plist
cp resources/Info.plist "${CONTENTS_DIR}/"

# 生成图标文件 (如果存在 SVG)
echo
echo "[7/7] Processing icons..."
if [ -f "resources/icons/icon.svg" ]; then
    # 尝试使用 rsvg-convert 生成 PNG (如果可用)
    if command -v rsvg-convert &> /dev/null; then
        echo "📦 Converting SVG to PNG using rsvg-convert..."
        rsvg-convert -w 1024 -h 1024 resources/icons/icon.svg -o "${RESOURCES_DIR}/icon.png"

        # 尝试生成 ICNS (如果有 iconutil)
        if command -v iconutil &> /dev/null; then
            echo "📦 Creating ICNS file..."
            ICONSET_DIR="${RESOURCES_DIR}/icon.iconset"
            mkdir -p "${ICONSET_DIR}"

            # 生成不同尺寸的图标
            for size in 16 32 64 128 256 512 1024; do
                rsvg-convert -w $size -h $size resources/icons/icon.svg -o "${ICONSET_DIR}/icon_${size}x${size}.png"
                if [ $size -le 512 ]; then
                    size2x=$((size * 2))
                    rsvg-convert -w $size2x -h $size2x resources/icons/icon.svg -o "${ICONSET_DIR}/icon_${size}x${size}@2x.png"
                fi
            done

            # 生成 ICNS
            iconutil -c icns "${ICONSET_DIR}" -o "${RESOURCES_DIR}/icon.icns"
            rm -rf "${ICONSET_DIR}"
            echo "✅ ICNS file created"
        fi
    else
        echo "⚠️  rsvg-convert not found. Install with: brew install librsvg"
        echo "📋 Copying SVG as fallback..."
        cp resources/icons/icon.svg "${RESOURCES_DIR}/"
    fi
else
    echo "⚠️  SVG icon not found at resources/icons/icon.svg"
fi

# 设置可执行权限
chmod +x "${MACOS_DIR}/claude-code-switcher"

# 检查文件信息
echo
echo "📋 Build Information:"
echo "Target: x86_64-apple-darwin (Intel x86)"
echo "Standalone executable: $(file dist/claude-code-switcher-macos-x86)"
echo "App Bundle: ${APP_DIR}"
echo "File size: $(du -h dist/claude-code-switcher-macos-x86 | cut -f1)"

echo
echo "========================================"
echo "✅ macOS x86 Build completed successfully!"
echo "📁 Standalone executable: dist/claude-code-switcher-macos-x86"
echo "📱 App Bundle: ${APP_DIR}"
echo "🚀 You can now run: ./dist/claude-code-switcher-macos-x86"
echo "🍎 Or drag the App Bundle to /Applications"
echo "========================================"
