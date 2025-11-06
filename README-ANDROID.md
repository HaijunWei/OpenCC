# OpenCC Android 构建指南

本指南说明如何将 OpenCC 编译为 Android 可用的 .so 库文件。

## 前置要求

1. **Android NDK**: 需要安装 Android NDK（推荐 r21 或更高版本）
2. **CMake**: 需要 CMake 3.5 或更高版本
3. **编译工具**: 在 macOS/Linux 上需要标准编译工具链

## 快速开始

### 1. 设置 Android NDK 路径

```bash
# 方法 1: 设置环境变量
export ANDROID_NDK=/path/to/your/ndk

# 方法 2: 脚本会自动查找以下路径:
# - $HOME/Library/Android/sdk/ndk/<version> (macOS)
# - $HOME/Android/Sdk/ndk/<version> (Linux)
# - $ANDROID_HOME/ndk/<version>
```

### 2. 运行构建脚本

```bash
# 构建所有 ABI (armeabi-v7a, arm64-v8a, x86, x86_64)
chmod +x build-android.sh
./build-android.sh

# 或构建特定 ABI
ANDROID_ABI=arm64-v8a ./build-android.sh
```

### 3. 构建结果

构建完成后，文件将位于 `install-android/` 目录：

```
install-android/
├── libs/
│   ├── armeabi-v7a/
│   │   └── libopencc.so
│   ├── arm64-v8a/
│   │   └── libopencc.so
│   ├── x86/
│   │   └── libopencc.so
│   └── x86_64/
│       └── libopencc.so
├── include/
│   └── opencc/
│       └── opencc.h (以及其他头文件)
└── share/
    └── opencc/
        └── (配置文件和数据文件)
```

## 在 Android 项目中使用

### 方法 1: 使用 CMake (推荐)

在你的 Android 项目的 `app/build.gradle` 中：

```gradle
android {
    // ...
    defaultConfig {
        // ...
        externalNativeBuild {
            cmake {
                cppFlags "-std=c++14"
                abiFilters "armeabi-v7a", "arm64-v8a", "x86", "x86_64"
            }
        }
    }
    
    externalNativeBuild {
        cmake {
            path "src/main/cpp/CMakeLists.txt"
        }
    }
}
```

在 `app/src/main/cpp/CMakeLists.txt` 中：

```cmake
cmake_minimum_required(VERSION 3.5)
project(yourapp)

# 设置 OpenCC 路径（根据你的实际路径调整）
set(OPENCC_ROOT ${CMAKE_SOURCE_DIR}/../../../opencc-install-android)

# 添加 OpenCC 头文件目录
include_directories(${OPENCC_ROOT}/include)

# 添加你的源文件
add_library(yourlib SHARED
    your_source.cpp
)

# 链接 OpenCC 库
target_link_libraries(yourlib
    ${OPENCC_ROOT}/libs/${ANDROID_ABI}/libopencc.so
)
```

### 方法 2: 使用 JNI 直接加载

1. 将 `.so` 文件复制到 `app/src/main/jniLibs/<abi>/` 目录
2. 将配置文件复制到 `app/src/main/assets/` 目录
3. 在 Java/Kotlin 代码中加载库：

```java
static {
    System.loadLibrary("opencc");
}
```

4. 使用 JNI 调用 OpenCC 的 C API（参考 `src/opencc.h`）

### 方法 3: 使用 Android.mk

在 `app/src/main/jni/Android.mk` 中：

```makefile
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := opencc
LOCAL_SRC_FILES := $(OPENCC_ROOT)/libs/$(TARGET_ARCH_ABI)/libopencc.so
include $(PREBUILT_SHARED_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE := yourlib
LOCAL_SRC_FILES := your_source.cpp
LOCAL_C_INCLUDES := $(OPENCC_ROOT)/include
LOCAL_SHARED_LIBRARIES := opencc
include $(BUILD_SHARED_LIBRARY)
```

## 使用 OpenCC C API 示例

