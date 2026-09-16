package com.wbq.aicodemother.model.enums;

import cn.hutool.core.util.ObjUtil;
import lombok.Getter;

@Getter
public enum AppVisibilityEnum {

    PLAZA("广场可见", "plaza"),
    PRIVATE("仅自己可见", "private");

    private final String text;
    private final String value;

    AppVisibilityEnum(String text, String value) {
        this.text = text;
        this.value = value;
    }

    public static AppVisibilityEnum getEnumByValue(String value) {
        if (ObjUtil.isEmpty(value)) {
            return null;
        }
        for (AppVisibilityEnum anEnum : AppVisibilityEnum.values()) {
            if (anEnum.value.equals(value)) {
                return anEnum;
            }
        }
        return null;
    }
}
