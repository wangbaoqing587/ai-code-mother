package com.wbq.aicodemother.model.dto.app;

import lombok.Data;

import java.io.Serializable;

@Data
public class AppLikeToggleRequest implements Serializable {

    private Long appId;

    private static final long serialVersionUID = 1L;
}
