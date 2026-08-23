# Starvive — 星衍 Flutter 客户端

星衍 AI 零代码应用生成平台的移动端客户端，对接现有 Spring Boot 后端，实现与 Web 前端一致的核心功能（不含可视化编辑）。

## 功能清单

| 模块 | 功能 |
|------|------|
| 首页 | 提示词创建应用、快捷提示词、我的作品、精选案例 |
| 认证 | 登录、注册、退出、Session Cookie 持久化 |
| 对话 | SSE 流式生成、历史消息分页、自动发送 initPrompt |
| 预览 | WebView 内嵌预览、外链打开、生成后自动刷新 |
| 应用 | 部署、下载代码 zip、应用详情、编辑、删除 |
| 用户 | 个人信息查看与编辑（头像本地上传压缩） |
| 管理后台 | 用户管理、应用管理、对话管理（管理员） |

## 技术架构

```
lib/
├── main.dart                 # 入口
├── app.dart                  # MaterialApp + 启动初始化
├── config/
│   ├── env.dart              # API / 部署域名 / 预览 URL
│   ├── theme.dart            # 薄荷绿主题（对齐 Web）
│   └── router.dart           # go_router 路由与权限守卫
├── core/
│   ├── constants/            # 业务常量、颜色、资源路径
│   ├── network/
│   │   ├── api_client.dart   # Dio + CookieJar + SSE
│   │   └── base_response.dart
│   └── utils/                # 格式化、文件保存
├── models/models.dart        # LoginUser / AppVO / ChatHistory 等
├── services/services.dart    # User / App / ChatHistory API
├── providers/providers.dart  # Riverpod 状态（认证）
├── widgets/                  # 通用 UI 组件
└── pages/                    # 页面
```

### 架构模式

- **分层**：Presentation（pages/widgets）→ State（Riverpod）→ Service → Network
- **路由**：`go_router` + `ShellRoute` 统一顶栏布局
- **状态**：`flutter_riverpod`，认证状态全局 `authProvider`
- **网络**：`dio` + `PersistCookieJar` 维持 Redis Session
- **流式**：自定义 SSE 解析（携带 Cookie），数据格式 `{"d":"chunk"}` + `event: done`
- **预览**：`webview_flutter` 加载 `/api/static/{type}_{appId}/`

### 与后端接口

| 能力 | 端点 |
|------|------|
| 登录 | `POST /user/login` |
| 创建应用 | `POST /app/add` |
| 流式生成 | `GET /app/chat/gen/code?appId=&message=` (SSE) |
| 聊天历史 | `GET /chatHistory/app/{appId}` |
| 预览 | `GET /static/{codeGenType}_{appId}/` |
| 部署 | `POST /app/deploy` |
| 下载 | `GET /app/download/{appId}` |

默认 API 地址：

- iOS 模拟器 / macOS / Web：`http://localhost:8123/api`
- Android 模拟器：`http://10.0.2.2:8123/api`

部署预览域名默认：`http://localhost`（端口 8080）

## 环境要求

- Flutter SDK >= 3.11
- Dart >= 3.11
- 后端 `ai-code-mother` 已启动（默认 `8123`，context-path `/api`）
- 真机调试需将 `lib/config/env.dart` 中 `apiBaseUrl` 改为本机局域网 IP

## 快速开始

```bash
# 1. 启动后端（项目根目录）
./mvnw spring-boot:run

# 2. 安装依赖
cd Starvive
flutter pub get

# 3. 运行（示例：iOS 模拟器）
flutter run

# 4. 指定 API 地址（真机）
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8123/api
```

如需通过 `--dart-define` 覆盖配置，在 `main.dart` 中可扩展：

```dart
const apiFromDefine = String.fromEnvironment('API_BASE_URL');
if (apiFromDefine.isNotEmpty) configureEnv(apiUrl: apiFromDefine);
```

## 页面路由

| 路径 | 页面 | 权限 |
|------|------|------|
| `/` | 首页 | 公开 |
| `/user/login` | 登录 | 公开 |
| `/user/register` | 注册 | 公开 |
| `/user/info` | 个人信息 | 登录 |
| `/app/chat/:id` | 对话 + 预览 | 登录 |
| `/app/edit/:id` | 应用编辑 | 登录 + Owner/Admin |
| `/admin/userManage` | 用户管理 | 管理员 |
| `/admin/appManage` | 应用管理 | 管理员 |
| `/admin/chatManage` | 对话管理 | 管理员 |
| `/401` | 无权限 | 公开 |

## 移动端适配说明

- **聊天页**：宽屏左右分栏（对话 + 预览），窄屏 Tab 切换
- **可视化编辑**：未实现（按需求排除）
- **封面/头像**：本地上传后压缩为 base64（与 Web 一致）
- **下载**：zip 保存至应用文档目录并提示路径

## 待确认事项

1. **API 地址配置**：真机/生产环境是否需要独立的配置文件或构建变体（dev/staging/prod）？
2. **部署域名**：移动端访问部署站点时，`deployDomain` 是否统一为公网域名？当前默认 `http://localhost:8080`。
3. **长消息 SSE**：当前使用 GET 传 `message`，极长提示词可能触及 URL 长度限制；若遇问题需后端增加 POST SSE 接口。
4. **下载体验**：当前保存到应用私有目录；是否需要系统分享面板或「保存到相册/文件」交互？
5. **应用图标**：当前使用 Flutter 默认图标，是否替换为 `icon_logo.png` 生成各平台图标？

## 依赖

| 包 | 用途 |
|----|------|
| flutter_riverpod | 状态管理 |
| go_router | 路由 |
| dio + cookie_jar | HTTP + Session |
| webview_flutter | 网页预览 |
| flutter_markdown | AI 消息渲染 |
| image_picker + image | 头像/封面上传压缩 |
| url_launcher | 外链打开 |

## 构建

```bash
flutter build apk --release
flutter build ios --release
flutter build macos --release
```

---

星衍 — 以灵感为星，衍万千应用
