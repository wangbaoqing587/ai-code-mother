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

    public void evictGoodAppPage() {
        Cache cache = cacheManager.getCache(AppConstant.GOOD_APP_PAGE_CACHE);
        if (cache == null) {
            log.warn("缓存 {} 不存在，跳过清理", AppConstant.GOOD_APP_PAGE_CACHE);
            return;
        }
        cache.clear();
    }
}
