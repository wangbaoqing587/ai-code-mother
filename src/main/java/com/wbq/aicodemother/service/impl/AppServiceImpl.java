package com.wbq.aicodemother.service.impl;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.io.FileUtil;
import cn.hutool.core.util.RandomUtil;
import cn.hutool.core.util.StrUtil;
import com.mybatisflex.core.paginate.Page;
import com.mybatisflex.core.query.QueryWrapper;
import com.mybatisflex.spring.service.impl.ServiceImpl;
import com.wbq.aicodemother.ai.AiAppNameService;
import com.wbq.aicodemother.ai.AiAppNameServiceFactory;
import com.wbq.aicodemother.ai.AiCodeGenTypeRoutingService;
import com.wbq.aicodemother.ai.AiCodeGenTypeRoutingServiceFactory;
import com.wbq.aicodemother.ai.model.AppNameResult;
import com.wbq.aicodemother.utils.AppNameUtils;
import com.wbq.aicodemother.cache.CacheEvictor;
import com.wbq.aicodemother.constant.AppConstant;
import com.wbq.aicodemother.constant.UserConstant;
import com.wbq.aicodemother.core.AiCodeGeneratorFacade;
import com.wbq.aicodemother.core.handler.StreamHandlerExecutor;
import com.wbq.aicodemother.exception.BusinessException;
import com.wbq.aicodemother.exception.ErrorCode;
import com.wbq.aicodemother.exception.ThrowUtils;
import com.wbq.aicodemother.mapper.AppCommentMapper;
import com.wbq.aicodemother.mapper.AppLikeMapper;
import com.wbq.aicodemother.mapper.AppMapper;
import com.wbq.aicodemother.model.dto.app.AppAddRequest;
import com.wbq.aicodemother.model.dto.app.AppCommentQueryRequest;
import com.wbq.aicodemother.model.dto.app.AppQueryRequest;
import com.wbq.aicodemother.model.entity.App;
import com.wbq.aicodemother.model.entity.AppComment;
import com.wbq.aicodemother.model.entity.AppLike;
import com.wbq.aicodemother.model.entity.User;
import com.wbq.aicodemother.model.enums.AppGenStatusEnum;
import com.wbq.aicodemother.model.enums.ChatHistoryMessageTypeEnum;
import com.wbq.aicodemother.model.enums.CodeGenTypeEnum;
import com.wbq.aicodemother.model.vo.AppCommentVO;
import com.wbq.aicodemother.model.vo.AppLikeToggleVO;
import com.wbq.aicodemother.model.vo.AppVO;
import com.wbq.aicodemother.model.vo.UserVO;
import com.wbq.aicodemother.service.AppService;
import com.wbq.aicodemother.service.ChatHistoryService;
import com.wbq.aicodemother.service.ScreenshotService;
import com.wbq.aicodemother.service.UserService;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import reactor.core.publisher.ConnectableFlux;
import reactor.core.publisher.Flux;

import java.io.File;
import java.io.Serializable;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.stream.Collectors;

/**
 * 应用 服务层实现。
 *
 * @author <a href="https://github.com/wangbaoqing587">王包青</a>
 */
@Service
@Slf4j
public class AppServiceImpl extends ServiceImpl<AppMapper, App> implements AppService {

    @Resource
    private UserService userService;

    @Resource
    private AiCodeGeneratorFacade aiCodeGeneratorFacade;

    @Resource
    private ChatHistoryService chatHistoryService;

    @Resource
    private StreamHandlerExecutor streamHandlerExecutor;

    @Resource
    private ScreenshotService screenshotService;

    @Resource
    private AiCodeGenTypeRoutingServiceFactory aiCodeGenTypeRoutingServiceFactory;

    @Resource
    private AiAppNameServiceFactory aiAppNameServiceFactory;

    @Resource
    private CacheEvictor cacheEvictor;

    @Resource
    private AppLikeMapper appLikeMapper;

