import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:starvive/core/constants/app_constants.dart';
import 'package:starvive/core/utils/format_utils.dart';
import 'package:starvive/providers/providers.dart';
import 'package:starvive/services/services.dart';
import 'package:starvive/widgets/home_background.dart';
import 'package:starvive/widgets/user_avatar.dart';

class UserInfoPage extends ConsumerStatefulWidget {
  const UserInfoPage({super.key});

  @override
  ConsumerState<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends ConsumerState<UserInfoPage> {
  bool _isEditing = false;
  bool _isSubmitting = false;
  final _nameController = TextEditingController();
  final _profileController = TextEditingController();
  String _avatar = '';

  @override
  void initState() {
    super.initState();
    _syncForm();
  }

  void _syncForm() {
    final user = ref.read(authProvider).user;
    _nameController.text = user.userName ?? '';
    _profileController.text = user.userProfile ?? '';
    _avatar = user.userAvatar ?? '';
  }

  Future<void> _pickAvatar() async {
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
      setState(() {
        _avatar = compressImageToBase64(Uint8List.fromList(bytes), 256);
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('头像已选择')));
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('头像读取失败')));
    }
  }

  Future<void> _save() async {
    final user = ref.read(authProvider).user;
    if (!user.isLoggedIn) return;
    setState(() => _isSubmitting = true);
    final err = await ref.read(authProvider.notifier).updateProfile(
          id: user.id!,
          userName: _nameController.text.trim(),
          userAvatar: _avatar,
          userProfile: _profileController.text.trim(),
          userRole: user.userRole,
        );
    setState(() => _isSubmitting = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('保存成功')));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _profileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (!user.isLoggedIn) {
      return const Center(child: CircularProgressIndicator());
    }

    final roleText = user.userRole == 'admin' ? '管理员' : '用户';

    return HomeBackground(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: AppColors.mintBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '个人信息',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (!_isEditing)
                          OutlinedButton(
                            onPressed: () {
                              _syncForm();
                              setState(() => _isEditing = true);
                            },
                            child: const Text('编辑'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_isEditing) ...[
                      Row(
                        children: [
                          UserAvatar(size: 64, src: _avatar),
                          const SizedBox(width: 16),
                          OutlinedButton(
                            onPressed: _pickAvatar,
                            child: const Text('本地上传'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: '用户名'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: '账号',
                          hintText: user.userAccount,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        enabled: false,
                        decoration: InputDecoration(labelText: '角色', hintText: roleText),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _profileController,
                        maxLines: 4,
                        decoration: const InputDecoration(labelText: '简介'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: '注册时间',
                          hintText: formatRegisterDate(user.createTime),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              _syncForm();
                              setState(() => _isEditing = false);
                            },
                            child: const Text('取消'),
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
                    ] else ...[
                      _infoRow('头像', UserAvatar(size: 64, src: user.userAvatar)),
                      _infoRow('用户名', Text(user.userName ?? '-')),
                      _infoRow('账号', Text(user.userAccount ?? '-')),
                      _infoRow('角色', Text(roleText)),
                      _infoRow(
                        '简介',
                        Text(
                          user.userProfile?.trim().isNotEmpty == true
                              ? user.userProfile!
                              : '还没有填写简介',
                          style: TextStyle(
                            color: user.userProfile?.trim().isNotEmpty == true
                                ? AppColors.textSecondary
                                : AppColors.textPlaceholder,
                          ),
                        ),
                      ),
                      _infoRow(
                        '注册时间',
                        Text(formatRegisterDate(user.createTime)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: AppColors.textMuted)),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
