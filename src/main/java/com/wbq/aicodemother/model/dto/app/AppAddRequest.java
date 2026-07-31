package com.wbq.aicodemother.model.dto.app;

import lombok.Data;

import java.io.Serializable;

@Data
public class AppAddRequest implements Serializable {

    /**
     * 应用初始化的 prompt
     */
    private String initPrompt;

    /**
     * 应用名称
     */
    private String appName;

    private static final long serialVersionUID = 1L;
}
