import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:starvive/core/constants/app_constants.dart';
import 'package:starvive/core/utils/format_utils.dart';
import 'package:starvive/providers/providers.dart';
import 'package:starvive/services/services.dart';
import 'package:starvive/widgets/empty_state.dart';
import 'package:starvive/widgets/user_avatar.dart';

class ProfileTabPage extends ConsumerStatefulWidget {
  const ProfileTabPage({super.key});

  @override
  ConsumerState<ProfileTabPage> createState() => _ProfileTabPageState();
}

class _ProfileTabPageState extends ConsumerState<ProfileTabPage> {
  bool _isEditing = false;
  bool _isSubmitting = false;
  final _nameController = TextEditingController();
  final _profileController = TextEditingController();
  String _avatar = '';
  int _gender = 1;

  String _genderText(int? gender) {
    if (gender == 0) return '女';
    if (gender == 1) return '男';
    return '-';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _profileController.dispose();
    super.dispose();
  }

  void _syncForm() {
    final user = ref.read(authProvider).user;
    _nameController.text = user.userName ?? '';
    _profileController.text = user.userProfile ?? '';
    _avatar = user.userAvatar ?? '';
    _gender = user.gender ?? 1;
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
          gender: _gender,
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

  Future<void> _logout() async {
    final err = await ref.read(authProvider.notifier).logout();
    if (err == null && mounted) {
      ref.read(currentChatAppIdProvider.notifier).state = null;
      ref.read(mainTabIndexProvider.notifier).state = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    if (!user.isLoggedIn) {
      return ColoredBox(
        color: AppColors.mintBg,
        child: EmptyState(
          icon: Icons.person_outline,
          title: '登录后查看个人信息',
          action: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () => context.push('/user/login?redirect=/'),
                child: const Text('登录'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () => context.push('/user/register'),
                child: const Text('注册'),
              ),
            ],
          ),
        ),
      );
    }

    return ColoredBox(
      color: AppColors.mintBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '个人信息',
                      style: TextStyle(
                        fontSize: AppFontSize.lg,
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
                const SizedBox(height: AppSpacing.lg),
                if (_isEditing) ...[
                  _EditForm(
                    nameController: _nameController,
                    profileController: _profileController,
                    avatar: _avatar,
                    gender: _gender,
                    userAccount: user.userAccount,
                    createTime: user.createTime,
                    onPickAvatar: _pickAvatar,
                    onGenderChanged: (value) => setState(() => _gender = value),
                    isSubmitting: _isSubmitting,
                    onCancel: () {
                      _syncForm();
                      setState(() => _isEditing = false);
                    },
                    onSave: _save,
                  ),
                ] else ...[
                  _InfoRow(
                    label: '头像',
                    child: UserAvatar(size: 64, src: user.userAvatar, gender: user.gender),
                  ),
                  _InfoRow(label: '用户名', child: Text(user.userName ?? '-')),
                  _InfoRow(label: '账号', child: Text(user.userAccount ?? '-')),
                  _InfoRow(label: '性别', child: Text(_genderText(user.gender))),
                  _InfoRow(
                    label: '简介',
                    child: Text(
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
                  _InfoRow(
                    label: '注册时间',
                    child: Text(formatRegisterDate(user.createTime)),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade400,
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                  child: const Text('退出登录'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditForm extends StatelessWidget {
  const _EditForm({
    required this.nameController,
    required this.profileController,
    required this.avatar,
    required this.gender,
    required this.userAccount,
    required this.createTime,
    required this.onPickAvatar,
    required this.onGenderChanged,
    required this.isSubmitting,
    required this.onCancel,
    required this.onSave,
  });

  final TextEditingController nameController;
  final TextEditingController profileController;
  final String avatar;
  final int gender;
  final String? userAccount;
  final String? createTime;
  final VoidCallback onPickAvatar;
  final ValueChanged<int> onGenderChanged;
  final bool isSubmitting;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            UserAvatar(size: 64, src: avatar, gender: gender),
            const SizedBox(width: AppSpacing.md),
            OutlinedButton(onPressed: onPickAvatar, child: const Text('本地上传')),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: '用户名'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          enabled: false,
          decoration: InputDecoration(labelText: '账号', hintText: userAccount),
        ),
        const SizedBox(height: AppSpacing.md),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('性别', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 1, label: Text('男')),
            ButtonSegment(value: 0, label: Text('女')),
          ],
          selected: {gender},
          onSelectionChanged: (value) => onGenderChanged(value.first),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: profileController,
          maxLines: 4,
          decoration: const InputDecoration(labelText: '简介'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          enabled: false,
          decoration: InputDecoration(
            labelText: '注册时间',
            hintText: formatRegisterDate(createTime),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(onPressed: onCancel, child: const Text('取消')),
            const SizedBox(width: AppSpacing.sm),
            ElevatedButton(
              onPressed: isSubmitting ? null : onSave,
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存'),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: const TextStyle(color: AppColors.textMuted)),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
