package com.wbq.aicodemother.model.dto.app;

import lombok.Data;

import java.io.Serializable;

@Data
public class AppUpdateRequest implements Serializable {

    /**
     * id
     */
    private Long id;

    /**
     * 应用名称
     */
    private String appName;

    /**
     * 可见范围：plaza/private
     */
    private String visibility;

    private static final long serialVersionUID = 1L;
}
