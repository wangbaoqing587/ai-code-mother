import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starvive/app.dart';
import 'package:starvive/config/env.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  const apiFromDefine = String.fromEnvironment('API_BASE_URL');
  const deployFromDefine = String.fromEnvironment('DEPLOY_DOMAIN');
  if (apiFromDefine.isNotEmpty || deployFromDefine.isNotEmpty) {
    configureEnv(
      apiUrl: apiFromDefine.isNotEmpty ? apiFromDefine : null,
      deployUrl: deployFromDefine.isNotEmpty ? deployFromDefine : null,
    );
  }

  runApp(const ProviderScope(child: StarviveApp()));
}
