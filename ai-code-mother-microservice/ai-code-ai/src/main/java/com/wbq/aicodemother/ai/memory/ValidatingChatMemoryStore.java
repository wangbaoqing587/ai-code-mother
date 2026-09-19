package com.wbq.aicodemother.ai.memory;

import cn.hutool.core.util.StrUtil;
import dev.langchain4j.data.message.AiMessage;
import dev.langchain4j.data.message.ChatMessage;
import dev.langchain4j.store.memory.chat.ChatMemoryStore;

import java.util.List;

public class ValidatingChatMemoryStore implements ChatMemoryStore {

    private final ChatMemoryStore delegate;

    public ValidatingChatMemoryStore(ChatMemoryStore delegate) {
        this.delegate = delegate;
    }

    @Override
    public List<ChatMessage> getMessages(Object memoryId) {
        return filter(delegate.getMessages(memoryId));
    }

    @Override
    public void updateMessages(Object memoryId, List<ChatMessage> messages) {
        delegate.updateMessages(memoryId, filter(messages));
    }

    @Override
    public void deleteMessages(Object memoryId) {
        delegate.deleteMessages(memoryId);
    }

    private static List<ChatMessage> filter(List<ChatMessage> messages) {
        return messages.stream().filter(msg -> !isInvalidAiMessage(msg)).toList();
    }

    private static boolean isInvalidAiMessage(ChatMessage message) {
        if (!(message instanceof AiMessage aiMessage)) {
            return false;
        }
        return StrUtil.isBlank(aiMessage.text()) && !aiMessage.hasToolExecutionRequests();
    }
}