    @Resource
    private AppCommentMapper appCommentMapper;

    @Override
    public Flux<String> chatToGenCode(Long appId, String message, User loginUser) {
        // 1.参数校验
        ThrowUtils.throwIf(appId == null || appId <= 0, ErrorCode.PARAMS_ERROR, "应用ID错误");
        ThrowUtils.throwIf(StrUtil.isBlank(message), ErrorCode.PARAMS_ERROR, "提示词为空错误");
        // 2.查询应用信息
        App app = getById(appId);
        ThrowUtils.throwIf(app == null, ErrorCode.NOT_FOUND_ERROR, "应用不存在");
        // 3.权限校验，仅本人可以和自己的应用对话
        if (!app.getUserId().equals(loginUser.getId())) {
            throw new BusinessException(ErrorCode.NO_AUTH_ERROR, "无权限访问该应用");
        }
        if (AppGenStatusEnum.GENERATING.getValue().equals(app.getGenStatus())) {
            throw new BusinessException(ErrorCode.OPERATION_ERROR, "应用正在生成中，请稍后再试");
        }
        // 4.获取应用的代码生成类型
        String codeGenType = app.getCodeGenType();
        CodeGenTypeEnum codeGenTypeEnum = CodeGenTypeEnum.getEnumByValue(codeGenType);
        if (codeGenTypeEnum == null) {
            throw new BusinessException(ErrorCode.PARAMS_ERROR, "应用代码生成类型错误");
        }
        // 5.在调用AI前，添加用户消息到对话历史
        chatHistoryService.addChatMessage(appId, message, ChatHistoryMessageTypeEnum.USER.getValue(), loginUser.getId());
        updateGenStatus(appId, AppGenStatusEnum.GENERATING);
        // 6.调用AI生成代码
        Flux<String> codeStream = aiCodeGeneratorFacade.generateAndSaveCodeStream(message, codeGenTypeEnum, appId);
        // 7.收集AI响应的内容，并且在完成后保存记录到对话历史
        // 增加超时限制和应用状态设置
        Flux<String> executedFlux = streamHandlerExecutor.doExecute(codeStream, chatHistoryService, appId, loginUser, codeGenTypeEnum)
                .timeout(Duration.ofMinutes(5))
                .doOnComplete(() -> updateGenStatus(appId, AppGenStatusEnum.IDLE))
                .doOnError(error -> updateGenStatus(appId, AppGenStatusEnum.FAILED));
        ConnectableFlux<String> connectableFlux = executedFlux.publish();
        connectableFlux.connect();
        return connectableFlux;
    }

    private void updateGenStatus(Long appId, AppGenStatusEnum genStatus) {
        log.warn("更新应用生成状态，appId: {}, genStatus: {}", appId, genStatus.getValue());
        App updateApp = new App();
        updateApp.setId(appId);
        updateApp.setGenStatus(genStatus.getValue());
        boolean updated = this.updateById(updateApp);
        if (!updated) {
            log.warn("更新应用生成状态失败，appId: {}, genStatus: {}", appId, genStatus.getValue());
        }
    }

