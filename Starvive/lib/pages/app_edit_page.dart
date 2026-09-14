import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:starvive/config/env.dart';
import 'package:starvive/core/constants/app_constants.dart';
import 'package:starvive/core/constants/business_constants.dart';
import 'package:starvive/core/utils/format_utils.dart';
import 'package:starvive/models/models.dart';
import 'package:starvive/providers/providers.dart';
import 'package:starvive/widgets/code_gen_type_tag.dart';
import 'package:starvive/widgets/home_background.dart';
import 'package:starvive/widgets/user_avatar.dart';
import 'package:url_launcher/url_launcher.dart';

class AppEditPage extends ConsumerStatefulWidget {
  const AppEditPage({super.key, required this.appId});

  final String appId;

  @override
  ConsumerState<AppEditPage> createState() => _AppEditPageState();
}

class _AppEditPageState extends ConsumerState<AppEditPage> {
  AppVO _appInfo = AppVO();
  bool _isLoading = false;
  bool _isSubmitting = false;
  final _nameController = TextEditingController();
  String _visibility = appVisibilityPlaza;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = ref.read(authProvider).user;
    if (!auth.isLoggedIn) {
      context.go('/user/login?redirect=/app/edit/${widget.appId}');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await ref.read(appServiceProvider).getAppVoById(widget.appId);
      if (res.isSuccess && res.data != null) {
        _appInfo = res.data!;
        _nameController.text = _appInfo.appName ?? '';
        _visibility = _appInfo.visibility == appVisibilityPrivate
            ? appVisibilityPrivate
            : appVisibilityPlaza;
        if (_appInfo.userId != auth.id) {
          context.go('/');
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String? get _accessUrl {
    if (_appInfo.deployKey != null) {
      return getDeployUrl(_appInfo.deployKey!, _appInfo.codeGenType);
    }
    if (_appInfo.codeGenType != null) {
      return getStaticPreviewUrl(_appInfo.codeGenType!, widget.appId);
    }
    return null;
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请输入应用名称')));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final res = await ref.read(appServiceProvider).updateApp(
            id: widget.appId,
            appName: _nameController.text.trim(),
            visibility: _visibility,
          );
      if (res.isSuccess) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('保存成功')));
        await _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：${res.message ?? '未知错误'}')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomeBackground(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      side: BorderSide(color: AppColors.mintBorder),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            '应用信息编辑',
                            style: TextStyle(
                              fontSize: AppFontSize.lg,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => context.pop(),
                                child: const Text('返回'),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              ElevatedButton(
                                onPressed: _isSubmitting ? null : _save,
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('保存'),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: '应用名称'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Text('可见范围'),
                          const SizedBox(height: AppSpacing.sm),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: appVisibilityPlaza,
                                label: Text('广场可见'),
                              ),
                              ButtonSegment(
                                value: appVisibilityPrivate,
                                label: Text('仅自己可见'),
                              ),
                            ],
                            selected: {_visibility},
                            onSelectionChanged: (selected) {
                              setState(() => _visibility = selected.first);
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            enabled: false,
                            decoration: InputDecoration(
                              labelText: '初始提示词',
                              hintText: _appInfo.initPrompt ?? '-',
                            ),
                            maxLines: 4,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Text('生成类型'),
                          const SizedBox(height: AppSpacing.sm),
                          if (_appInfo.codeGenType != null)
                            CodeGenTypeTag(codeGenType: _appInfo.codeGenType!),
                          const SizedBox(height: AppSpacing.xl),
                          const Divider(),
                          const SizedBox(height: AppSpacing.md),
                          const Text(
                            '应用信息',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: AppFontSize.md),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _infoTile('应用 ID', Text(_appInfo.id ?? '-')),
                          _infoTile(
                            '创建者',
                            Row(
                              children: [
                                UserAvatar(
                                  size: 24,
                                  src: _appInfo.user?.userAvatar,
                                  gender: _appInfo.user?.gender,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(_appInfo.user?.userName ?? '未知用户'),
                              ],
                            ),
                          ),
                          _infoTile('创建时间', Text(formatDateTime(_appInfo.createTime))),
                          _infoTile('更新时间', Text(formatDateTime(_appInfo.updateTime))),
                          _infoTile('部署时间', Text(formatDateTime(_appInfo.deployedTime))),
                          _infoTile(
                            '访问链接',
                            _accessUrl != null
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _accessUrl!,
                                          style: const TextStyle(fontSize: AppFontSize.sm),
                                        ),
                                      ),
                                      OutlinedButton(
                                        onPressed: () => launchUrl(
                                          Uri.parse(_accessUrl!),
                                          mode: LaunchMode.externalApplication,
                                        ),
                                        child: const Text('浏览'),
                                      ),
                                    ],
                                  )
                                : const Text('-'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _infoTile(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(color: AppColors.textMuted)),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
