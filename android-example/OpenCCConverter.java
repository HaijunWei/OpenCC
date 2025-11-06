package com.example.opencc;

/**
 * OpenCC Android Java 封装类示例
 */
public class OpenCCConverter {
    
    static {
        System.loadLibrary("opencc");
        System.loadLibrary("opencc_example");  // 你的 JNI 库名称
    }
    
    /**
     * 执行转换
     * @param input 输入文本
     * @param config 配置文件名称（如 "s2t.json", "t2s.json"）
     * @return 转换后的文本
     */
    public native String convert(String input, String config);
    
    /**
     * 简体转繁体
     * @param input 简体中文文本
     * @return 繁体中文文本
     */
    public native String convertS2T(String input);
    
    /**
     * 繁体转简体
     * @param input 繁体中文文本
     * @return 简体中文文本
     */
    public native String convertT2S(String input);
    
    // 使用示例
    public static void main(String[] args) {
        OpenCCConverter converter = new OpenCCConverter();
        
        // 简体转繁体
        String result = converter.convertS2T("简体中文");
        System.out.println(result);  // 输出: 簡體中文
        
        // 繁体转简体
        result = converter.convertT2S("繁體中文");
        System.out.println(result);  // 输出: 繁体中文
    }
}