    @Override
    public Long createApp(AppAddRequest appAddRequest, User loginUser) {
        // 参数校验
        String initPrompt = appAddRequest.getInitPrompt();
        ThrowUtils.throwIf(StrUtil.isBlank(initPrompt), ErrorCode.PARAMS_ERROR, "初始化 prompt 不能为空");
        // app命名任务 与 选择代码生成类型 任务并行
        CompletableFuture<String> appNameFuture = CompletableFuture.supplyAsync(() -> {
            try {
                AiAppNameService aiAppNameService = aiAppNameServiceFactory.createAiAppNameService();
                AppNameResult appNameResult = aiAppNameService.generateAppName(initPrompt);
                String aiAppName = appNameResult != null ? appNameResult.getAppName() : null;
                return AppNameUtils.resolveAppName(initPrompt, aiAppName);
            } catch (Exception e) {
                log.warn("AI 生成应用名失败: {}", e.getMessage());
                return AppNameUtils.fallbackFromPrompt(initPrompt);
            }
        });
        CompletableFuture<CodeGenTypeEnum> codeGenTypeFuture = CompletableFuture.supplyAsync(() -> {
            AiCodeGenTypeRoutingService aiCodeGenTypeRoutingService = aiCodeGenTypeRoutingServiceFactory.createAiCodeGenTypeRoutingService();
            return aiCodeGenTypeRoutingService.routeCodeGenType(initPrompt);
        });
        String appName = appNameFuture.join();
        CodeGenTypeEnum selectedCodeGenType = codeGenTypeFuture.join();
        App app = new App();
        BeanUtil.copyProperties(appAddRequest, app);
        app.setUserId(loginUser.getId());
        app.setAppName(appName);
        app.setCodeGenType(selectedCodeGenType.getValue());
        app.setGenStatus(AppGenStatusEnum.IDLE.getValue());
        // 插入数据库
        boolean result = this.save(app);
        ThrowUtils.throwIf(!result, ErrorCode.OPERATION_ERROR);
        cacheEvictor.evictAppListPageCaches();
        log.info("应用创建成功，ID: {}, 名称: {}, 类型: {}", app.getId(), appName, selectedCodeGenType.getValue());
        return app.getId();
    }

    /**
     * 删除应用时，同时删除关联的对话历史、点赞和评论
     *
     * @param id 数据主键
     * @return
     */
    @Override
    public boolean removeById(Serializable id) {
        if (id == null) {
            return false;
        }
        long appId = Long.parseLong(id.toString());
        if (appId <= 0) {
            return false;
        }
        // 先删除应用关联的对话历史
        try {
            chatHistoryService.deleteByAppId(appId);
        } catch (Exception e) {
            log.error("删除应用关联的对话历史失败：{}", e.getMessage());
        }
        try {
            deleteLikesByAppId(appId);
        } catch (Exception e) {
            log.error("删除应用关联的点赞失败：{}", e.getMessage());
        }
        try {
            deleteCommentsByAppId(appId);
        } catch (Exception e) {
            log.error("删除应用关联的评论失败：{}", e.getMessage());
        }
        // 删除应用
        boolean result = super.removeById(id);
        if (result) {
            cacheEvictor.evictAppListPageCaches();
        }
        return result;
    }

    @Override
    public boolean updateById(App entity) {
        boolean result = super.updateById(entity);
        if (result) {
            cacheEvictor.evictAppListPageCaches();
        }
        return result;
    }

    @Override
    public AppVO getAppVO(App app) {
        return getAppVO(app, null);
    }

    @Override
    public AppVO getAppVO(App app, Long loginUserId) {
        if (app == null) {
            return null;
        }
        AppVO appVO = new AppVO();
        BeanUtil.copyProperties(app, appVO);
        Long userId = app.getUserId();
        if (userId != null) {
            User user = userService.getById(userId);
            UserVO userVO = userService.getUserVO(user);
            appVO.setUser(userVO);
        }
        fillAppInteractionStats(Collections.singletonList(appVO), loginUserId);
        return appVO;
    }

    @Override
    public List<AppVO> getAppVOList(List<App> appList) {
        return getAppVOList(appList, null);
    }

    @Override
    public List<AppVO> getAppVOList(List<App> appList, Long loginUserId) {
        if (CollUtil.isEmpty(appList)) {
            return new ArrayList<>();
        }
        Set<Long> userIdSet = appList.stream()
                .map(App::getUserId)
                .collect(Collectors.toSet());
        Map<Long, UserVO> userVOMap = userService.listByIds(userIdSet).stream()
                .collect(Collectors.toMap(User::getId, userService::getUserVO));
        List<AppVO> appVOList = appList.stream().map(app -> {
            AppVO appVO = new AppVO();
            BeanUtil.copyProperties(app, appVO);
            appVO.setUser(userVOMap.get(app.getUserId()));
            return appVO;
        }).collect(Collectors.toList());
        fillAppInteractionStats(appVOList, loginUserId);
        return appVOList;
    }

