package com.wbq.aicodemother.utils;

import cn.hutool.crypto.digest.DigestUtil;
import cn.hutool.json.JSONUtil;

/**
 * 缓存 key 生成工具类
 *
 * @author yupi
 */
public class CacheKeyUtils {

    /**
     * 根据对象生成缓存key (JSON + MD5)
     *
     * @param obj 要生成key的对象
     * @return MD5哈希后的缓存key
     */
    public static String generateKey(Object obj) {
        if (obj == null) {
            return DigestUtil.md5Hex("null");
        }
        // 先转JSON，再MD5
        String jsonStr = JSONUtil.toJsonStr(obj);
        return DigestUtil.md5Hex(jsonStr);
    }

    /**
     * 应用列表分页缓存 key（区分登录用户，避免 hasLiked 串数据）
     */
    public static String generateGoodAppPageKey(Object appQueryRequest, Long loginUserId) {
        String userSuffix = loginUserId == null ? "guest" : String.valueOf(loginUserId);
        return generateKey(appQueryRequest) + ":" + userSuffix;
    }
}
