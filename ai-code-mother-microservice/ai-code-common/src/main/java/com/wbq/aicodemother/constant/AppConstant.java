package com.wbq.aicodemother.constant;

public interface AppConstant {

    static String tmpRootDir() {
        String fromEnv = System.getenv("AI_CODE_TMP_ROOT");
        if (fromEnv != null && !fromEnv.isBlank()) {
            return fromEnv.trim();
        }
        return System.getProperty("user.dir") + "/tmp";
    }

    /**
     * 精选应用列表缓存名
     */
    String GOOD_APP_PAGE_CACHE = "good_app_page";

    /**
     * 应用广场列表缓存名
     */
    String PLAZA_APP_PAGE_CACHE = "plaza_app_page";

    /**
     * 精选应用的优先级
     */
    Integer GOOD_APP_PRIORITY = 99;

    /**
     * 默认应用优先级
     */
    Integer DEFAULT_APP_PRIORITY = 1;

    /**
     * 应用生成目录
     */
    String CODE_OUTPUT_ROOT_DIR = tmpRootDir() + "/code_output";

    /**
     * 应用部署目录
     */
    String CODE_DEPLOY_ROOT_DIR = tmpRootDir() + "/code_deploy";

    /**
     * 应用部署域名
     */
    String CODE_DEPLOY_HOST = "http://localhost:8080";

}
