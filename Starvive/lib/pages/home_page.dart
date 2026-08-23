import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:starvive/core/constants/app_constants.dart';
import 'package:starvive/core/constants/business_constants.dart';
import 'package:starvive/models/models.dart';
import 'package:starvive/providers/providers.dart';
import 'package:starvive/widgets/app_list_section.dart';
import 'package:starvive/widgets/home_background.dart';
import 'package:starvive/widgets/prompt_input_box.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _promptController = TextEditingController();
  bool _isCreating = false;
  List<AppVO> _myApps = [];
  int _myTotal = 0;
  bool _isMyLoading = false;
  int _myPageNum = 1;
  List<AppVO> _goodApps = [];
  int _goodTotal = 0;
  bool _isGoodLoading = false;
  int _goodPageNum = 1;

  @override
  void initState() {
    super.initState();
    _fetchGoodApps();
    _fetchMyApps();
  }

  Future<void> _fetchMyApps() async {
    final auth = ref.read(authProvider);
    if (!auth.user.isLoggedIn) {
      setState(() {
        _myApps = [];
        _myTotal = 0;
      });
      return;
    }
    setState(() => _isMyLoading = true);
    try {
      final service = ref.read(appServiceProvider);
      final query = {
        'pageNum': _myPageNum,
        'pageSize': myAppPageSize,
        'userId': auth.user.id,
      };
      final res = auth.user.isAdmin
          ? await service.listAppVoByPageByAdmin(query)
          : await service.listMyAppVoByPage(query);
      if (res.isSuccess && res.data != null) {
        final records = res.data!.records ?? [];
        final filtered = records
            .where((a) => a.userId == auth.user.id)
            .toList();
        setState(() {
          _myApps = filtered;
          _myTotal = res.data!.totalRow ?? filtered.length;
        });
      }
    } finally {
      setState(() => _isMyLoading = false);
    }
  }

  Future<void> _fetchGoodApps() async {
    setState(() => _isGoodLoading = true);
    try {
      final res = await ref.read(appServiceProvider).listGoodAppVoByPage({
        'pageNum': _goodPageNum,
        'pageSize': goodAppPageSize,
      });
      if (res.isSuccess && res.data != null) {
        setState(() {
          _goodApps = res.data!.records ?? [];
          _goodTotal = res.data!.totalRow ?? 0;
        });
      }
    } finally {
      setState(() => _isGoodLoading = false);
    }
  }

  Future<void> _handleCreate() async {
    final initPrompt = _promptController.text.trim();
    if (initPrompt.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请输入提示词')));
      return;
    }
    final auth = ref.read(authProvider);
    if (!auth.user.isLoggedIn) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请先登录')));
      context.push('/user/login?redirect=/');
      return;
    }
    setState(() => _isCreating = true);
    try {
      final res = await ref.read(appServiceProvider).addApp(initPrompt: initPrompt);
      if (res.isSuccess && res.data != null) {
        _promptController.clear();
        context.push('/app/chat/${res.data}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建应用失败：${res.message ?? '未知错误'}')),
        );
      }
    } finally {
      setState(() => _isCreating = false);
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    ref.listen(authProvider, (prev, next) {
      if (prev?.user.id != next.user.id) {
        _myPageNum = 1;
        _fetchMyApps();
      }
    });

    return HomeBackground(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Column(
                children: [
                  Image.asset(
                    AppAssets.iconCoverLogo,
                    width: 160,
                    height: 160,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '星衍-AI 零代码应用生成平台',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '以灵感为星，衍万千应用',
                    style: TextStyle(fontSize: 16, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 32),
                  PromptInputBox(
                    controller: _promptController,
                    onSubmit: _handleCreate,
                    placeholder: '帮我创建个人博客网站',
                    loading: _isCreating,
                    variant: PromptVariant.hero,
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: quickPrompts.map((item) {
                      return OutlinedButton(
                        onPressed: () => _promptController.text = item.prompt,
                        style: OutlinedButton.styleFrom(
                          shape: const StadiumBorder(),
                          side: BorderSide(
                            color: AppColors.mintLight.withValues(alpha: 0.55),
                            width: 2,
                          ),
                          backgroundColor: Colors.white,
                        ),
                        child: Text(item.label),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            if (auth.user.isLoggedIn && _myApps.isNotEmpty)
              AppListSection(
                title: '我的作品',
                apps: _myApps,
                total: _myTotal,
                loading: _isMyLoading,
                pageNum: _myPageNum,
                pageSize: myAppPageSize,
                onPageChange: (page) {
                  _myPageNum = page;
                  _fetchMyApps();
                },
              ),
            if (_goodApps.isNotEmpty)
              AppListSection(
                title: '精选案例',
                apps: _goodApps,
                total: _goodTotal,
                loading: _isGoodLoading,
                pageNum: _goodPageNum,
                pageSize: goodAppPageSize,
                onPageChange: (page) {
                  _goodPageNum = page;
                  _fetchGoodApps();
                },
              ),
            const SizedBox(height: 72),
          ],
        ),
      ),
    );
  }
}
