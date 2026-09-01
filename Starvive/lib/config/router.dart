import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:starvive/pages/app_edit_page.dart';
import 'package:starvive/pages/auth_pages.dart';
import 'package:starvive/providers/providers.dart';
import 'package:starvive/widgets/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final path = state.uri.path;
      final isLoggedIn = auth.user.isLoggedIn;

      if (!auth.initialized) return null;

      final protectedRoutes = ['/app/edit'];
      if (protectedRoutes.any((r) => path.startsWith(r)) && !isLoggedIn) {
        return '/user/login?redirect=${Uri.encodeComponent(state.uri.toString())}';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const MainShell()),
      GoRoute(path: '/user/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/user/register', builder: (_, __) => const RegisterPage()),
      GoRoute(
        path: '/app/edit/:id',
        builder: (_, state) => AppEditPage(
          appId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
});
