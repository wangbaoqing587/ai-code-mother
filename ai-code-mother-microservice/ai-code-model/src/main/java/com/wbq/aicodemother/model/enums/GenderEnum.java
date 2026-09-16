package com.wbq.aicodemother.model.enums;

import lombok.Getter;

@Getter
public enum GenderEnum {

    FEMALE("女", 0),
    MALE("男", 1);

    private final String text;

    private final Integer value;

    GenderEnum(String text, Integer value) {
        this.text = text;
        this.value = value;
    }

    public static GenderEnum getEnumByValue(Integer value) {
        if (value == null) {
            return null;
        }
        for (GenderEnum anEnum : GenderEnum.values()) {
            if (anEnum.value.equals(value)) {
                return anEnum;
            }
        }
        return null;
    }
}