    private void fillAppInteractionStats(List<AppVO> appVOList, Long loginUserId) {
        if (CollUtil.isEmpty(appVOList)) {
            return;
        }
        List<Long> appIds = appVOList.stream()
                .map(AppVO::getId)
                .filter(Objects::nonNull)
                .collect(Collectors.toList());
        if (CollUtil.isEmpty(appIds)) {
            return;
        }
        try {
            Map<Long, Long> likeCountMap = countLikesByAppIds(appIds);
            Map<Long, Long> commentCountMap = countCommentsByAppIds(appIds);
            Set<Long> likedAppIds = getLikedAppIds(appIds, loginUserId);
            for (AppVO appVO : appVOList) {
                Long appId = appVO.getId();
                appVO.setLikeCount(likeCountMap.getOrDefault(appId, 0L));
                appVO.setCommentCount(commentCountMap.getOrDefault(appId, 0L));
                appVO.setHasLiked(likedAppIds.contains(appId));
            }
        } catch (Exception e) {
            log.error("填充应用互动统计失败：{}", e.getMessage());
            for (AppVO appVO : appVOList) {
                appVO.setLikeCount(0L);
                appVO.setCommentCount(0L);
                appVO.setHasLiked(false);
            }
        }
    }

    @Override
    public QueryWrapper getQueryWrapper(AppQueryRequest appQueryRequest) {
        if (appQueryRequest == null) {
            throw new BusinessException(ErrorCode.PARAMS_ERROR, "请求参数为空");
        }
        Long id = appQueryRequest.getId();
        String appName = appQueryRequest.getAppName();
        String cover = appQueryRequest.getCover();
        String initPrompt = appQueryRequest.getInitPrompt();
        String codeGenType = appQueryRequest.getCodeGenType();
        String deployKey = appQueryRequest.getDeployKey();
        Integer priority = appQueryRequest.getPriority();
        Long userId = appQueryRequest.getUserId();
        String sortField = appQueryRequest.getSortField();
        String sortOrder = appQueryRequest.getSortOrder();
        return QueryWrapper.create()
                .eq("id", id)
                .like("appName", appName)
                .like("cover", cover)
                .like("initPrompt", initPrompt)
                .eq("codeGenType", codeGenType)
                .eq("deployKey", deployKey)
                .eq("priority", priority)
                .eq("userId", userId)
                .orderBy(sortField, "ascend".equals(sortOrder));
    }



