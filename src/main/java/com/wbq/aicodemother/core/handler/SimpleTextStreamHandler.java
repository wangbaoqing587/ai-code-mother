package com.wbq.aicodemother.core.handler;

import cn.hutool.core.util.StrUtil;
import com.wbq.aicodemother.model.entity.User;
import com.wbq.aicodemother.model.enums.ChatHistoryMessageTypeEnum;
import com.wbq.aicodemother.service.ChatHistoryService;
import reactor.core.publisher.Flux;

/**
 * 简单文本流处理器
 * 处理 HTML 和 MULTILINE 类型的流式响应
 */
public class SimpleTextStreamHandler {

    /**
     * 处理传统流（HTML，MULTILINE）
     * 直接收集完整的文本响应
     *
     * @param originFlux
     * @param chatHistoryService
     * @param appId
     * @param loginUser
     * @return 处理后的流
     */
    public Flux<String> handle(Flux<String> originFlux,
                               ChatHistoryService chatHistoryService,
                               Long appId,
                               User loginUser) {
        StringBuilder aiResponseBuilder = new StringBuilder();
        return originFlux.map(chunk -> {
                    aiResponseBuilder.append(chunk);
                    return chunk;
                })
                .doOnComplete(() -> {
                    String aiResponse = aiResponseBuilder.toString();
                    if (StrUtil.isNotBlank(aiResponse)) {
                        chatHistoryService.addChatMessage(appId, aiResponse,
                                ChatHistoryMessageTypeEnum.AI.getValue(), loginUser.getId());
                    }
                })
                .doOnError(error -> {
                    String errorMessage = "AI回复失败: " + error.getMessage();
                    chatHistoryService.addChatMessage(appId, errorMessage,
                            ChatHistoryMessageTypeEnum.AI.getValue(), loginUser.getId());
                });
    }
}
