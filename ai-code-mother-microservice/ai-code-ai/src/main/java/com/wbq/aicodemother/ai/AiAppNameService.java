package com.wbq.aicodemother.ai;

import com.wbq.aicodemother.ai.model.AppNameResult;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;

public interface AiAppNameService {

    @SystemMessage(fromResource = "prompt/app-name-system-prompt.txt")
    AppNameResult generateAppName(@UserMessage String userPrompt);
}
