package com.wbq.aicodemother.model.dto.app;

import lombok.Data;

import java.io.Serializable;

@Data
public class AppCommentAddRequest implements Serializable {

    private Long appId;

    private String content;

    private static final long serialVersionUID = 1L;
}
