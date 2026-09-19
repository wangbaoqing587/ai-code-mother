package com.wbq.aicodemother.ai;

import com.wbq.aicodemother.utils.SpringContextUtil;
import dev.langchain4j.model.chat.ChatModel;
import dev.langchain4j.service.AiServices;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class AiAppNameServiceFactory {

    public AiAppNameService createAiAppNameService() {
        ChatModel chatModel = SpringContextUtil.getBean("routingChatModelPrototype", ChatModel.class);
        return AiServices.builder(AiAppNameService.class)
                .chatModel(chatModel)
                .build();
    }

    @Bean
    public AiAppNameService aiAppNameService() {
        return createAiAppNameService();
    }
}
