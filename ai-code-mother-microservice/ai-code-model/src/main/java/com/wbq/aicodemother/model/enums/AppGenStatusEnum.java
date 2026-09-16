package com.wbq.aicodemother.model.enums;

import cn.hutool.core.util.ObjUtil;
import lombok.Getter;

@Getter
public enum AppGenStatusEnum {

    IDLE("空闲", "idle"),
    GENERATING("生成中", "generating"),
    FAILED("失败", "failed");

    private final String text;
    private final String value;

    AppGenStatusEnum(String text, String value) {
        this.text = text;
        this.value = value;
    }

    public static AppGenStatusEnum getEnumByValue(String value) {
        if (ObjUtil.isEmpty(value)) {
            return null;
        }
        for (AppGenStatusEnum anEnum : AppGenStatusEnum.values()) {
            if (anEnum.value.equals(value)) {
                return anEnum;
            }
        }
        return null;
    }
}
