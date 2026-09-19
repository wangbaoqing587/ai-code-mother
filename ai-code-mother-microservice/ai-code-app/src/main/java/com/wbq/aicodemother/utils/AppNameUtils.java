package com.wbq.aicodemother.utils;

import cn.hutool.core.util.StrUtil;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

public final class AppNameUtils {

    private static final int MIN_LEN = 3;
    private static final int MAX_LEN = 12;

    private static final Pattern CHINESE_CHAR_PATTERN = Pattern.compile("[\\u4e00-\\u9fff]");

    private AppNameUtils() {
    }

    public static String sanitize(String raw) {
        if (StrUtil.isBlank(raw)) {
            return null;
        }
        Matcher matcher = CHINESE_CHAR_PATTERN.matcher(raw.trim());
        StringBuilder builder = new StringBuilder();
        while (matcher.find()) {
            builder.append(matcher.group());
        }
        String result = builder.toString();
        if (result.length() < MIN_LEN) {
            return null;
        }
        if (result.length() > MAX_LEN) {
            return result.substring(0, MAX_LEN);
        }
        return result;
    }

    public static String fallbackFromPrompt(String initPrompt) {
        String sanitized = sanitize(initPrompt);
        if (StrUtil.isNotBlank(sanitized)) {
            return sanitized;
        }
        String trimmed = initPrompt.trim();
        return trimmed.substring(0, Math.min(trimmed.length(), MAX_LEN));
    }

    public static String resolveAppName(String initPrompt, String aiName) {
        String sanitized = sanitize(aiName);
        return StrUtil.isNotBlank(sanitized) ? sanitized : fallbackFromPrompt(initPrompt);
    }
}
