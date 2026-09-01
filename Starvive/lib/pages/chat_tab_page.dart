import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:starvive/core/constants/app_constants.dart';
import 'package:starvive/core/constants/business_constants.dart';
import 'package:starvive/models/models.dart';
import 'package:starvive/pages/app_chat_page.dart';
import 'package:starvive/providers/providers.dart';
import 'package:starvive/widgets/empty_state.dart';
import 'package:starvive/widgets/prompt_input_box.dart';

class ChatTabPage extends ConsumerStatefulWidget {
  const ChatTabPage({super.key});

  @override
  ConsumerState<ChatTabPage> createState() => _ChatTabPageState();
}

class _ChatTabPageState extends ConsumerState<ChatTabPage> {
  final _createController = TextEditingController();
  List<AppVO> _myApps = [];
  bool _isLoadingApps = false;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMyApps());
  }

  @override
  void dispose() {
    _createController.dispose();
    super.dispose();
  }

  Future<void> _loadMyApps() async {
    final auth = ref.read(authProvider);
    if (!auth.user.isLoggedIn) return;

    setState(() => _isLoadingApps = true);
    try {
      final res = await ref.read(appServiceProvider).listMyAppVoByPage({
        'pageNum': 1,
        'pageSize': myAppPageSize,
      });
      if (res.isSuccess && res.data != null) {
        _myApps = res.data!.records ?? [];
        final currentId = ref.read(currentChatAppIdProvider);
        if (currentId == null && _myApps.isNotEmpty && _myApps.first.id != null) {
          ref.read(currentChatAppIdProvider.notifier).state = _myApps.first.id;
        }
      }
    } finally {
      if (mounted) setState(() => _isLoadingApps = false);
    }
  }

  Future<void> _createApp() async {
    final initPrompt = _createController.text.trim();
    if (initPrompt.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请输入提示词')));
      return;
    }
    setState(() => _isCreating = true);
    try {
      final res = await ref.read(appServiceProvider).addApp(initPrompt: initPrompt);
      if (res.isSuccess && res.data != null) {
        _createController.clear();
        ref.read(currentChatAppIdProvider.notifier).state = res.data;
        await _loadMyApps();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败：${res.message ?? '未知错误'}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _startNewChat() {
    ref.read(currentChatAppIdProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final appId = ref.watch(currentChatAppIdProvider);

    ref.listen(authProvider, (prev, next) {
      if (prev?.user.id != next.user.id) {
        ref.read(currentChatAppIdProvider.notifier).state = null;
        _loadMyApps();
      }
    });

    if (!auth.user.isLoggedIn) {
      return EmptyState(
        icon: Icons.chat_bubble_outline,
        title: '登录后开始与 AI 对话',
        action: ElevatedButton(
          onPressed: () => context.push('/user/login?redirect=/'),
          child: const Text('去登录'),
        ),
      );
    }

    if (_isLoadingApps && appId == null) {
      return const LoadingState();
    }

    if (appId == null) {
      return _NewChatView(
        controller: _createController,
        loading: _isCreating,
        onSubmit: _createApp,
        myApps: _myApps,
        onSelectApp: (id) {
          ref.read(currentChatAppIdProvider.notifier).state = id;
        },
      );
    }

    return Column(
      children: [
        _ChatAppBar(
          myApps: _myApps,
          currentAppId: appId,
          onSelectApp: (id) {
            ref.read(currentChatAppIdProvider.notifier).state = id;
          },
          onNewChat: _startNewChat,
        ),
        Expanded(child: AppChatPage(appId: appId)),
      ],
    );
  }
}

class _ChatAppBar extends StatelessWidget {
  const _ChatAppBar({
    required this.myApps,
    required this.currentAppId,
    required this.onSelectApp,
    required this.onNewChat,
  });

  final List<AppVO> myApps;
  final String currentAppId;
  final ValueChanged<String> onSelectApp;
  final VoidCallback onNewChat;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        border: Border(bottom: BorderSide(color: AppColors.mintBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: myApps.length <= 1
                ? Text(
                    myApps.isNotEmpty
                        ? (myApps.first.appName ?? '对话')
                        : '对话',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: myApps.map((app) {
                        final id = app.id;
                        if (id == null) return const SizedBox.shrink();
                        final selected = id == currentAppId;
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: FilterChip(
                            label: Text(
                              app.appName ?? '未命名',
                              overflow: TextOverflow.ellipsis,
                            ),
                            selected: selected,
                            onSelected: (_) => onSelectApp(id),
                            selectedColor:
                                AppColors.mintLight.withValues(alpha: 0.35),
                            checkmarkColor: AppColors.mintPrimary,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: '新建对话',
            onPressed: onNewChat,
          ),
        ],
      ),
    );
  }
}

class _NewChatView extends StatelessWidget {
  const _NewChatView({
    required this.controller,
    required this.loading,
    required this.onSubmit,
    required this.myApps,
    required this.onSelectApp,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSubmit;
  final List<AppVO> myApps;
  final ValueChanged<String> onSelectApp;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.mintBg,
      child: Column(
        children: [
          if (myApps.isNotEmpty)
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: myApps.map((app) {
                    final id = app.id;
                    if (id == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ActionChip(
                        label: Text(app.appName ?? '未命名'),
                        onPressed: () => onSelectApp(id),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          const Expanded(
            child: EmptyState(
              icon: Icons.auto_awesome_outlined,
              title: '描述你想创建的应用',
              subtitle: 'AI 将根据你的描述生成代码',
            ),
          ),
          PromptInputBox(
            controller: controller,
            onSubmit: onSubmit,
            variant: PromptVariant.chat,
            placeholder: '请描述你想生成的网站，越详细效果越好',
            loading: loading,
          ),
        ],
      ),
    );
  }
}
