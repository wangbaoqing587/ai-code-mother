package com.wbq.aicodemother.config;

import dev.langchain4j.http.client.HttpClientBuilder;
import dev.langchain4j.http.client.jdk.JdkHttpClient;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;


@Configuration
public class LangChain4jHttpClientConfig {

    /**
     * 覆盖 Spring Boot starter 默认的 openAiChatModelHttpClientBuilder，
     * 让 ChatModel 走 JDK HttpClient，而不是默认的 Spring RestClient。
     */
    @Bean(name = "openAiChatModelHttpClientBuilder")
    public HttpClientBuilder openAiChatModelHttpClientBuilder() {
        return JdkHttpClient.builder();
    }
}
