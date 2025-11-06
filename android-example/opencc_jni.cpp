/**
 * OpenCC Android JNI 示例
 * 演示如何在 Android 中使用 OpenCC
 */

#include <jni.h>
#include <string>
#include "opencc.h"

extern "C" {

/**
 * 简繁体转换示例
 * Java 方法签名: public native String convert(String input, String config);
 */
JNIEXPORT jstring JNICALL
Java_com_example_opencc_OpenCCConverter_convert(JNIEnv *env, jobject thiz,
                                                 jstring input,
                                                 jstring config) {
    // 获取配置文件名
    const char *configStr = env->GetStringUTFChars(config, NULL);
    if (configStr == NULL) {
        return NULL;
    }

    // 打开 OpenCC 转换器
    opencc_t cc = opencc_open(configStr);
    env->ReleaseStringUTFChars(config, configStr);

    if (cc == (opencc_t) -1) {
        // 打开失败，返回错误信息
        const char *error = opencc_error();
        return env->NewStringUTF(error ? error : "Failed to open converter");
    }

    // 获取输入字符串
    const char *inputStr = env->GetStringUTFChars(input, NULL);
    if (inputStr == NULL) {
        opencc_close(cc);
        return NULL;
    }

    // 执行转换
    char *output = opencc_convert_utf8(cc, inputStr, strlen(inputStr));

    // 释放输入字符串
    env->ReleaseStringUTFChars(input, inputStr);

    // 关闭转换器
    opencc_close(cc);

    if (output == NULL) {
        const char *error = opencc_error();
        return env->NewStringUTF(error ? error : "Conversion failed");
    }

    // 创建 Java 字符串
    jstring result = env->NewStringUTF(output);

    // 释放输出字符串
    opencc_convert_utf8_free(output);

    return result;
}

/**
 * 简体到繁体转换（使用默认配置）
 */
JNIEXPORT jstring JNICALL
Java_com_example_opencc_OpenCCConverter_convertS2T(JNIEnv *env, jobject thiz,
                                                    jstring input) {
    jstring config = env->NewStringUTF("s2t.json");
    jstring result = Java_com_example_opencc_OpenCCConverter_convert(env, thiz, input, config);
    env->DeleteLocalRef(config);
    return result;
}

/**
 * 繁体到简体转换（使用默认配置）
 */
JNIEXPORT jstring JNICALL
Java_com_example_opencc_OpenCCConverter_convertT2S(JNIEnv *env, jobject thiz,
                                                    jstring input) {
    jstring config = env->NewStringUTF("t2s.json");
    jstring result = Java_com_example_opencc_OpenCCConverter_convert(env, thiz, input, config);
    env->DeleteLocalRef(config);
    return result;
}

} // extern "C"

