import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:starvive/pages/admin_pages.dart';
import 'package:starvive/pages/app_chat_page.dart';
import 'package:starvive/pages/app_edit_page.dart';
import 'package:starvive/pages/auth_pages.dart';
import 'package:starvive/pages/home_page.dart';
import 'package:starvive/pages/user_info_page.dart';
import 'package:starvive/providers/providers.dart';
import 'package:starvive/widgets/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final path = state.uri.path;
      final isLoggedIn = auth.user.isLoggedIn;
      final isAdmin = auth.user.isAdmin;

      if (!auth.initialized) return null;

      final userRoutes = [
        '/user/info',
        '/app/chat',
        '/app/edit',
      ];
      final adminRoutes = [
        '/admin/userManage',
        '/admin/appManage',
        '/admin/chatManage',
      ];

      if (userRoutes.any((r) => path.startsWith(r)) && !isLoggedIn) {
        return '/user/login?redirect=${Uri.encodeComponent(state.uri.toString())}';
      }

      if (adminRoutes.any((r) => path.startsWith(r)) && !isAdmin) {
        return '/401';
      }

      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          final hideFooter = state.uri.path.startsWith('/app/chat');
          if (state.uri.path == '/user/login' ||
              state.uri.path == '/user/register' ||
              state.uri.path == '/401') {
            return child;
          }
          return AppShell(hideFooter: hideFooter, child: child);
        },
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomePage()),
          GoRoute(path: '/user/login', builder: (_, __) => const LoginPage()),
          GoRoute(path: '/user/register', builder: (_, __) => const RegisterPage()),
          GoRoute(path: '/user/info', builder: (_, __) => const UserInfoPage()),
          GoRoute(
            path: '/app/chat/:id',
            builder: (_, state) => AppChatPage(
              appId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/app/edit/:id',
            builder: (_, state) => AppEditPage(
              appId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(path: '/admin/userManage', builder: (_, __) => const UserManagePage()),
          GoRoute(path: '/admin/appManage', builder: (_, __) => const AppManagePage()),
          GoRoute(path: '/admin/chatManage', builder: (_, __) => const ChatManagePage()),
          GoRoute(path: '/401', builder: (_, __) => const NoAuthPage()),
        ],
      ),
    ],
  );
});
