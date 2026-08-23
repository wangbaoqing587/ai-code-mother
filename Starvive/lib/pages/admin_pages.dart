import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:starvive/core/constants/app_constants.dart';
import 'package:starvive/core/constants/business_constants.dart';
import 'package:starvive/core/constants/code_gen_type.dart';
import 'package:starvive/core/utils/format_utils.dart';
import 'package:starvive/models/models.dart';
import 'package:starvive/providers/providers.dart';
import 'package:starvive/widgets/code_gen_type_tag.dart';
import 'package:starvive/widgets/home_background.dart';
import 'package:starvive/widgets/user_avatar.dart';

class UserManagePage extends ConsumerStatefulWidget {
  const UserManagePage({super.key});

  @override
  ConsumerState<UserManagePage> createState() => _UserManagePageState();
}

class _UserManagePageState extends ConsumerState<UserManagePage> {
  List<UserVO> _list = [];
  int _total = 0;
  bool _loading = false;
  int _pageNum = 1;
  int _pageSize = adminPageSize;
  String? _accountFilter;
  String? _nameFilter;
  String? _roleFilter;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ref.read(userServiceProvider).listUserVoByPage({
        'pageNum': _pageNum,
        'pageSize': _pageSize,
        if (_accountFilter != null) 'userAccount': _accountFilter,
        if (_nameFilter != null) 'userName': _nameFilter,
        if (_roleFilter != null) 'userRole': _roleFilter,
      });
      if (res.isSuccess && res.data != null) {
        setState(() {
          _list = res.data!.records ?? [];
          _total = res.data!.totalRow ?? 0;
        });
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _editUser(UserVO user) async {
    if (user.userRole == userRoleAdmin) return;
    final nameController = TextEditingController(text: user.userName);
    final profileController = TextEditingController(text: user.userProfile);
    String role = user.userRole ?? userRoleUser;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('编辑用户'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: '用户名')),
              TextField(controller: profileController, decoration: const InputDecoration(labelText: '简介')),
              DropdownButtonFormField<String>(
                value: role,
                items: const [
                  DropdownMenuItem(value: userRoleUser, child: Text('用户')),
                  DropdownMenuItem(value: userRoleAdmin, child: Text('管理员')),
                ],
                onChanged: (v) => role = v ?? userRoleUser,
                decoration: const InputDecoration(labelText: '角色'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              final res = await ref.read(userServiceProvider).updateUser(
                    id: user.id!,
                    userName: nameController.text,
                    userProfile: profileController.text,
                    userRole: role,
                  );
              if (res.isSuccess) {
                Navigator.pop(context);
                _fetch();
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(UserVO user) async {
    if (user.userRole == userRoleAdmin) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认删除用户？'),
        content: Text('账号：${user.userAccount}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final res = await ref.read(userServiceProvider).deleteUser(user.id!);
      if (res.isSuccess) _fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminListScaffold(
      title: '用户管理',
      loading: _loading,
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 160,
                child: TextField(
                  decoration: const InputDecoration(labelText: '账号'),
                  onChanged: (v) => _accountFilter = v.isEmpty ? null : v,
                ),
              ),
              SizedBox(
                width: 160,
                child: TextField(
                  decoration: const InputDecoration(labelText: '用户名'),
                  onChanged: (v) => _nameFilter = v.isEmpty ? null : v,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _pageNum = 1;
                  _fetch();
                },
                child: const Text('搜索'),
              ),
              OutlinedButton(
                onPressed: () {
                  _accountFilter = null;
                  _nameFilter = null;
                  _roleFilter = null;
                  _pageNum = 1;
                  _fetch();
                },
                child: const Text('重置'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('id')),
                  DataColumn(label: Text('账号')),
                  DataColumn(label: Text('用户名')),
                  DataColumn(label: Text('头像')),
                  DataColumn(label: Text('简介')),
                  DataColumn(label: Text('角色')),
                  DataColumn(label: Text('创建时间')),
                  DataColumn(label: Text('操作')),
                ],
                rows: _list.map((user) {
                  return DataRow(cells: [
                    DataCell(Text(user.id ?? '-')),
                    DataCell(Text(user.userAccount ?? '-')),
                    DataCell(Text(user.userName ?? '-')),
                    DataCell(UserAvatar(size: 28, src: user.userAvatar)),
                    DataCell(Text(
                      user.userProfile?.trim().isNotEmpty == true
                          ? user.userProfile!
                          : '该用户还没有填写简介',
                    )),
                    DataCell(Text(user.userRole ?? '-')),
                    DataCell(Text(formatDateTime(user.createTime))),
                    DataCell(Row(
                      children: [
                        if (user.userRole != userRoleAdmin)
                          TextButton(onPressed: () => _editUser(user), child: const Text('编辑')),
                        if (user.userRole != userRoleAdmin)
                          TextButton(
                            onPressed: () => _deleteUser(user),
                            child: const Text('删除', style: TextStyle(color: Colors.red)),
                          ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
          _Pagination(
            pageNum: _pageNum,
            pageSize: _pageSize,
            total: _total,
            onChange: (p) {
              _pageNum = p;
              _fetch();
            },
          ),
        ],
      ),
    );
  }
}

class AppManagePage extends ConsumerStatefulWidget {
  const AppManagePage({super.key});

  @override
  ConsumerState<AppManagePage> createState() => _AppManagePageState();
}

class _AppManagePageState extends ConsumerState<AppManagePage> {
  List<AppVO> _list = [];
  int _total = 0;
  bool _loading = false;
  int _pageNum = 1;
  int _pageSize = adminPageSize;
  String? _nameFilter;
  String? _typeFilter;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ref.read(appServiceProvider).listAppVoByPageByAdmin({
        'pageNum': _pageNum,
        'pageSize': _pageSize,
        if (_nameFilter != null) 'appName': _nameFilter,
        if (_typeFilter != null) 'codeGenType': _typeFilter,
      });
      if (res.isSuccess && res.data != null) {
        setState(() {
          _list = res.data!.records ?? [];
          _total = res.data!.totalRow ?? 0;
        });
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _setFeatured(AppVO app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认设为精选？'),
        content: Text('应用：${app.appName ?? app.id}，优先级将设为 $goodAppPriority'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final res = await ref.read(appServiceProvider).updateAppByAdmin(
            id: app.id!,
            priority: goodAppPriority,
          );
      if (res.isSuccess) _fetch();
    }
  }

  Future<void> _deleteApp(AppVO app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认删除应用？'),
        content: Text('应用：${app.appName ?? app.id}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final res = await ref.read(appServiceProvider).deleteAppByAdmin(app.id!);
      if (res.isSuccess) _fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminListScaffold(
      title: '应用管理',
      loading: _loading,
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 180,
                child: TextField(
                  decoration: const InputDecoration(labelText: '应用名称'),
                  onChanged: (v) => _nameFilter = v.isEmpty ? null : v,
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: '生成类型'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('全部')),
                    ...codeGenTypeOptions.map(
                      (o) => DropdownMenuItem(value: o.value, child: Text(o.label)),
                    ),
                  ],
                  onChanged: (v) => _typeFilter = v,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _pageNum = 1;
                  _fetch();
                },
                child: const Text('搜索'),
              ),
              OutlinedButton(
                onPressed: () {
                  _nameFilter = null;
                  _typeFilter = null;
                  _pageNum = 1;
                  _fetch();
                },
                child: const Text('重置'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('id')),
                  DataColumn(label: Text('应用名称')),
                  DataColumn(label: Text('生成类型')),
                  DataColumn(label: Text('优先级')),
                  DataColumn(label: Text('创建者')),
                  DataColumn(label: Text('创建时间')),
                  DataColumn(label: Text('操作')),
                ],
                rows: _list.map((app) {
                  return DataRow(cells: [
                    DataCell(Text(app.id ?? '-')),
                    DataCell(Text(app.appName ?? '-')),
                    DataCell(app.codeGenType != null
                        ? CodeGenTypeTag(codeGenType: app.codeGenType!)
                        : const Text('-')),
                    DataCell(Text(app.priority?.toString() ?? '-')),
                    DataCell(Text(app.user?.userName ?? '-')),
                    DataCell(Text(formatDateTime(app.createTime))),
                    DataCell(Row(
                      children: [
                        TextButton(
                          onPressed: () => context.push('/app/edit/${app.id}'),
                          child: const Text('编辑'),
                        ),
                        TextButton(
                          onPressed: () => context.push('/app/chat/${app.id}'),
                          child: const Text('对话'),
                        ),
                        if (app.priority != goodAppPriority)
                          TextButton(
                            onPressed: () => _setFeatured(app),
                            child: const Text('设为精选'),
                          ),
                        TextButton(
                          onPressed: () => _deleteApp(app),
                          child: const Text('删除', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
          _Pagination(
            pageNum: _pageNum,
            pageSize: _pageSize,
            total: _total,
            onChange: (p) {
              _pageNum = p;
              _fetch();
            },
          ),
        ],
      ),
    );
  }
}

class ChatManagePage extends ConsumerStatefulWidget {
  const ChatManagePage({super.key});

  @override
  ConsumerState<ChatManagePage> createState() => _ChatManagePageState();
}

class _ChatManagePageState extends ConsumerState<ChatManagePage> {
  List<ChatHistory> _list = [];
  int _total = 0;
  bool _loading = false;
  int _pageNum = 1;
  int _pageSize = adminPageSize;
  String? _messageFilter;
  String? _typeFilter;
  String? _appIdFilter;
  String? _userIdFilter;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res =
          await ref.read(chatHistoryServiceProvider).listAllChatHistoryByPageForAdmin({
        'pageNum': _pageNum,
        'pageSize': _pageSize,
        if (_messageFilter != null) 'message': _messageFilter,
        if (_typeFilter != null) 'messageType': _typeFilter,
        if (_appIdFilter != null) 'appId': _appIdFilter,
        if (_userIdFilter != null) 'userId': _userIdFilter,
      });
      if (res.isSuccess && res.data != null) {
        setState(() {
          _list = res.data!.records ?? [];
          _total = res.data!.totalRow ?? 0;
        });
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminListScaffold(
      title: '对话管理',
      loading: _loading,
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 200,
                child: TextField(
                  decoration: const InputDecoration(labelText: '消息内容'),
                  onChanged: (v) => _messageFilter = v.isEmpty ? null : v,
                ),
              ),
              SizedBox(
                width: 140,
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: '消息类型'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('全部')),
                    DropdownMenuItem(value: 'user', child: Text('用户')),
                    DropdownMenuItem(value: 'ai', child: Text('AI')),
                  ],
                  onChanged: (v) => _typeFilter = v,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _pageNum = 1;
                  _fetch();
                },
                child: const Text('搜索'),
              ),
              OutlinedButton(
                onPressed: () {
                  _messageFilter = null;
                  _typeFilter = null;
                  _appIdFilter = null;
                  _userIdFilter = null;
                  _pageNum = 1;
                  _fetch();
                },
                child: const Text('重置'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('id')),
                  DataColumn(label: Text('消息内容')),
                  DataColumn(label: Text('消息类型')),
                  DataColumn(label: Text('应用 id')),
                  DataColumn(label: Text('用户 id')),
                  DataColumn(label: Text('创建时间')),
                ],
                rows: _list.map((item) {
                  return DataRow(cells: [
                    DataCell(Text(item.id ?? '-')),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 300),
                        child: Text(item.message ?? '-', overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    DataCell(Text(formatMessageType(item.messageType))),
                    DataCell(Text(item.appId ?? '-')),
                    DataCell(Text(item.userId ?? '-')),
                    DataCell(Text(formatDateTime(item.createTime))),
                  ]);
                }).toList(),
              ),
            ),
          ),
          _Pagination(
            pageNum: _pageNum,
            pageSize: _pageSize,
            total: _total,
            onChange: (p) {
              _pageNum = p;
              _fetch();
            },
          ),
        ],
      ),
    );
  }
}

class AdminListScaffold extends StatelessWidget {
  const AdminListScaffold({
    super.key,
    required this.title,
    required this.loading,
    required this.child,
  });

  final String title;
  final bool loading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return HomeBackground(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.adminBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.pageNum,
    required this.pageSize,
    required this.total,
    required this.onChange,
  });

  final int pageNum;
  final int pageSize;
  final int total;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    final totalPages = (total / pageSize).ceil().clamp(1, 999999);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: pageNum > 1 ? () => onChange(pageNum - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('$pageNum / $totalPages'),
          IconButton(
            onPressed: pageNum < totalPages ? () => onChange(pageNum + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class NoAuthPage extends StatelessWidget {
  const NoAuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeBackground(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '401',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('无权访问该页面'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    );
  }
}
