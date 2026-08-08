export const GOOD_APP_PRIORITY = 99

export const MY_APP_PAGE_SIZE = 6

export const GOOD_APP_PAGE_SIZE = 6

export interface QuickPromptItem {
  label: string
  prompt: string
}

export const QUICK_PROMPTS: QuickPromptItem[] = [
  {
    label: '个人博客',
    prompt:
      '帮我创建一个简洁现代的个人博客网站，首页展示最新文章列表和作者简介，支持按分类与标签筛选，文章详情页带目录导航与相关推荐，配色清爽，适配手机与电脑，并预留关于我和联系方式入口。',
  },
  {
    label: '企业官网',
    prompt:
      '请生成一个科技公司企业官网，包含首页 Banner、产品服务介绍、核心优势、客户案例与联系我们模块，导航清晰，视觉偏蓝白科技风，支持响应式布局，按钮与卡片有轻微悬停动效，适合对外展示品牌与业务能力。',
  },
  {
    label: '作品集',
    prompt:
      '帮我做一个设计师个人作品集网站，首页用大图展示代表项目，作品详情页含项目背景、设计过程与效果图轮播，风格极简留白，突出视觉作品本身，并提供简历下载与联系表单，方便潜在客户了解能力并预约合作。',
  },
  {
    label: '在线课程',
    prompt:
      '请创建一个轻量级在线课程介绍站，首页突出热门课程卡片，含课程封面、简介、适合人群与报名按钮，另设讲师介绍与常见问题答疑区，整体清新教育风，移动端友好，方便学员快速浏览课程并完成意向报名。',
  },
]
