package com.wbq.aicodemother.model.dto.app;

import com.wbq.aicodemother.common.PageRequest;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.io.Serializable;
import java.time.LocalDateTime;

@Data
@EqualsAndHashCode(callSuper = true)
public class AppCommentQueryRequest extends PageRequest implements Serializable {

    private Long id;

    private Long appId;

    private Long userId;

    private String content;

    private LocalDateTime lastCreateTime;

    private static final long serialVersionUID = 1L;
}