```c
#include "opencc.h"
#include <jni.h>
#include <string.h>

JNIEXPORT jstring JNICALL
Java_com_example_yourapp_MainActivity_convert(JNIEnv *env, jobject thiz, jstring input) {
    // 打开转换器（配置文件路径需要根据实际情况调整）
    opencc_t cc = opencc_open("s2t.json");
    if (cc == (opencc_t) -1) {
        return NULL;
    }
    
    // 获取输入字符串
    const char *inputStr = env->GetStringUTFChars(input, NULL);
    
    // 转换
    char *output = opencc_convert_utf8(cc, inputStr, strlen(inputStr));
    
    // 释放输入字符串
    env->ReleaseStringUTFChars(input, inputStr);
    
    // 创建 Java 字符串
    jstring result = env->NewStringUTF(output);
    
    // 释放输出字符串
    opencc_convert_utf8_free(output);
    
    // 关闭转换器
    opencc_close(cc);
    
    return result;
}
```

## 配置文件说明

OpenCC 的配置文件位于 `data/config/` 目录，常用的配置包括：

- `s2t.json`: 简体到繁体
- `t2s.json`: 繁体到简体
- `s2tw.json`: 简体到台湾繁体
- `tw2s.json`: 台湾繁体到简体
- `s2hk.json`: 简体到香港繁体
- `hk2s.json`: 香港繁体到简体

## 高级选项

### 自定义构建选项

```bash
# 构建 Debug 版本
BUILD_TYPE=Debug ./build-android.sh

# 指定 Android API Level
ANDROID_PLATFORM=23 ./build-android.sh

# 只构建特定 ABI
ANDROID_ABI=arm64-v8a ./build-android.sh

# 使用共享 C++ 标准库（不推荐，需要额外打包 libc++_shared.so）
ANDROID_STL=c++_shared ./build-android.sh
```

### 手动使用 CMake 构建

如果脚本不满足需求，可以手动使用 CMake：

```bash
mkdir build-android
cd build-android

cmake .. \
    -DCMAKE_SYSTEM_NAME=Android \
    -DCMAKE_SYSTEM_VERSION=21 \
    -DCMAKE_ANDROID_ARCH_ABI=arm64-v8a \
    -DCMAKE_ANDROID_NDK=/path/to/ndk \
    -DCMAKE_ANDROID_STL_TYPE=c++_static \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DENABLE_GTEST=OFF \
    -DENABLE_BENCHMARK=OFF \
    -DBUILD_PYTHON=OFF

cmake --build . -j$(nproc)
cmake --install . --prefix ../install-android/arm64-v8a
```

## 常见问题

### Q: libmarisa 编译出来是 .a 文件，Android 能用吗？
A: **完全可以！** 这是正确的行为。marisa 被编译为静态库（.a），然后会被静态链接到 `libopencc.so` 中。这意味着：
- ✅ `libmarisa.a` 的代码会被打包进 `libopencc.so`
- ✅ Android 应用中**只需要 `libopencc.so`**，不需要单独的 `libmarisa.so`
- ✅ 这是 Android 开发中的标准做法，避免了多个 .so 文件的依赖问题
- ✅ 静态链接还可以减少最终 APK 的大小

### Q: 运行时错误 "dlopen failed: library 'libc++_shared.so' not found"？
A: 这是因为使用了 `c++_shared` STL 类型。解决方案有两种：

**方案 1（推荐）：使用静态链接 C++ 标准库**
```bash
# 重新编译，使用 c++_static（默认已启用）
./build-android.sh
```

**方案 2：打包 libc++_shared.so 到 APK**
如果必须使用 `c++_shared`，需要将 `libc++_shared.so` 复制到你的 Android 项目：
```bash
# 从 NDK 复制 libc++_shared.so
cp $ANDROID_NDK/sources/cxx-stl/llvm-libc++/libs/<abi>/libc++_shared.so \
   app/src/main/jniLibs/<abi>/
```

**推荐使用方案 1**，因为：
- ✅ 不需要额外的运行时依赖
- ✅ 减少 APK 大小
- ✅ 避免版本冲突问题

### Q: 找不到 Android NDK？
A: 确保设置了 `ANDROID_NDK` 环境变量，或安装 NDK 在标准位置。

### Q: 编译错误 "undefined reference"？
A: 确保链接了 `libopencc.so`，并且使用了正确的 ABI 架构。

### Q: 运行时找不到配置文件？
A: 确保将配置文件复制到 Android 应用的 assets 目录或可访问的文件系统位置，并在代码中使用正确的路径。

### Q: 如何减小 .so 文件大小？
A: 可以使用 `strip` 工具：
```bash
$ANDROID_NDK/toolchains/llvm/prebuilt/*/bin/llvm-strip libopencc.so
```

## 许可证

OpenCC 使用 Apache License 2.0 许可证。

