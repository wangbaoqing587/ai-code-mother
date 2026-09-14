package com.wbq.aicodemother.utils;

import cn.hutool.core.util.StrUtil;
import cn.hutool.json.JSONUtil;
import com.wbq.aicodemother.exception.BusinessException;
import com.wbq.aicodemother.exception.ErrorCode;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;

public final class AppTagUtils {

    public static final int MAX_TAG_COUNT = 5;
    public static final int MAX_TAG_LENGTH = 20;

    private AppTagUtils() {
    }

    public static List<String> fromJson(String tagsJson) {
        if (StrUtil.isBlank(tagsJson)) {
            return new ArrayList<>();
        }
        try {
            List<String> tags = JSONUtil.toList(tagsJson, String.class);
            return tags == null ? new ArrayList<>() : tags;
        } catch (Exception e) {
            return new ArrayList<>();
        }
    }

    public static String toJson(List<String> tags) {
        if (tags == null) {
            return null;
        }
        return JSONUtil.toJsonStr(normalize(tags));
    }

    public static List<String> normalize(List<String> tags) {
        if (tags == null) {
            return new ArrayList<>();
        }
        LinkedHashSet<String> unique = new LinkedHashSet<>();
        for (String raw : tags) {
            if (StrUtil.isBlank(raw)) {
                continue;
            }
            String tag = raw.trim();
            if (tag.length() > MAX_TAG_LENGTH) {
                throw new BusinessException(ErrorCode.PARAMS_ERROR, "标签长度不能超过" + MAX_TAG_LENGTH + "个字符");
            }
            unique.add(tag);
            if (unique.size() > MAX_TAG_COUNT) {
                throw new BusinessException(ErrorCode.PARAMS_ERROR, "最多添加" + MAX_TAG_COUNT + "个标签");
            }
        }
        return new ArrayList<>(unique);
    }
}
