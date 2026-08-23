import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starvive/config/router.dart';
import 'package:starvive/config/theme.dart';
import 'package:starvive/core/network/api_client.dart';
import 'package:starvive/providers/providers.dart';

class StarviveApp extends ConsumerStatefulWidget {
  const StarviveApp({super.key});

  @override
  ConsumerState<StarviveApp> createState() => _StarviveAppState();
}

class _StarviveAppState extends ConsumerState<StarviveApp> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await ApiClient.instance.init();
    await ref.read(authProvider.notifier).init();
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: '星衍',
      theme: AppTheme.light(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
