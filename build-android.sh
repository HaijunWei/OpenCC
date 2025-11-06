#!/bin/bash

# OpenCC Android Build Script
# 用于编译 OpenCC 为 Android .so 文件

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 默认配置
ANDROID_NDK="${ANDROID_NDK:-}"
ANDROID_ABI="${ANDROID_ABI:-all}"  # 支持: all, armeabi-v7a, arm64-v8a, x86, x86_64
ANDROID_PLATFORM="${ANDROID_PLATFORM:-21}"  # Android API Level
ANDROID_STL="${ANDROID_STL:-c++_static}"  # C++ STL 类型: c++_static (推荐) 或 c++_shared
BUILD_TYPE="${BUILD_TYPE:-Release}"
BUILD_DIR="build-android"
INSTALL_DIR="install-android"

# 检查 NDK 路径
if [ -z "$ANDROID_NDK" ]; then
    # 尝试常见的 NDK 路径
    if [ -d "$HOME/Library/Android/sdk/ndk" ]; then
        # macOS/Linux 常见路径
        NDK_VERSION=$(ls -1 "$HOME/Library/Android/sdk/ndk" | head -1)
        ANDROID_NDK="$HOME/Library/Android/sdk/ndk/$NDK_VERSION"
    elif [ -d "$HOME/Android/Sdk/ndk" ]; then
        NDK_VERSION=$(ls -1 "$HOME/Android/Sdk/ndk" | head -1)
        ANDROID_NDK="$HOME/Android/Sdk/ndk/$NDK_VERSION"
    elif [ -d "$ANDROID_HOME/ndk" ]; then
        NDK_VERSION=$(ls -1 "$ANDROID_HOME/ndk" | head -1)
        ANDROID_NDK="$ANDROID_HOME/ndk/$NDK_VERSION"
    else
        echo -e "${RED}错误: 未找到 Android NDK${NC}"
        echo "请设置 ANDROID_NDK 环境变量，或确保 NDK 安装在以下位置之一:"
        echo "  - \$HOME/Library/Android/sdk/ndk/<version>"
        echo "  - \$HOME/Android/Sdk/ndk/<version>"
        echo "  - \$ANDROID_HOME/ndk/<version>"
        echo ""
        echo "使用方法:"
        echo "  export ANDROID_NDK=/path/to/ndk"
        echo "  ./build-android.sh"
        exit 1
    fi
fi

if [ ! -d "$ANDROID_NDK" ]; then
    echo -e "${RED}错误: Android NDK 路径不存在: $ANDROID_NDK${NC}"
    exit 1
fi

echo -e "${GREEN}使用 Android NDK: $ANDROID_NDK${NC}"

# 获取 NDK 版本
NDK_VERSION=$(grep -oP 'Pkg\.Revision\s*=\s*\K[0-9.]+' "$ANDROID_NDK/source.properties" 2>/dev/null || echo "unknown")
echo -e "${GREEN}NDK 版本: $NDK_VERSION${NC}"

# 定义支持的 ABI
ABIS=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")

# 如果指定了单个 ABI，只构建该 ABI
if [ "$ANDROID_ABI" != "all" ]; then
    ABIS=("$ANDROID_ABI")
fi

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 创建构建目录
mkdir -p "$BUILD_DIR"
mkdir -p "$INSTALL_DIR"

