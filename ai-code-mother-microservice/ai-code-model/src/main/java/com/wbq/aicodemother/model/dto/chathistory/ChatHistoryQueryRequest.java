package com.wbq.aicodemother.model.dto.chathistory;

import com.wbq.aicodemother.common.PageRequest;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.io.Serializable;
import java.time.LocalDateTime;

@EqualsAndHashCode(callSuper = true)
@Data
public class ChatHistoryQueryRequest extends PageRequest implements Serializable {

    private Long id;

    private String message;

    private String messageType;

    private Long appId;

    private Long userId;

    /**
     * 游标查询 - 最后一条记录的创建时间
     * 用于分页查询，从该时间开始查询
     *
     */
    private LocalDateTime lastCreateTime;

    private static final long serialVersionUID = 1L;
}
