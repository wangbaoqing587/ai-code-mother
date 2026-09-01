import 'dart:io';

import 'package:starvive/core/constants/code_gen_type.dart';

const String defaultApiBaseUrl = 'http://192.168.24.106:8123/api';
const String defaultDeployDomain = 'http://192.168.24.106:8080';

String _defaultApiForPlatform() {
  if (Platform.isAndroid) {
    return 'http://192.168.24.106:8123/api';
  }
  return defaultApiBaseUrl;
}

String apiBaseUrl = _defaultApiForPlatform();
String deployDomain = defaultDeployDomain;

void configureEnv({String? apiUrl, String? deployUrl}) {
  if (apiUrl != null && apiUrl.isNotEmpty) {
    apiBaseUrl = apiUrl;
  }
  if (deployUrl != null && deployUrl.isNotEmpty) {
    deployDomain = deployUrl;
  }
}

String get staticBaseUrl => '$apiBaseUrl/static';

String getDeployUrl(String deployKey, String? codeGenType) {
  final baseUrl = '$deployDomain/$deployKey';
  if (codeGenType == CodeGenType.vueProject) {
    return '$baseUrl/dist/index.html';
  }
  return baseUrl;
}

String getStaticPreviewUrl(String codeGenType, String appId) {
  final baseUrl = '$staticBaseUrl/${codeGenType}_$appId/';
  if (codeGenType == CodeGenType.vueProject) {
    return '${baseUrl}dist/index.html';
  }
  return baseUrl;
}