    @Override
    public String deployApp(Long appId, User loginUser) {
        // 1. 参数校验
        ThrowUtils.throwIf(appId == null || appId <= 0, ErrorCode.PARAMS_ERROR, "应用 ID 不能为空");
        ThrowUtils.throwIf(loginUser == null, ErrorCode.NOT_LOGIN_ERROR, "用户未登录");
        // 2. 查询应用信息
        App app = this.getById(appId);
        ThrowUtils.throwIf(app == null, ErrorCode.NOT_FOUND_ERROR, "应用不存在");
        // 3. 验证用户是否有权限部署该应用，仅本人可以部署
        if (!app.getUserId().equals(loginUser.getId())) {
            throw new BusinessException(ErrorCode.NO_AUTH_ERROR, "无权限部署该应用");
        }
        // 4. 检查是否已有 deployKey
        String deployKey = app.getDeployKey();
        // 没有则生成 6 位 deployKey（大小写字母 + 数字）
        if (StrUtil.isBlank(deployKey)) {
            deployKey = RandomUtil.randomString(6);
        }
        // 5. 获取代码生成类型，构建源目录路径
        String codeGenType = app.getCodeGenType();
        String sourceDirName = codeGenType + "_" + appId;
        String sourceDirPath = AppConstant.CODE_OUTPUT_ROOT_DIR + File.separator + sourceDirName;
        // 6. 检查源目录是否存在
        File sourceDir = new File(sourceDirPath);
        if (!sourceDir.exists() || !sourceDir.isDirectory()) {
            throw new BusinessException(ErrorCode.SYSTEM_ERROR, "应用代码不存在，请先生成代码");
        }
        // 7. 复制文件到部署目录
        String deployDirPath = AppConstant.CODE_DEPLOY_ROOT_DIR + File.separator + deployKey;
        try {
            FileUtil.copyContent(sourceDir, new File(deployDirPath), true);
        } catch (Exception e) {
            throw new BusinessException(ErrorCode.SYSTEM_ERROR, "部署失败：" + e.getMessage());
        }
        // 8. 更新应用的 deployKey 和部署时间
        App updateApp = new App();
        updateApp.setId(appId);
        updateApp.setDeployKey(deployKey);
        updateApp.setDeployedTime(LocalDateTime.now());
        boolean updateResult = this.updateById(updateApp);
        ThrowUtils.throwIf(!updateResult, ErrorCode.OPERATION_ERROR, "更新应用部署信息失败");
        // 10. 构建应用访问 URL
        String appDeployUrl = String.format("%s/%s/", AppConstant.CODE_DEPLOY_HOST, deployKey);
        if (Objects.equals(codeGenType, CodeGenTypeEnum.VUE_PROJECT.getValue())) {
            appDeployUrl += "dist/index.html";
        }
        // 11. 异步生成截图并更新应用封面
        generateAppScreenshotAsync(appId, appDeployUrl);
        return appDeployUrl;

    }

    @Override
    public void generateAppScreenshotAsync(Long appId, String appUrl) {
        // 使用虚拟线程异步执行
        Thread.startVirtualThread(() -> {
            // 调用截图服务生成截图并上传
            String screenshotUrl = screenshotService.generateAndUploadScreenshot(appUrl);
            // 更新应用封面字段
            App updateApp = new App();
            updateApp.setId(appId);
            updateApp.setCover(screenshotUrl);
            boolean updated = this.updateById(updateApp);
            ThrowUtils.throwIf(!updated, ErrorCode.OPERATION_ERROR, "更新应用封面字段失败");
        });
    }

    @Override
    public AppLikeToggleVO toggleLike(Long appId, User loginUser) {
        ThrowUtils.throwIf(appId == null || appId <= 0, ErrorCode.PARAMS_ERROR, "应用ID不能为空");
        ThrowUtils.throwIf(loginUser == null, ErrorCode.NOT_LOGIN_ERROR);
        App app = getById(appId);
        ThrowUtils.throwIf(app == null, ErrorCode.NOT_FOUND_ERROR, "应用不存在");
        Long userId = loginUser.getId();
        QueryWrapper queryWrapper = QueryWrapper.create()
                .eq("appId", appId)
                .eq("userId", userId);
        AppLike existingLike = appLikeMapper.selectOneByQuery(queryWrapper);
        boolean liked;
        if (existingLike != null) {
            appLikeMapper.deleteById(existingLike.getId());
            liked = false;
        } else {
            AppLike appLike = AppLike.builder()
                    .appId(appId)
                    .userId(userId)
                    .build();
            appLikeMapper.insert(appLike);
            liked = true;
        }
        cacheEvictor.evictAppListPageCaches();
        AppLikeToggleVO result = new AppLikeToggleVO();
        result.setLiked(liked);
        result.setLikeCount(countLikesByAppId(appId));
        return result;
    }

