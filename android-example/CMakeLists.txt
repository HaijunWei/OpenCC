# OpenCC Android 示例 CMakeLists.txt
# 此文件展示如何在 Android 项目中使用已编译的 OpenCC 库

cmake_minimum_required(VERSION 3.5)

project(opencc_example)

# 设置 C++ 标准
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 设置 OpenCC 安装路径（根据你的实际路径调整）
# 假设你已经将编译好的 OpenCC 文件复制到了项目的 jniLibs 目录
set(OPENCC_ROOT ${CMAKE_SOURCE_DIR}/../install-android)

# 添加 OpenCC 头文件目录
include_directories(${OPENCC_ROOT}/include)

# 添加你的源文件
add_library(opencc_example SHARED
    opencc_jni.cpp
)

# 链接 OpenCC 库
# 注意：这里使用相对路径，实际使用时需要根据你的项目结构调整
target_link_libraries(opencc_example
    ${OPENCC_ROOT}/libs/${ANDROID_ABI}/libopencc.so
)

# 如果需要链接其他库（如 log）
find_library(log-lib log)
target_link_libraries(opencc_example ${log-lib})

