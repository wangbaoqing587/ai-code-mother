import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starvive/core/network/api_client.dart';
import 'package:starvive/models/models.dart';
import 'package:starvive/services/services.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient.instance);

final userServiceProvider = Provider<UserService>(
  (ref) => UserService(ref.watch(apiClientProvider)),
);

final appServiceProvider = Provider<AppService>(
  (ref) => AppService(ref.watch(apiClientProvider)),
);

final chatHistoryServiceProvider = Provider<ChatHistoryService>(
  (ref) => ChatHistoryService(ref.watch(apiClientProvider)),
);

class AuthState {
  const AuthState({
    this.user = const LoginUser(),
    this.isLoading = false,
    this.initialized = false,
  });

  final LoginUser user;
  final bool isLoading;
  final bool initialized;

  AuthState copyWith({
    LoginUser? user,
    bool? isLoading,
    bool? initialized,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      initialized: initialized ?? this.initialized,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._userService) : super(const AuthState());

  final UserService _userService;

  Future<void> init() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _userService.getLoginUser();
      if (res.isSuccess && res.data != null) {
        state = state.copyWith(user: res.data!, initialized: true, isLoading: false);
      } else {
        state = state.copyWith(initialized: true, isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(initialized: true, isLoading: false);
    }
  }

  Future<void> fetchLoginUser() async {
    final res = await _userService.getLoginUser();
    if (res.isSuccess && res.data != null) {
      state = state.copyWith(user: res.data!);
    }
  }

  void setLoginUser(LoginUser user) {
    state = state.copyWith(user: user);
  }

  Future<String?> login(String account, String password) async {
    final res = await _userService.login(
      userAccount: account,
      userPassword: password,
    );
    if (res.isSuccess && res.data != null) {
      state = state.copyWith(user: res.data!);
      return null;
    }
    return res.message ?? '登录失败';
  }

  Future<String?> register(
    String account,
    String password,
    String checkPassword,
    int gender,
  ) async {
    final res = await _userService.register(
      userAccount: account,
      userPassword: password,
      checkPassword: checkPassword,
      gender: gender,
    );
    if (res.isSuccess) return null;
    return res.message ?? '注册失败';
  }

  Future<String?> logout() async {
    final res = await _userService.logout();
    if (res.isSuccess) {
      state = state.copyWith(user: const LoginUser());
      return null;
    }
    return res.message ?? '退出失败';
  }

  Future<String?> updateProfile({
    required String id,
    String? userName,
    String? userAvatar,
    String? userProfile,
    int? gender,
    String? userRole,
  }) async {
    final res = await _userService.updateUser(
      id: id,
      userName: userName,
      userAvatar: userAvatar,
      userProfile: userProfile,
      gender: gender,
      userRole: userRole,
    );
    if (res.isSuccess) {
      await fetchLoginUser();
      return null;
    }
    return res.message ?? '保存失败';
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(userServiceProvider));
});

final mainTabIndexProvider = StateProvider<int>((ref) => 0);

final currentChatAppIdProvider = StateProvider<String?>((ref) => null);