    @Override
    public Long addComment(Long appId, String content, User loginUser) {
        ThrowUtils.throwIf(appId == null || appId <= 0, ErrorCode.PARAMS_ERROR, "应用ID不能为空");
        ThrowUtils.throwIf(StrUtil.isBlank(content), ErrorCode.PARAMS_ERROR, "评论内容不能为空");
        ThrowUtils.throwIf(content.length() > 1024, ErrorCode.PARAMS_ERROR, "评论内容过长");
        ThrowUtils.throwIf(loginUser == null, ErrorCode.NOT_LOGIN_ERROR);
        App app = getById(appId);
        ThrowUtils.throwIf(app == null, ErrorCode.NOT_FOUND_ERROR, "应用不存在");
        AppComment appComment = AppComment.builder()
                .appId(appId)
                .userId(loginUser.getId())
                .content(content.trim())
                .build();
        int saved = appCommentMapper.insert(appComment);
        ThrowUtils.throwIf(saved <= 0, ErrorCode.OPERATION_ERROR);
        cacheEvictor.evictAppListPageCaches();
        return appComment.getId();
    }

    @Override
    public boolean deleteComment(Long commentId, User loginUser) {
        ThrowUtils.throwIf(commentId == null || commentId <= 0, ErrorCode.PARAMS_ERROR, "评论ID不能为空");
        ThrowUtils.throwIf(loginUser == null, ErrorCode.NOT_LOGIN_ERROR);
        AppComment oldComment = appCommentMapper.selectOneById(commentId);
        ThrowUtils.throwIf(oldComment == null, ErrorCode.NOT_FOUND_ERROR, "评论不存在");
        boolean isAdmin = UserConstant.ADMIN_ROLE.equals(loginUser.getUserRole());
        if (!oldComment.getUserId().equals(loginUser.getId()) && !isAdmin) {
            throw new BusinessException(ErrorCode.NO_AUTH_ERROR, "无权限删除该评论");
        }
        int removed = appCommentMapper.deleteById(commentId);
        if (removed > 0) {
            cacheEvictor.evictAppListPageCaches();
        }
        return removed > 0;
    }

    @Override
    public Page<AppCommentVO> listAppCommentByPage(Long appId, int pageSize, LocalDateTime lastCreateTime) {
        ThrowUtils.throwIf(appId == null || appId <= 0, ErrorCode.PARAMS_ERROR, "应用ID不能为空");
        ThrowUtils.throwIf(pageSize <= 0 || pageSize > 50, ErrorCode.PARAMS_ERROR, "页面大小必须在1-50之间");
        App app = getById(appId);
        ThrowUtils.throwIf(app == null, ErrorCode.NOT_FOUND_ERROR, "应用不存在");
        AppCommentQueryRequest queryRequest = new AppCommentQueryRequest();
        queryRequest.setAppId(appId);
        queryRequest.setLastCreateTime(lastCreateTime);
        QueryWrapper queryWrapper = getCommentQueryWrapper(queryRequest);
        Page<AppComment> commentPage = appCommentMapper.paginate(Page.of(1, pageSize), queryWrapper);
        Page<AppCommentVO> resultPage = new Page<>(commentPage.getPageNumber(), commentPage.getPageSize(), commentPage.getTotalRow());
        resultPage.setRecords(getAppCommentVOList(commentPage.getRecords()));
        return resultPage;
    }

    @Override
    public Page<AppVO> listAppPlazaVOByPage(AppQueryRequest appQueryRequest, Long loginUserId) {
        ThrowUtils.throwIf(appQueryRequest == null, ErrorCode.PARAMS_ERROR);
        long pageNum = appQueryRequest.getPageNum();
        long pageSize = appQueryRequest.getPageSize();
        ThrowUtils.throwIf(pageNum <= 0 || pageSize <= 0, ErrorCode.PARAMS_ERROR);
        ThrowUtils.throwIf(pageSize > 20, ErrorCode.PARAMS_ERROR);
        long total = mapper.countAllApps();
        long offset = (pageNum - 1) * pageSize;
        List<App> appList = mapper.selectAppPlazaPage(offset, pageSize);
        Page<AppVO> appVOPage = new Page<>(pageNum, pageSize, total);
        appVOPage.setRecords(getAppVOList(appList, loginUserId));
        return appVOPage;
    }

