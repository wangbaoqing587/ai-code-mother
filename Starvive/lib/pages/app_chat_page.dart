import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:starvive/config/env.dart';
import 'package:starvive/core/constants/app_constants.dart';
import 'package:starvive/core/constants/business_constants.dart';
import 'package:starvive/core/utils/file_utils.dart';
import 'package:starvive/core/utils/format_utils.dart';
import 'package:starvive/models/models.dart';
import 'package:starvive/providers/providers.dart';
import 'package:starvive/widgets/code_gen_type_tag.dart';
import 'package:starvive/widgets/markdown_content.dart';
import 'package:starvive/widgets/prompt_input_box.dart';
import 'package:starvive/widgets/user_avatar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AppChatPage extends ConsumerStatefulWidget {
  const AppChatPage({super.key, required this.appId});

  final String appId;

  @override
  ConsumerState<AppChatPage> createState() => _AppChatPageState();
}

class _AppChatPageState extends ConsumerState<AppChatPage>
    with SingleTickerProviderStateMixin {
  AppVO _appInfo = AppVO();
  List<ChatMessage> _messages = [];
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoadingApp = false;
  bool _isLoadingHistory = false;
  bool _isLoadingMoreHistory = false;
  bool _isGenerating = false;
  bool _isDeploying = false;
  bool _isDownloading = false;
  bool _showPreview = false;
  int _previewKey = 0;
  bool _hasMoreHistory = false;
  int _historyTotal = 0;
  String? _historyCursor;
  StreamSubscription<String>? _streamSub;
  late TabController _tabController;
  WebViewController? _webController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initPage();
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initPage() async {
    _streamSub?.cancel();
    _messages = [];
    _showPreview = false;
    _hasMoreHistory = false;
    _historyTotal = 0;
    _historyCursor = null;
    await _fetchAppInfo();
    await _fetchChatHistory(false);
    _updatePreviewByHistory();

    final auth = ref.read(authProvider).user;
    if (_appInfo.userId == auth.id && _messages.isEmpty && _appInfo.initPrompt != null) {
      await _sendMessage(_appInfo.initPrompt!);
    }
    setState(() {});
  }

  void _updatePreviewByHistory() {
    if (_historyTotal >= 2 && _appInfo.codeGenType != null) {
      _showPreview = true;
    }
  }

  String? get _previewUrl {
    if (_appInfo.codeGenType == null) return null;
    return getStaticPreviewUrl(_appInfo.codeGenType!, widget.appId);
  }

  Future<void> _fetchAppInfo() async {
    setState(() => _isLoadingApp = true);
    try {
      final res = await ref.read(appServiceProvider).getAppVoById(widget.appId);
      if (res.isSuccess && res.data != null) {
        _appInfo = res.data!;
      }
    } finally {
      setState(() => _isLoadingApp = false);
    }
  }

  Future<void> _fetchChatHistory(bool isLoadMore) async {
    if (isLoadMore) {
      if (!_hasMoreHistory || _isLoadingMoreHistory || _historyCursor == null) return;
      setState(() => _isLoadingMoreHistory = true);
    } else {
      setState(() => _isLoadingHistory = true);
    }

    try {
      final res = await ref.read(chatHistoryServiceProvider).listAppChatHistory(
            appId: widget.appId,
            pageSize: chatHistoryPageSize,
            lastCreateTime: isLoadMore ? _historyCursor : null,
          );
      if (res.isSuccess && res.data != null) {
        final records = res.data!.records ?? [];
        _historyTotal = res.data!.totalRow ?? records.length;
        _hasMoreHistory = records.length >= chatHistoryPageSize;
        final mapped = _mapHistory(records);

        if (isLoadMore) {
          final existingIds = _messages.map((m) => m.id).toSet();
          final older = mapped.where((m) => !existingIds.contains(m.id)).toList();
          _messages = [...older, ..._messages];
        } else {
          _messages = mapped;
        }
        _updateHistoryCursor();
      }
    } finally {
      setState(() {
        _isLoadingHistory = false;
        _isLoadingMoreHistory = false;
      });
      _scrollToBottom();
    }
  }

  List<ChatMessage> _mapHistory(List<ChatHistory> records) {
    final sorted = [...records];
    sorted.sort((a, b) {
      final ta = a.createTime != null ? DateTime.tryParse(a.createTime!) : null;
      final tb = b.createTime != null ? DateTime.tryParse(b.createTime!) : null;
      return (ta?.millisecondsSinceEpoch ?? 0) - (tb?.millisecondsSinceEpoch ?? 0);
    });
    return sorted
        .map((item) => ChatMessage(
              id: item.id ?? createMessageId(),
              role: item.isUserMessage ? 'user' : 'ai',
              content: item.message ?? '',
              createTime: item.createTime,
            ))
        .toList();
  }

  void _updateHistoryCursor() {
    final historyMessages = _messages.where((m) => m.createTime != null).toList();
    if (historyMessages.isNotEmpty) {
      _historyCursor = historyMessages.first.createTime;
    }
  }

  Future<void> _scrollToBottom() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  Future<void> _sendMessage(String rawMessage) async {
    final text = rawMessage.trim();
    if (text.isEmpty || _isGenerating) return;

    _messages.add(ChatMessage(id: createMessageId(), role: 'user', content: text));
    final aiIndex = _messages.length;
    _messages.add(ChatMessage(
      id: createMessageId(),
      role: 'ai',
      content: '',
      isStreaming: true,
    ));
    _inputController.clear();
    setState(() {
      _isGenerating = true;
      _showPreview = false;
    });
    await _scrollToBottom();
    await _generateCodeStream(text, aiIndex);
  }

  Future<void> _generateCodeStream(String message, int aiIndex) async {
    _streamSub?.cancel();
    var fullContent = '';

    final stream = ref.read(appServiceProvider).generateCodeStream(
          appId: widget.appId,
          message: message,
        );

    _streamSub = stream.listen(
      (chunk) {
        fullContent += chunk;
        _messages[aiIndex] = ChatMessage(
          id: _messages[aiIndex].id,
          role: 'ai',
          content: fullContent,
          isStreaming: false,
        );
        setState(() {});
        _scrollToBottom();
      },
      onError: (Object e) {
        _messages[aiIndex] = ChatMessage(
          id: _messages[aiIndex].id,
          role: 'ai',
          content: '❌ ${e.toString()}',
          isStreaming: false,
        );
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      },
      onDone: () async {
        setState(() => _isGenerating = false);
        await Future<void>.delayed(const Duration(seconds: 1));
        await _fetchAppInfo();
        if (_appInfo.codeGenType != null) {
          setState(() {
            _showPreview = true;
            _previewKey++;
          });
          _initWebView();
        }
        _scrollToBottom();
      },
    );
  }

  void _initWebView() {
    final url = _previewUrl;
    if (url == null) return;
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url));
  }

  Future<void> _handleDeploy() async {
    setState(() => _isDeploying = true);
    try {
      final res = await ref.read(appServiceProvider).deployApp(widget.appId);
      if (res.isSuccess) {
        await _fetchAppInfo();
        final url = _appInfo.deployKey != null
            ? getDeployUrl(_appInfo.deployKey!, _appInfo.codeGenType)
            : res.data ?? '';
        if (context.mounted) {
          showDialog<void>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('部署成功'),
              content: SelectableText(url),
              actions: [
                TextButton(
                  onPressed: () => launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication),
                  child: const Text('打开链接'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('关闭'),
                ),
              ],
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('部署失败：${res.message ?? '未知错误'}')),
        );
      }
    } finally {
      setState(() => _isDeploying = false);
    }
  }

  Future<void> _handleDownload() async {
    setState(() => _isDownloading = true);
    try {
      final bytes = await ref.read(appServiceProvider).downloadAppCode(widget.appId);
      final path = await saveBytesToFile(
        bytes,
        '${_appInfo.appName ?? widget.appId}.zip',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已保存到：$path')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('下载失败')));
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  void _showAppDetail() {
    final auth = ref.read(authProvider).user;
    final canManage = auth.isAdmin || _appInfo.userId == auth.id;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _appInfo.appName ?? '未命名应用',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (_appInfo.codeGenType != null)
              CodeGenTypeTag(codeGenType: _appInfo.codeGenType!),
            const SizedBox(height: 12),
            Text('初始提示词：${_appInfo.initPrompt ?? '-'}'),
            const SizedBox(height: 12),
            Text('创建时间：${formatDateTime(_appInfo.createTime)}'),
            const SizedBox(height: 24),
            if (canManage)
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/app/edit/${widget.appId}');
                    },
                    child: const Text('编辑'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () async {
                      final auth = ref.read(authProvider).user;
                      final service = ref.read(appServiceProvider);
                      final res = auth.isAdmin
                          ? await service.deleteAppByAdmin(widget.appId)
                          : await service.deleteApp(widget.appId);
                      if (res.isSuccess) {
                        Navigator.pop(context);
                        context.go('/');
                      }
                    },
                    child: const Text('删除', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider).user;
    final canPreview = _showPreview && _previewUrl != null;
    if (canPreview && _webController == null) _initWebView();

    final isWide = MediaQuery.sizeOf(context).width > 900;

    return Column(
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            border: Border(bottom: BorderSide(color: AppColors.mintBorder)),
          ),
          child: Row(
            children: [
              Image.asset(AppAssets.iconWeb, width: 28, height: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _appInfo.appName ?? '未命名应用',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_appInfo.codeGenType != null)
                CodeGenTypeTag(codeGenType: _appInfo.codeGenType!),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _showAppDetail,
                child: const Text('应用详情'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _isDownloading ? null : _handleDownload,
                child: _isDownloading
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('下载代码'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isDeploying ? null : _handleDeploy,
                child: _isDeploying
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('部署'),
              ),
            ],
          ),
        ),
        if (!isWide)
          TabBar(
            controller: _tabController,
            labelColor: AppColors.mintPrimary,
            tabs: const [
              Tab(text: '对话'),
              Tab(text: '预览'),
            ],
          ),
        Expanded(
          child: isWide
              ? Row(
                  children: [
                    Expanded(flex: 2, child: _buildChatPanel(auth)),
                    Expanded(flex: 3, child: _buildPreviewPanel(canPreview)),
                  ],
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildChatPanel(auth),
                    _buildPreviewPanel(canPreview),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildChatPanel(LoginUser auth) {
    return ColoredBox(
      color: Colors.white.withValues(alpha: 0.55),
      child: Column(
        children: [
          Expanded(
            child: _isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_hasMoreHistory ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_hasMoreHistory && index == 0) {
                        return Center(
                          child: TextButton(
                            onPressed: _isLoadingMoreHistory
                                ? null
                                : () => _fetchChatHistory(true),
                            child: _isLoadingMoreHistory
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('加载更多'),
                          ),
                        );
                      }
                      final msgIndex = _hasMoreHistory ? index - 1 : index;
                      if (msgIndex < 0 || msgIndex >= _messages.length) {
                        return const SizedBox.shrink();
                      }
                      final msg = _messages[msgIndex];
                      return _MessageBubble(message: msg, userAvatar: auth.userAvatar);
                    },
                  ),
          ),
          PromptInputBox(
            controller: _inputController,
            onSubmit: () => _sendMessage(_inputController.text),
            variant: PromptVariant.chat,
            placeholder: '请描述你想生成的网站，越详细效果越好哦',
            loading: _isGenerating,
            disabled: _isGenerating,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewPanel(bool canPreview) {
    return ColoredBox(
      color: const Color(0xD9F0F7F4),
      child: Column(
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              border: Border(bottom: BorderSide(color: AppColors.mintBorder)),
            ),
            child: Row(
              children: [
                const Text('网页预览',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                if (canPreview && _previewUrl != null)
                  IconButton(
                    icon: Image.asset(AppAssets.iconPageOpen, width: 18, height: 18),
                    onPressed: () => launchUrl(
                      Uri.parse(_previewUrl!),
                      mode: LaunchMode.externalApplication,
                    ),
                    tooltip: '新窗口打开',
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: canPreview && _webController != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: WebViewWidget(key: ValueKey(_previewKey), controller: _webController!),
                    )
                  : Center(
                      child: _isGenerating
                          ? const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 12),
                                Text('正在生成网站...'),
                              ],
                            )
                          : const Text(
                              '生成完成后将在此展示网站效果',
                              style: TextStyle(color: AppColors.textPlaceholder),
                            ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, this.userAvatar});

  final ChatMessage message;
  final String? userAvatar;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(AppAssets.avatarChatbot, width: 36, height: 36, fit: BoxFit.cover),
            )
          else
            const SizedBox(width: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.mintLight.withValues(alpha: 0.22)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.mintLight.withValues(alpha: isUser ? 0.35 : 0.28),
                ),
                boxShadow: isUser
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.mintLight.withValues(alpha: 0.1),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: isUser
                  ? Text(
                      message.content.isEmpty && message.isStreaming
                          ? '生成中...'
                          : message.content,
                      style: const TextStyle(height: 1.6),
                    )
                  : message.content.isNotEmpty
                      ? MarkdownContent(content: message.content)
                      : Text(
                          message.isStreaming ? '生成中...' : '',
                          style: const TextStyle(height: 1.6),
                        ),
            ),
          ),
          const SizedBox(width: 10),
          if (isUser)
            UserAvatar(size: 36, src: userAvatar)
          else
            const SizedBox(width: 36),
        ],
      ),
    );
  }
}
