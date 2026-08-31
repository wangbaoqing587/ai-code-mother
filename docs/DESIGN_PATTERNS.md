# ai-code-mother 后端设计模式分析

> 版本：0.0.1-SNAPSHOT  
> 最后更新：2026-08-28  
> 分析范围：`src/main/java/com/wbq/aicodemother`

---

## 目录

1. [概述](#1-概述)
2. [创建型模式](#2-创建型模式)
3. [结构型模式](#3-结构型模式)
4. [行为型模式](#4-行为型模式)
5. [架构与框架模式](#5-架构与框架模式)
6. [模式协作关系](#6-模式协作关系)
7. [模式速查表](#7-模式速查表)

---

## 1. 概述

后端在代码生成、AI 集成、权限控制、工作流编排等模块中，综合运用了 GoF 设计模式与 Spring / LangChain4j 生态中的架构模式。以下分析均结合项目实际代码，说明**在哪里用、为什么用、怎么实现**。

---

## 2. 创建型模式

### 2.1 工厂模式（Factory）

**用途**：按业务上下文（`appId`、`codeGenType`）创建配置不同的 AI 服务实例。

**核心类**：`AiCodeGeneratorServiceFactory`、`AiCodeGenTypeRoutingServiceFactory`、`AiAppNameServiceFactory`

`AiCodeGeneratorServiceFactory` 根据代码生成类型，选择不同 StreamingChatModel 和工具集，通过 LangChain4j 的 `AiServices.builder()` 动态创建代理对象：

```100:118:src/main/java/com/wbq/aicodemother/ai/AiCodeGeneratorServiceFactory.java
        return switch (codeGenType) {
            case VUE_PROJECT -> {
                StreamingChatModel reasoningStreamingChatModel = SpringContextUtil.getBean("reasoningStreamingChatModelPrototype", StreamingChatModel.class);
                yield AiServices.builder(AiCodeGeneratorService.class)
                        .streamingChatModel(reasoningStreamingChatModel)
                        .chatMemoryProvider(memoryId -> chatMemory)
                        .tools(toolManager.getAllTools())
                        .hallucinatedToolNameStrategy(toolExecutionRequest -> ToolExecutionResultMessage.from(
                                toolExecutionRequest, "Error: there is no tool called " + toolExecutionRequest.name()
                        ))
                        .maxToolCallingRoundTrips(20)
                        .inputGuardrails(new PromptSafetyInputGuardrail())
                        .build();
            }
            case HTML, MULTI_FILE -> {
                // ...
            }
        };
```

同类工厂还存在于 `langgraph4j/ai/` 包（`CodeQualityCheckServiceFactory`、`ImageCollectionServiceFactory` 等），统一封装 AI 服务的创建逻辑。

---

### 2.2 建造者模式（Builder）

**用途**：构建复杂对象，避免构造参数过多。

**实现方式一 — Lombok `@Builder`**：工作流状态、图片资源等不可变对象

```22:25:src/main/java/com/wbq/aicodemother/langgraph4j/state/WorkflowContext.java
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WorkflowContext implements Serializable {
```

**实现方式二 — 第三方 Builder API**：LangChain4j / OpenAI 模型配置

```35:48:src/main/java/com/wbq/aicodemother/config/StreamingChatModelConfig.java
    @Bean
    @Scope("prototype")
    public StreamingChatModel streamingChatModelPrototype() {
        return OpenAiStreamingChatModel.builder()
                .apiKey(apiKey)
                .baseUrl(baseUrl)
                .modelName(modelName)
                // ...
                .build();
    }
```

**实现方式三 — 统一响应构建**：`ResultUtils.success()` / `ResultUtils.error()` 封装 `BaseResponse` 构造过程。

---

### 2.3 原型模式（Prototype）

**用途**：流式 AI 模型存在并发状态，不能多个请求共享同一实例。

通过 Spring `@Scope("prototype")` 每次 `getBean` 创建新的 `StreamingChatModel`：

```35:37:src/main/java/com/wbq/aicodemother/config/StreamingChatModelConfig.java
    @Bean
    @Scope("prototype")
    public StreamingChatModel streamingChatModelPrototype() {
```

`ReasoningStreamingChatModelConfig`、`RoutingAiModelConfig` 采用相同策略。`AiCodeGeneratorServiceFactory` 在创建服务时通过 `SpringContextUtil.getBean(...)` 获取原型实例，避免并发串流。

---

### 2.4 单例模式（Singleton）

**用途**：全局唯一实例，减少对象创建开销。

| 实现方式 | 示例 |
|----------|------|
| Spring 默认 Bean 作用域 | `@Service`、`@Component` 标注的 Service / Manager |
| 静态 final 实例 | `CodeParserExecutor` 内 `htmlCodeParser`、`multiFileCodeParser` |
| Caffeine 缓存池 | `AiCodeGeneratorServiceFactory.serviceCache` 按 key 缓存 AI 服务 |

```15:17:src/main/java/com/wbq/aicodemother/core/parser/CodeParserExecutor.java
    private static final HtmlCodeParser htmlCodeParser = new HtmlCodeParser();

    private static final MultiFileCodeParser multiFileCodeParser = new MultiFileCodeParser();
```

Parser / Saver 策略对象无状态，使用静态单例即可；有状态的 AI 模型则使用 Prototype。

---

## 3. 结构型模式

### 3.1 外观模式（Facade）

**用途**：为代码生成子系统提供统一入口，隐藏 Factory、Parser、Saver、Builder 之间的调用细节。

**核心类**：`AiCodeGeneratorFacade`

```78:103:src/main/java/com/wbq/aicodemother/core/AiCodeGeneratorFacade.java
    public Flux<String> generateAndSaveCodeStream(String userMessage, CodeGenTypeEnum codeGenTypeEnum, Long appId) {
        AiCodeGeneratorService aiCodeGeneratorService = aiCodeGeneratorServiceFactory.getAiCodeGeneratorService(appId, codeGenTypeEnum);

        return switch (codeGenTypeEnum) {
            case HTML -> {
                Flux<String> result = aiCodeGeneratorService.generateHtmlCodeStream(userMessage);
                yield processCodeStream(result, CodeGenTypeEnum.HTML, appId);
            }
            case MULTI_FILE -> { /* ... */ }
            case VUE_PROJECT -> {
                TokenStream result = aiCodeGeneratorService.generateVueProjectCodeStream(appId, userMessage);
                yield processTokenStream(result, appId);
            }
            // ...
        };
    }
```

Controller / Service 只需调用 Facade，无需关心各生成类型的内部差异。

---

### 3.2 装饰器模式（Decorator）

**用途**：在不修改 Redis 存储实现的前提下，增强 ChatMemory 的读写行为。

**核心类**：`ValidatingChatMemoryStore`

```10:31:src/main/java/com/wbq/aicodemother/ai/memory/ValidatingChatMemoryStore.java
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
```

在 `RedisChatMemoryStoreConfig` 中装配：

```24:33:src/main/java/com/wbq/aicodemother/config/RedisChatMemoryStoreConfig.java
    @Bean
    public ChatMemoryStore chatMemoryStore() {
        RedisChatMemoryStore redisChatMemoryStore = RedisChatMemoryStore.builder()
                // ...
                .build();
        return new ValidatingChatMemoryStore(redisChatMemoryStore);
    }
```

装饰器在 `getMessages` / `updateMessages` 时过滤无效 `AiMessage`，原始 Redis 存储逻辑不变。

---

### 3.3 代理模式（Proxy）

**用途**：在不修改目标对象的情况下，附加权限校验、限流、AI 调用等横切逻辑。

| 类型 | 实现 | 说明 |
|------|------|------|
| 静态代理 / 动态代理 | LangChain4j `AiServices.builder()` | 为 `AiCodeGeneratorService` 接口生成运行时代理，注入模型、记忆、工具 |
| JDK 动态代理 + AOP | `AuthInterceptor` | `@Around("@annotation(authCheck)")` 拦截管理员接口 |
| AOP 代理 | `RateLimitAspect` | `@Before("@annotation(rateLimit)")` 在方法执行前检查 Redisson 令牌桶 |

权限代理示例：

```32:56:src/main/java/com/wbq/aicodemother/aop/AuthInterceptor.java
    @Around("@annotation(authCheck)")
    public Object doInterceptor(ProceedingJoinPoint joinPoint, AuthCheck authCheck) throws Throwable {
        String mustRole = authCheck.mustRole();
        // ...
        User loginUser = userService.getLoginUser(request);
        // 权限校验
        if (UserRoleEnum.ADMIN.equals(mustRoleEnum) && !UserRoleEnum.ADMIN.equals(userRoleEnum)) {
            throw new BusinessException(ErrorCode.NO_AUTH_ERROR);
        }
        return joinPoint.proceed();
    }
```

---

### 3.4 适配器模式（Adapter）

**用途**：对接外部 SDK / 框架 API，使其符合项目内部调用习惯。

| 适配目标 | 适配类 | 说明 |
|----------|--------|------|
| 腾讯云 COS SDK | `CosManager` | 封装 `putObject` / `uploadFile`，返回统一 URL |
| LangChain4j TokenStream | `AiCodeGeneratorFacade.processTokenStream` | 将 `TokenStream` 回调转为 Reactor `Flux<String>` |
| Selenium WebDriver | `WebScreenshotUtils` | 封装浏览器截图逻辑，供 `ScreenshotServiceImpl` 调用 |

---

## 4. 行为型模式

### 4.1 模板方法模式（Template Method）

**用途**：定义代码保存的固定流程，子类只实现差异化步骤。

**核心类**：`CodeFileSaverTemplate` 及子类 `HtmlCodeFileSaverTemplate`、`MultiFileCodeFileSaverTemplate`

类注释已明确标注为模板方法模式：

```14:40:src/main/java/com/wbq/aicodemother/core/saver/CodeFileSaverTemplate.java
/**
 * 抽象代码文件保存器 - 模板方法模式
 */
public abstract class CodeFileSaverTemplate<T> {

    public final File saveCode(T result, Long appId) {
        validateInput(result);
        String baseDirPath = buildUniqueDir(appId);
        saveFiles(result, baseDirPath);       // 钩子方法，子类实现
        return new File(baseDirPath);
    }

    protected abstract CodeGenTypeEnum getCodeType();
    protected abstract void saveFiles(T result, String baseDirPath);
}
```

**固定步骤**：校验 → 建目录 → 保存文件 → 返回路径  
**可变步骤**：`getCodeType()`、`saveFiles()` 由子类实现

---

### 4.2 策略模式（Strategy）

**用途**：同一操作有多种算法实现，运行时按条件选择。

#### 代码解析策略

```8:16:src/main/java/com/wbq/aicodemother/core/parser/CodeParser.java
public interface CodeParser<T> {
    T parseCode(String codeContent);
}
```

- `HtmlCodeParser` — 解析单文件 HTML
- `MultiFileCodeParser` — 解析 HTML + CSS + JS

#### 流式响应处理策略

`StreamHandlerExecutor` 按 `CodeGenTypeEnum` 选择处理器：

```37:42:src/main/java/com/wbq/aicodemother/core/handler/StreamHandlerExecutor.java
        return switch (codeGenType) {
            case VUE_PROJECT ->
                    jsonMessageStreamHandler.handle(originFlux, chatHistoryService, appId, loginUser);
            case HTML, MULTI_FILE ->
                    new SimpleTextStreamHandler().handle(originFlux, chatHistoryService, appId, loginUser);
        };
```

- `SimpleTextStreamHandler` — 纯文本流，流结束后保存 AI 回复
- `JsonMessageStreamHandler` — JSON 消息流，解析工具调用信息

#### 限流 Key 生成策略

`RateLimitAspect.generateRateLimitKey()` 按 `RateLimitType`（API / USER / IP）生成不同 Redis key。

---

### 4.3 执行器 / 分发器模式（Strategy + Facade 变体）

**用途**：封装「选择策略 + 调用策略」的逻辑，简化调用方代码。

| 执行器 | 分发依据 | 目标策略 |
|--------|----------|----------|
| `CodeParserExecutor` | `CodeGenTypeEnum` | `HtmlCodeParser` / `MultiFileCodeParser` |
| `CodeFileSaverExecutor` | `CodeGenTypeEnum` | `HtmlCodeFileSaverTemplate` / `MultiFileCodeFileSaverTemplate` |
| `StreamHandlerExecutor` | `CodeGenTypeEnum` | `SimpleTextStreamHandler` / `JsonMessageStreamHandler` |

```26:31:src/main/java/com/wbq/aicodemother/core/parser/CodeParserExecutor.java
    public static Object executeParser(String codeContent, CodeGenTypeEnum codeGenType) {
        return switch (codeGenType) {
            case HTML -> htmlCodeParser.parseCode(codeContent);
            case MULTI_FILE -> multiFileCodeParser.parseCode(codeContent);
            default -> throw new BusinessException(ErrorCode.SYSTEM_ERROR, "不支持的代码生成类型: " + codeGenType);
        };
    }
```

---

### 4.4 状态模式（State）

**用途**：应用在不同生成阶段具有不同行为约束。

**核心枚举**：`AppGenStatusEnum`（idle / generating / failed）

`AppServiceImpl.chatToGenCode()` 在生成前检查状态，生成中拒绝重复请求，完成后更新状态：

```96:115:src/main/java/com/wbq/aicodemother/service/impl/AppServiceImpl.java
        if (AppGenStatusEnum.GENERATING.getValue().equals(app.getGenStatus())) {
            throw new BusinessException(ErrorCode.OPERATION_ERROR, "应用正在生成中，请稍后再试");
        }
        // ...
        updateGenStatus(appId, AppGenStatusEnum.GENERATING);
        // ...
        Flux<String> executedFlux = streamHandlerExecutor.doExecute(...)
                .doOnComplete(() -> updateGenStatus(appId, AppGenStatusEnum.IDLE))
                .doOnError(error -> updateGenStatus(appId, AppGenStatusEnum.FAILED));
```

LangGraph4j 工作流中 `WorkflowContext` 作为状态载体，在节点间传递，`routeAfterQualityCheck` 根据质检结果决定下一节点（重试 / 构建 / 结束），属于**状态机**层面的状态模式。

---

### 4.5 观察者模式（Observer）— 响应式变体

**用途**：流式 AI 输出时，在数据到达 / 流完成 / 出错时触发副作用。

Reactor `Flux` 的 `doOnNext` / `doOnComplete` / `doOnError` 替代传统 Observer 接口：

```148:165:src/main/java/com/wbq/aicodemother/core/AiCodeGeneratorFacade.java
    private Flux<String> processCodeStream(Flux<String> codeStream, CodeGenTypeEnum codeGenType, Long appId) {
        StringBuilder codeBuilder = new StringBuilder();
        return codeStream.doOnNext(chunk -> {
            codeBuilder.append(chunk);
        }).doOnComplete(() -> {
            String completeCode = codeBuilder.toString();
            Object parsedResult = CodeParserExecutor.executeParser(completeCode, codeGenType);
            File savedDir = CodeFileSaverExecutor.executeSaver(parsedResult, codeGenType, appId);
        });
    }
```

`AppServiceImpl` 使用 `ConnectableFlux.publish().connect()` 创建热流，保证多个订阅者共享同一流的生命周期。

---

### 4.6 注册表模式（Registry）

**用途**：统一管理 AI 工具，支持按名称查找。

**核心类**：`ToolManager`

```33:39:src/main/java/com/wbq/aicodemother/ai/tools/ToolManager.java
    @PostConstruct
    public void initTools() {
        for (BaseTool tool : tools) {
            toolMap.put(tool.getToolName(), tool);
        }
    }
```

Spring 自动注入所有 `BaseTool` 子类（`FileWriteTool`、`FileReadTool` 等），`@PostConstruct` 注册到 Map，`AiCodeGeneratorServiceFactory` 通过 `getAllTools()` 一次性交给 LangChain4j。

---

### 4.7 模板方法 + 抽象基类（工具层）

**核心类**：`BaseTool` 及 6 个子类

```9:40:src/main/java/com/wbq/aicodemother/ai/tools/BaseTool.java
public abstract class BaseTool {
    public abstract String getToolName();
    public abstract String getDisplayName();
    public String generateToolRequestResponse() {
        return String.format("\n\n[选择工具] %s\n\n", getDisplayName());
    }
    public abstract String generateToolExecutedResult(JSONObject arguments);
}
```

`generateToolRequestResponse()` 为公共实现，子类只需实现工具名和执行结果格式化，与模板方法思想一致。

---

### 4.8 护轨 / 拦截链（Guardrail Chain）

**用途**：在 AI 调用链路中插入输入校验，类似责任链的前置拦截。

**核心类**：`PromptSafetyInputGuardrail`、`RetryOutputGuardrail`

```28:52:src/main/java/com/wbq/aicodemother/ai/guardrail/PromptSafetyInputGuardrail.java
    @Override
    public InputGuardrailResult validate(UserMessage userMessage) {
        String input = userMessage.singleText();
        if (input.length() > 1000) {
            return fatal("输入内容过长，不要超过 1000 字");
        }
        // 敏感词 / 注入攻击检测
        return success();
    }
```

通过 Factory 中 `.inputGuardrails(new PromptSafetyInputGuardrail())` 挂载到 AI 服务调用链。

---

## 5. 架构与框架模式

### 5.1 分层架构（Layered Architecture）

```
Controller → Service → Mapper / Manager / Facade
```

典型调用链：

```
AppController.chatToGenCode()
  → AppServiceImpl.chatToGenCode()
    → AiCodeGeneratorFacade.generateAndSaveCodeStream()
      → AiCodeGeneratorServiceFactory.getAiCodeGeneratorService()
```

各层职责清晰：Controller 处理 HTTP，Service 处理业务规则，Facade / Factory 处理 AI 编排，Mapper 处理持久化。

---

### 5.2 仓储模式（Repository）

MyBatis-Flex 的 `BaseMapper` + `ServiceImpl` 组合实现仓储抽象：

```java
public interface AppMapper extends BaseMapper<App> { }
public class AppServiceImpl extends ServiceImpl<AppMapper, App> implements AppService { }
```

Service 层对外暴露业务语义方法（`createApp`、`deployApp`），底层 CRUD 由 `ServiceImpl` 代理到 Mapper。

---

### 5.2 DTO / VO / Entity 分层

| 层次 | 包路径 | 职责 |
|------|--------|------|
| Entity | `model/entity/` | 数据库表映射（`App`、`User`、`ChatHistory`） |
| DTO | `model/dto/` | 请求参数（`AppAddRequest`、`AppQueryRequest`） |
| VO | `model/vo/` | 响应视图（`AppVO`、`LoginUserVO`，可聚合关联对象） |

Controller 接收 DTO，Service 操作 Entity，返回 VO，避免数据库结构直接暴露给前端。

---

### 5.3 依赖注入（Dependency Injection）

Spring IoC 容器管理所有组件生命周期。典型注入方式：

- `@Resource` — Controller / Service 注入
- `@Configuration` + `@Bean` — 第三方组件（Redis、COS、AI 模型）
- `@ConfigurationProperties` — 配置绑定（`StreamingChatModelConfig`、`CosClientConfig`）

---

### 5.4 服务定位器（Service Locator）

**核心类**：`SpringContextUtil`

LangGraph4j 节点（`CodeGeneratorNode`、`RouterNode` 等）由框架实例化，无法直接使用 `@Resource` 注入，通过 `SpringContextUtil.getBean()` 获取 Spring Bean：

```java
AiCodeGeneratorFacade codeGeneratorFacade = SpringContextUtil.getBean(AiCodeGeneratorFacade.class);
```

这是对 DI 的补充，用于非 Spring 管理的执行上下文。

---

### 5.5 AOP + 自定义注解

| 注解 | 切面 | 作用 |
|------|------|------|
| `@AuthCheck(mustRole = "admin")` | `AuthInterceptor` | 管理员权限校验 |
| `@RateLimit(limitType = USER, rate = 3, rateInterval = 60)` | `RateLimitAspect` | 分布式限流 |

声明式编程：业务 Controller 只需加注解，横切逻辑由切面统一处理。

---

### 5.6 统一异常处理

**核心类**：`GlobalExceptionHandler`、`BusinessException`、`ThrowUtils`

```23:31:src/main/java/com/wbq/aicodemother/exception/GlobalExceptionHandler.java
    @ExceptionHandler(BusinessException.class)
    public BaseResponse<?> businessExceptionHandler(BusinessException e) {
        if (handleSseError(e.getCode(), e.getMessage())) {
            return null;
        }
        return ResultUtils.error(e.getCode(), e.getMessage());
    }
```

对普通 REST 请求返回 JSON；对 SSE 请求（`/chat/gen/code`）写入 `event: business-error` 事件，避免破坏流式协议。

---

### 5.7 缓存模式

| 层级 | 实现 | 说明 |
|------|------|------|
| 本地缓存 | Caffeine（`AiCodeGeneratorServiceFactory.serviceCache`） | 缓存 AI 服务实例 |
| 分布式缓存 | Spring `@Cacheable` + Redis（`AppController.listGoodAppVOByPage`） | 精选应用列表 |
| 主动失效 | `CacheEvictor.evictAppListPageCaches()` | 应用增删改时清理精选/广场缓存 |

---

### 5.8 Manager 模式

**核心类**：`CosManager`

封装第三方 SDK 调用细节（上传、URL 生成），Service 层只关心业务语义：

```java
String cosUrl = cosManager.uploadFile(cosKey, screenshotFile);
```

---

### 5.9 LangGraph 工作流模式

#### 状态机 / 工作流图

`CodeGenWorkflow` 用 `MessagesStateGraph` 定义节点与条件边：

```50:57:src/main/java/com/wbq/aicodemother/langgraph4j/CodeGenWorkflow.java
                    .addConditionalEdges("code_quality_check",
                            edge_async(this::routeAfterQualityCheck),
                            Map.of(
                                    "build", "project_builder",
                                    "skip_build", END,
                                    "fail", "code_generator"
                            ))
```

- 质检失败 → 回到 `code_generator` 重试
- 质检通过 + HTML/MULTI_FILE → 直接结束
- 质检通过 + VUE_PROJECT → 进入 `project_builder`

#### 扇出 / 扇入（Fan-out / Fan-in）

`CodeGenConcurrentWorkflow` 中 `image_plan` 同时触发 4 个图片收集节点，再汇聚到 `ImageAggregatorNode`：

```
image_plan ─┬→ content_image_collector ─┐
            ├→ illustration_collector ──┤
            ├→ diagram_collector ────────┼→ image_aggregator → ...
            └→ logo_collector ───────────┘
```

#### 命令式节点（Command-like Node）

每个节点提供 `static create()` 返回 `AsyncNodeAction`，封装单一职责步骤（路由、增强 Prompt、生成代码、质检、构建），注册到状态图。

---

### 5.10 并行模式（CompletableFuture）

`AppServiceImpl.createApp()` 并行执行 AI 命名与类型路由：

```138:152:src/main/java/com/wbq/aicodemother/service/impl/AppServiceImpl.java
        CompletableFuture<String> appNameFuture = CompletableFuture.supplyAsync(() -> {
            AiAppNameService aiAppNameService = aiAppNameServiceFactory.createAiAppNameService();
            // ...
        });
        CompletableFuture<CodeGenTypeEnum> codeGenTypeFuture = CompletableFuture.supplyAsync(() -> {
            AiCodeGenTypeRoutingService routingService = aiCodeGenTypeRoutingServiceFactory.createAiCodeGenTypeRoutingService();
            return routingService.routeCodeGenType(initPrompt);
        });
        String appName = appNameFuture.join();
        CodeGenTypeEnum selectedCodeGenType = codeGenTypeFuture.join();
```

两个独立 AI 调用并行执行，缩短创建应用耗时。

---

## 6. 模式协作关系

以一次 **VUE_PROJECT 代码生成请求** 为例，各模式如何协作：

```mermaid
flowchart TB
    subgraph Controller
        AC[AppController<br/>@RateLimit 限流]
    end

    subgraph Service
        AS[AppServiceImpl<br/>状态模式 genStatus]
    end

    subgraph Core
        F[Facade<br/>AiCodeGeneratorFacade]
        SE[StreamHandlerExecutor<br/>策略模式]
        VP[VueProjectBuilder]
    end

    subgraph AI
        Factory[AiCodeGeneratorServiceFactory<br/>工厂 + 缓存]
        Proxy[AiServices 动态代理]
        Tools[ToolManager 注册表]
        Guard[PromptSafetyInputGuardrail]
        Memory[ValidatingChatMemoryStore 装饰器]
    end

    AC -->|AOP 代理| AS
    AS --> F
    F --> Factory
    Factory --> Proxy
    Proxy --> Tools
    Proxy --> Guard
    Factory --> Memory
    F --> SE
    SE --> VP
```

**调用顺序**：

1. `@RateLimit`（AOP 代理）检查令牌
2. `AppServiceImpl` 检查 `genStatus`（状态模式），更新为 generating
3. `AiCodeGeneratorFacade`（外观）统一调度
4. `AiCodeGeneratorServiceFactory`（工厂 + 原型 + 缓存）创建 AI 服务
5. LangChain4j 代理（代理模式）调用 LLM + 工具（注册表模式）
6. `ValidatingChatMemoryStore`（装饰器）过滤记忆
7. `StreamHandlerExecutor`（策略）处理流式响应并保存历史
8. `VueProjectBuilder` 同步构建项目
9. 更新 `genStatus` 为 idle / failed

---

## 7. 模式速查表

| 模式 | 分类 | 核心类 | 包路径 |
|------|------|--------|--------|
| 工厂 | 创建型 | `AiCodeGeneratorServiceFactory` | `ai/` |
| 建造者 | 创建型 | `WorkflowContext`、`OpenAiStreamingChatModel.builder()` | 多处 |
| 原型 | 创建型 | `StreamingChatModelConfig`（prototype Bean） | `config/` |
| 单例 | 创建型 | Spring Bean、`CodeParserExecutor` 静态实例 | 全局 |
| 外观 | 结构型 | `AiCodeGeneratorFacade` | `core/` |
| 装饰器 | 结构型 | `ValidatingChatMemoryStore` | `ai/memory/` |
| 代理 | 结构型 | `AuthInterceptor`、`RateLimitAspect`、LangChain4j AiServices | `aop/`、`ratelimit/`、`ai/` |
| 适配器 | 结构型 | `CosManager`、`processTokenStream` | `manager/`、`core/` |
| 模板方法 | 行为型 | `CodeFileSaverTemplate` | `core/saver/` |
| 策略 | 行为型 | `CodeParser`、`StreamHandlerExecutor` | `core/parser/`、`core/handler/` |
| 状态 | 行为型 | `AppGenStatusEnum`、`WorkflowContext` | `model/enums/`、`langgraph4j/` |
| 观察者 | 行为型 | Reactor `Flux.doOnNext/doOnComplete` | `core/`、`service/` |
| 注册表 | 行为型 | `ToolManager` | `ai/tools/` |
| 护轨链 | 行为型 | `PromptSafetyInputGuardrail` | `ai/guardrail/` |
| 仓储 | 架构 | `AppMapper` + `AppServiceImpl` | `mapper/`、`service/` |
| DTO/VO | 架构 | `AppAddRequest`、`AppVO` | `model/` |
| AOP + 注解 | 架构 | `@AuthCheck`、`@RateLimit` | `aop/`、`ratelimit/` |
| 状态机 | 架构 | `CodeGenWorkflow` | `langgraph4j/` |
| 扇出扇入 | 架构 | `CodeGenConcurrentWorkflow` | `langgraph4j/` |
| Manager | 架构 | `CosManager` | `manager/` |
| 服务定位器 | 架构 | `SpringContextUtil` | `utils/` |

---

## 附：未采用或弱体现的模式

| 模式 | 说明 |
|------|------|
| 经典责任链 | 无独立 Handler 链类；AOP / Guardrail 为框架级链式拦截 |
| 访问者 | 未使用 |
| 备忘录 | 未使用；对话历史由 DB + Redis 持久化替代 |
| 享元 | 未显式使用；Caffeine 缓存 AI 服务实例有类似效果 |
| 手写单例 | 无 `getInstance()` 实现，依赖 Spring 容器 |

---

*文档基于代码静态分析，代码变更时请同步更新。*