    private long countLikesByAppId(Long appId) {
        if (appId == null || appId <= 0) {
            return 0L;
        }
        return appLikeMapper.selectCountByQuery(QueryWrapper.create().eq("appId", appId));
    }

    private Map<Long, Long> countLikesByAppIds(Collection<Long> appIds) {
        if (CollUtil.isEmpty(appIds)) {
            return Collections.emptyMap();
        }
        List<AppLike> likes = appLikeMapper.selectListByQuery(QueryWrapper.create().in("appId", appIds));
        return likes.stream().collect(Collectors.groupingBy(AppLike::getAppId, Collectors.counting()));
    }

    private Map<Long, Long> countCommentsByAppIds(Collection<Long> appIds) {
        if (CollUtil.isEmpty(appIds)) {
            return Collections.emptyMap();
        }
        List<AppComment> comments = appCommentMapper.selectListByQuery(QueryWrapper.create().in("appId", appIds));
        return comments.stream().collect(Collectors.groupingBy(AppComment::getAppId, Collectors.counting()));
    }

    private Set<Long> getLikedAppIds(Collection<Long> appIds, Long userId) {
        if (CollUtil.isEmpty(appIds) || userId == null || userId <= 0) {
            return Collections.emptySet();
        }
        QueryWrapper queryWrapper = QueryWrapper.create()
                .select("appId")
                .in("appId", appIds)
                .eq("userId", userId);
        return appLikeMapper.selectListByQuery(queryWrapper).stream()
                .map(AppLike::getAppId)
                .collect(Collectors.toSet());
    }

    private void deleteLikesByAppId(Long appId) {
        appLikeMapper.deleteByQuery(QueryWrapper.create().eq("appId", appId));
    }

    private void deleteCommentsByAppId(Long appId) {
        appCommentMapper.deleteByQuery(QueryWrapper.create().eq("appId", appId));
    }

    private List<AppCommentVO> getAppCommentVOList(List<AppComment> commentList) {
        if (CollUtil.isEmpty(commentList)) {
            return new ArrayList<>();
        }
        Set<Long> userIdSet = commentList.stream()
                .map(AppComment::getUserId)
                .collect(Collectors.toSet());
        Map<Long, UserVO> userVOMap = userService.listByIds(userIdSet).stream()
                .collect(Collectors.toMap(User::getId, userService::getUserVO));
        return commentList.stream().map(comment -> {
            AppCommentVO commentVO = new AppCommentVO();
            BeanUtil.copyProperties(comment, commentVO);
            commentVO.setUser(userVOMap.get(comment.getUserId()));
            return commentVO;
        }).collect(Collectors.toList());
    }

    private QueryWrapper getCommentQueryWrapper(AppCommentQueryRequest queryRequest) {
        QueryWrapper queryWrapper = QueryWrapper.create();
        if (queryRequest == null) {
            return queryWrapper;
        }
        Long id = queryRequest.getId();
        Long appId = queryRequest.getAppId();
        Long userId = queryRequest.getUserId();
        String content = queryRequest.getContent();
        LocalDateTime lastCreateTime = queryRequest.getLastCreateTime();
        String sortField = queryRequest.getSortField();
        String sortOrder = queryRequest.getSortOrder();
        queryWrapper.eq("id", id)
                .eq("appId", appId)
                .eq("userId", userId)
                .like("content", content);
        if (lastCreateTime != null) {
            queryWrapper.lt("createTime", lastCreateTime);
        }
        if (StrUtil.isNotBlank(sortField)) {
            queryWrapper.orderBy(sortField, "ascend".equals(sortOrder));
        } else {
            queryWrapper.orderBy("createTime", false);
        }
        return queryWrapper;
    }
}
