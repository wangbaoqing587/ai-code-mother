package com.wbq.aicodemother.service;

import com.mybatisflex.core.query.QueryWrapper;
import com.mybatisflex.core.service.IService;
import com.wbq.aicodemother.model.dto.app.AppQueryRequest;
import com.wbq.aicodemother.model.entity.App;
import com.wbq.aicodemother.model.entity.User;
import com.wbq.aicodemother.model.vo.AppVO;
import reactor.core.publisher.Flux;

import java.util.List;

/**
 * 应用 服务层。
 *
 * @author <a href="https://github.com/wangbaoqing587">王包青</a>
 */
public interface AppService extends IService<App> {

    /**
     * 获取应用封装
     *
     * @param app 应用
     * @return 应用封装
     */
    AppVO getAppVO(App app);

    /**
     * 获取应用封装列表
     *
     * @param appList 应用列表
     * @return 应用封装列表
     */
    List<AppVO> getAppVOList(List<App> appList);

    /**
     * 根据查询条件构造查询参数
     *
     * @param appQueryRequest 查询请求
     * @return 查询条件
     */
    QueryWrapper getQueryWrapper(AppQueryRequest appQueryRequest);

    /**
     * 通过对话生成应用代码
     *
     * @param appId 应用id
     * @param message 提示词
     * @param loginUser 登录用户
     * @return
     */
    Flux<String> chatToGenCode(Long appId, String message, User loginUser);

    /**
     * 部署应用
     *
     * @param appId
     * @param loginUser
     * @return
     */
    String deployApp(Long appId, User loginUser);
}
