package com.wbq.aicodemother.mapper;

import com.mybatisflex.core.BaseMapper;
import com.wbq.aicodemother.model.entity.App;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 应用 映射层。
 *
 * @author <a href="https://github.com/wangbaoqing587">王包青</a>
 */
public interface AppMapper extends BaseMapper<App> {

    long countAllApps();

    List<App> selectAppPlazaPage(@Param("offset") long offset, @Param("pageSize") long pageSize);
}
