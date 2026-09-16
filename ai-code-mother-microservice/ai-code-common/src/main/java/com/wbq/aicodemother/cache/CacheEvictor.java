package com.wbq.aicodemother.cache;

import com.wbq.aicodemother.constant.AppConstant;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.Cache;
import org.springframework.cache.CacheManager;
import org.springframework.stereotype.Component;

@Component
@Slf4j
public class CacheEvictor {

    @Resource
    private CacheManager cacheManager;

    /**
     * 清理精选应用与应用广场分页缓存
     */
    public void evictAppListPageCaches() {
        Cache goodAppCache = cacheManager.getCache(AppConstant.GOOD_APP_PAGE_CACHE);
        if (goodAppCache == null) {
            log.warn("缓存 {} 不存在，跳过清理", AppConstant.GOOD_APP_PAGE_CACHE);
        } else {
            goodAppCache.clear();
        }
        Cache plazaCache = cacheManager.getCache(AppConstant.PLAZA_APP_PAGE_CACHE);
        if (plazaCache == null) {
            log.warn("缓存 {} 不存在，跳过清理", AppConstant.PLAZA_APP_PAGE_CACHE);
        } else {
            plazaCache.clear();
        }
    }
}
