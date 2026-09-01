import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starvive/core/constants/app_constants.dart';
import 'package:starvive/core/constants/business_constants.dart';
import 'package:starvive/models/models.dart';
import 'package:starvive/providers/providers.dart';
import 'package:starvive/widgets/app_card.dart';
import 'package:starvive/widgets/empty_state.dart';

class PlazaTabPage extends ConsumerStatefulWidget {
  const PlazaTabPage({super.key});

  @override
  ConsumerState<PlazaTabPage> createState() => _PlazaTabPageState();
}

class _PlazaTabPageState extends ConsumerState<PlazaTabPage> {
  List<AppVO> _apps = [];
  int _total = 0;
  int _pageNum = 1;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ref.read(appServiceProvider).listAppPlazaVoByPage({
        'pageNum': _pageNum,
        'pageSize': plazaPageSize,
      });
      if (res.isSuccess && res.data != null) {
        setState(() {
          _apps = res.data!.records ?? [];
          _total = res.data!.totalRow ?? 0;
        });
      } else {
        setState(() => _error = res.message ?? '加载失败');
      }
    } catch (_) {
      setState(() => _error = '网络异常，请稍后重试');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_total / plazaPageSize).ceil().clamp(1, 999999);

    return ColoredBox(
      color: AppColors.mintBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              '应用广场',
              style: TextStyle(
                fontSize: AppFontSize.xl,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingState()
                : _error != null
                    ? ErrorState(message: _error!, onRetry: _fetch)
                    : _apps.isEmpty
                        ? const EmptyState(
                            icon: Icons.apps_outlined,
                            title: '暂无应用',
                            subtitle: '快来创建第一个应用吧',
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              _pageNum = 1;
                              await _fetch();
                            },
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final crossAxisCount = constraints.maxWidth > 900
                                    ? 3
                                    : constraints.maxWidth > 600
                                        ? 2
                                        : 1;
                                return ListView(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  children: [
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        crossAxisSpacing: AppSpacing.md,
                                        mainAxisSpacing: AppSpacing.md,
                                        childAspectRatio: 0.85,
                                      ),
                                      itemCount: _apps.length,
                                      itemBuilder: (_, index) =>
                                          AppCard(app: _apps[index]),
                                    ),
                                    if (totalPages > 1)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: AppSpacing.md,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              onPressed: _pageNum > 1
                                                  ? () {
                                                      _pageNum--;
                                                      _fetch();
                                                    }
                                                  : null,
                                              icon: const Icon(Icons.chevron_left),
                                            ),
                                            Text('$_pageNum / $totalPages'),
                                            IconButton(
                                              onPressed: _pageNum < totalPages
                                                  ? () {
                                                      _pageNum++;
                                                      _fetch();
                                                    }
                                                  : null,
                                              icon:
                                                  const Icon(Icons.chevron_right),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
