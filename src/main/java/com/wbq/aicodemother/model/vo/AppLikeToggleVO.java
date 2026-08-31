package com.wbq.aicodemother.model.vo;

import lombok.Data;

import java.io.Serializable;

@Data
public class AppLikeToggleVO implements Serializable {

    private Boolean liked;

    private Long likeCount;

    private static final long serialVersionUID = 1L;
}
