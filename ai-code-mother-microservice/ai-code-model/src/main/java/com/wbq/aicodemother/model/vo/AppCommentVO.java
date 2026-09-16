package com.wbq.aicodemother.model.vo;

import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

@Data
public class AppCommentVO implements Serializable {

    private Long id;

    private Long appId;

    private Long userId;

    private String content;

    private LocalDateTime createTime;

    private UserVO user;

    private static final long serialVersionUID = 1L;
}
