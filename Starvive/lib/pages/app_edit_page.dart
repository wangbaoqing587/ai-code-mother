import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:starvive/config/env.dart';
import 'package:starvive/core/constants/app_constants.dart';
import 'package:starvive/core/constants/business_constants.dart';
import 'package:starvive/core/utils/format_utils.dart';
import 'package:starvive/models/models.dart';
import 'package:starvive/providers/providers.dart';
import 'package:starvive/services/services.dart';
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
  final _coverController = TextEditingController();
  int? _priority;

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
      final service = ref.read(appServiceProvider);
      final res = auth.isAdmin
          ? await service.getAppByIdByAdmin(widget.appId)
          : await service.getAppVoById(widget.appId);
      if (res.isSuccess && res.data != null) {
        _appInfo = res.data!;
        _nameController.text = _appInfo.appName ?? '';
        _coverController.text = _appInfo.cover ?? '';
        _priority = _appInfo.priority;
        final canEdit = auth.isAdmin || _appInfo.userId == auth.id;
        if (!canEdit) {
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

  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.length > 2 * 1024 * 1024) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('图片大小不能超过 2MB')));
      return;
    }
    try {
      _coverController.text = compressImageToBase64(Uint8List.fromList(bytes), 800);
      setState(() {});
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('封面已选择')));
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('封面读取失败')));
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请输入应用名称')));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final auth = ref.read(authProvider).user;
      final service = ref.read(appServiceProvider);
      final res = auth.isAdmin
          ? await service.updateAppByAdmin(
              id: widget.appId,
              appName: _nameController.text.trim(),
              cover: _coverController.text.isEmpty ? null : _coverController.text,
              priority: _priority,
            )
          : await service.updateApp(
              id: widget.appId,
              appName: _nameController.text.trim(),
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
    _coverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider).user;
    final isAdmin = auth.isAdmin;

    return HomeBackground(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isAdmin ? AppColors.adminBorder : AppColors.mintBorder,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '应用信息编辑',
                            textAlign: isAdmin ? TextAlign.center : TextAlign.left,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => context.pop(),
                                child: const Text('返回'),
                              ),
                              const SizedBox(width: 12),
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
                          const SizedBox(height: 20),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: '应用名称'),
                          ),
                          const SizedBox(height: 16),
                          const Text('应用封面'),
                          const SizedBox(height: 8),
                          if (_coverController.text.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: _coverController.text.startsWith('data:image')
                                  ? Image.memory(
                                      base64Decode(
                                        _coverController.text.contains(',')
                                            ? _coverController.text.split(',').last
                                            : _coverController.text,
                                      ),
                                      height: 160,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      _coverController.text,
                                      height: 160,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const SizedBox(
                                        height: 160,
                                        child: Center(child: Text('封面预览失败')),
                                      ),
                                    ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _coverController,
                                  decoration: const InputDecoration(
                                    hintText: '请输入封面 URL',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: _pickCover,
                                child: const Text('本地上传'),
                              ),
                            ],
                          ),
                          if (isAdmin) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                SizedBox(
                                  width: 200,
                                  child: TextField(
                                    decoration: const InputDecoration(labelText: '优先级'),
                                    keyboardType: TextInputType.number,
                                    controller: TextEditingController(
                                      text: _priority?.toString() ?? '',
                                    ),
                                    onChanged: (v) =>
                                        _priority = int.tryParse(v),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  '99 表示精选应用',
                                  style: TextStyle(color: AppColors.textPlaceholder),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextField(
                            enabled: false,
                            decoration: InputDecoration(
                              labelText: '初始提示词',
                              hintText: _appInfo.initPrompt ?? '-',
                            ),
                            maxLines: 4,
                          ),
                          const SizedBox(height: 16),
                          const Text('生成类型'),
                          const SizedBox(height: 8),
                          if (_appInfo.codeGenType != null)
                            CodeGenTypeTag(codeGenType: _appInfo.codeGenType!),
                          if (isAdmin) ...[
                            const SizedBox(height: 16),
                            TextField(
                              enabled: false,
                              decoration: InputDecoration(
                                labelText: '部署密钥',
                                hintText: _appInfo.deployKey ?? '-',
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          const Divider(),
                          const SizedBox(height: 16),
                          const Text(
                            '应用信息',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          _infoTile('应用 ID', Text(_appInfo.id ?? '-')),
                          _infoTile(
                            '创建者',
                            Row(
                              children: [
                                UserAvatar(
                                  size: 24,
                                  src: _appInfo.user?.userAvatar,
                                ),
                                const SizedBox(width: 8),
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
                                          style: const TextStyle(fontSize: 13),
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