# 构建函数
build_for_abi() {
    local ABI=$1
    echo -e "\n${YELLOW}========================================${NC}"
    echo -e "${YELLOW}构建 $ABI${NC}"
    echo -e "${YELLOW}========================================${NC}\n"
    
    local ABI_BUILD_DIR="$BUILD_DIR/$ABI"
    local ABI_INSTALL_DIR="$INSTALL_DIR/$ABI"
    
    mkdir -p "$ABI_BUILD_DIR"
    cd "$ABI_BUILD_DIR"
    
    # 配置 CMake
    cmake "$SCRIPT_DIR" \
        -DCMAKE_SYSTEM_NAME=Android \
        -DCMAKE_SYSTEM_VERSION="$ANDROID_PLATFORM" \
        -DCMAKE_ANDROID_ARCH_ABI="$ABI" \
        -DCMAKE_ANDROID_NDK="$ANDROID_NDK" \
        -DCMAKE_ANDROID_STL_TYPE="$ANDROID_STL" \
        -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
        -DCMAKE_INSTALL_PREFIX="$SCRIPT_DIR/$ABI_INSTALL_DIR" \
        -DBUILD_SHARED_LIBS=ON \
        -DENABLE_GTEST=OFF \
        -DENABLE_BENCHMARK=OFF \
        -DBUILD_PYTHON=OFF \
        -DCMAKE_CXX_STANDARD=14 \
        -DCMAKE_CXX_STANDARD_REQUIRED=ON
    
    # 编译
    cmake --build . --config "$BUILD_TYPE" -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
    
    # 安装
    cmake --install . --config "$BUILD_TYPE"
    
    cd "$SCRIPT_DIR"
    
    # 复制 .so 文件到统一目录
    if [ -f "$ABI_INSTALL_DIR/lib/libopencc.so" ]; then
        mkdir -p "$INSTALL_DIR/libs/$ABI"
        cp "$ABI_INSTALL_DIR/lib/libopencc.so" "$INSTALL_DIR/libs/$ABI/libopencc.so"
        echo -e "${GREEN}✓ $ABI 构建完成: $INSTALL_DIR/libs/$ABI/libopencc.so${NC}"
    else
        echo -e "${RED}✗ $ABI 构建失败: 未找到 libopencc.so${NC}"
        return 1
    fi
}

# 构建所有 ABI
for ABI in "${ABIS[@]}"; do
    if ! build_for_abi "$ABI"; then
        echo -e "${RED}构建 $ABI 时出错${NC}"
        exit 1
    fi
done

# 复制数据文件
echo -e "\n${YELLOW}复制数据文件...${NC}"
mkdir -p "$INSTALL_DIR/share/opencc"
cp -r "$SCRIPT_DIR/data/config"/* "$INSTALL_DIR/share/opencc/" 2>/dev/null || true
cp -r "$SCRIPT_DIR/data/dictionary"/*.txt "$INSTALL_DIR/share/opencc/" 2>/dev/null || true
cp -r "$SCRIPT_DIR/data/scheme"/*.txt "$INSTALL_DIR/share/opencc/" 2>/dev/null || true

# 复制头文件
echo -e "${YELLOW}复制头文件...${NC}"
mkdir -p "$INSTALL_DIR/include/opencc"
cp "$SCRIPT_DIR/src/opencc.h" "$INSTALL_DIR/include/opencc/"
cp "$SCRIPT_DIR/src"/*.hpp "$INSTALL_DIR/include/opencc/" 2>/dev/null || true

# 总结
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}构建完成！${NC}"
echo -e "${GREEN}========================================${NC}\n"
echo "输出目录: $INSTALL_DIR"
echo ""
echo "库文件 (.so):"
for ABI in "${ABIS[@]}"; do
    if [ -f "$INSTALL_DIR/libs/$ABI/libopencc.so" ]; then
        echo "  - $INSTALL_DIR/libs/$ABI/libopencc.so"
    fi
done
echo ""
echo "头文件:"
echo "  - $INSTALL_DIR/include/opencc/"
echo ""
echo "数据文件:"
echo "  - $INSTALL_DIR/share/opencc/"
echo ""
echo -e "${YELLOW}使用说明:${NC}"
echo "1. 将 .so 文件复制到 Android 项目的 app/src/main/jniLibs/<abi>/ 目录"
echo "2. 将头文件复制到你的项目中使用"
echo "3. 将配置文件复制到 Android 应用的 assets 目录或合适的位置"
echo ""
echo -e "${GREEN}注意:${NC} libmarisa 是静态库（.a），已被打包进 libopencc.so，"
echo "   你不需要单独处理 libmarisa 文件，只需要 libopencc.so 即可。"
echo ""
echo "示例 Android.mk 或 CMakeLists.txt 配置请参考 README-ANDROID.md"

