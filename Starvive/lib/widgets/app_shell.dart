import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:starvive/core/constants/app_constants.dart';
import 'package:starvive/providers/providers.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child, this.hideFooter = false});

  final Widget child;
  final bool hideFooter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final location = GoRouterState.of(context).uri.path;
    final isAdmin = location.startsWith('/admin') ||
        (location.startsWith('/app/edit') && auth.user.isAdmin);
    final isMint = !isAdmin;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isAdmin
            ? AppColors.adminBg.withValues(alpha: 0.9)
            : AppColors.mintBg.withValues(alpha: 0.88),
        title: Row(
          children: [
            Image.asset(AppAssets.iconLogo, width: 36, height: 36),
            const SizedBox(width: 12),
            const Text('星衍', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          if (auth.user.isLoggedIn) ...[
            if (auth.user.isAdmin) _navBtn(context, '/', '首页', location == '/'),
            if (auth.user.isAdmin)
              _navBtn(
                context,
                '/admin/userManage',
                '用户管理',
                location.startsWith('/admin/userManage'),
                admin: true,
              ),
            if (auth.user.isAdmin)
              _navBtn(
                context,
                '/admin/appManage',
                '应用管理',
                location.startsWith('/admin/appManage'),
                admin: true,
              ),
            if (auth.user.isAdmin)
              _navBtn(
                context,
                '/admin/chatManage',
                '对话管理',
                location.startsWith('/admin/chatManage'),
                admin: true,
              ),
            PopupMenuButton<String>(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: auth.user.userAvatar?.isNotEmpty == true
                          ? NetworkImage(auth.user.userAvatar!)
                          : null,
                      child: auth.user.userAvatar?.isEmpty != false
                          ? const Icon(Icons.person, size: 18)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(auth.user.userName ?? ''),
                  ],
                ),
              ),
              onSelected: (value) async {
                if (value == 'info') {
                  context.push('/user/info');
                } else if (value == 'logout') {
                  final err = await ref.read(authProvider.notifier).logout();
                  if (err == null) {
                    context.go('/user/login');
                  }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'info', child: Text('个人信息')),
                const PopupMenuItem(value: 'logout', child: Text('退出登录')),
              ],
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton(
                onPressed: () => context.push('/user/login'),
                child: const Text('登录'),
              ),
            ),
        ],
      ),
      body: child,
    );
  }

  Widget _navBtn(
    BuildContext context,
    String path,
    String label,
    bool selected, {
    bool admin = false,
  }) {
    final color = admin ? AppColors.adminPrimary : AppColors.mintPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        onPressed: () => context.go(path),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : AppColors.textMuted,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
