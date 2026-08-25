package com.wbq.aicodemother.ai.model;

import dev.langchain4j.model.output.structured.Description;
import lombok.Data;

@Description("根据用户需求生成的应用名称")
@Data
public class AppNameResult {

    @Description("应用名称，3到12个汉字，简洁有辨识度")
    private String appName;
}
