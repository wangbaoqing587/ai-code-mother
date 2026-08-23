import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:starvive/config/env.dart';
import 'package:starvive/core/constants/business_constants.dart';
import 'package:starvive/core/network/api_exception.dart';
import 'package:starvive/core/network/base_response.dart';

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;
  late final CookieJar _cookieJar;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final cookiePath = '${appDocDir.path}/.cookies/';
    _cookieJar = PersistCookieJar(storage: FileStorage(cookiePath));

    _dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 120),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(CookieManager(_cookieJar));
    _dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          final data = response.data;
          if (data is Map<String, dynamic>) {
            final code = data['code'] as int?;
            if (code == errorCodeNotLogin) {
              final url = response.requestOptions.path;
              if (!url.contains('/user/get/login') &&
                  !url.contains('/user/login')) {
                debugPrint('Session expired: $url');
              }
            }
          }
          handler.next(response);
        },
      ),
    );

    _initialized = true;
  }

  Dio get dio {
    if (!_initialized) {
      throw StateError('ApiClient not initialized');
    }
    return _dio;
  }

  Future<BaseResponse<T>> request<T>(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? queryParameters,
    dynamic data,
    T? Function(dynamic)? fromJsonT,
    Options? options,
  }) async {
    final response = await _dio.request(
      path,
      data: data,
      queryParameters: queryParameters,
      options: (options ?? Options()).copyWith(method: method),
    );
    return _parseResponse(response, fromJsonT);
  }

  BaseResponse<T> _parseResponse<T>(
    Response response,
    T? Function(dynamic)? fromJsonT,
  ) {
    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      return BaseResponse.fromJson(raw, fromJsonT);
    }
    throw ApiException('响应格式错误');
  }

  Future<Response> download(String path,
      {Map<String, dynamic>? queryParameters}) {
    return _dio.get(
      path,
      queryParameters: queryParameters,
      options: Options(responseType: ResponseType.bytes),
    );
  }

  Stream<SseEvent> streamSse(
    String path, {
    Map<String, String>? queryParameters,
  }) {
    final controller = StreamController<SseEvent>();
    final uri = Uri.parse('$apiBaseUrl$path').replace(
      queryParameters: queryParameters,
    );

    Future<void> run() async {
      try {
        final client = HttpClient();
        final request = await client.getUrl(uri);

        final cookies = await _cookieJar.loadForRequest(uri);
        if (cookies.isNotEmpty) {
          request.headers.set('Cookie', cookies.map((c) => '${c.name}=${c.value}').join('; '));
        }

        final response = await request.close();

        if (response.statusCode != 200) {
          final body = await response.transform(utf8.decoder).join();
          try {
            final json = jsonDecode(body) as Map<String, dynamic>;
            controller.addError(
              ApiException(
                json['message'] as String? ?? '请求失败',
                code: json['code'] as int?,
              ),
            );
          } catch (_) {
            controller.addError(
              ApiException('SSE 连接失败: ${response.statusCode}'),
            );
          }
          await controller.close();
          client.close();
          return;
        }

        String? currentEvent;
        final buffer = StringBuffer();

        await for (final chunk in response.transform(utf8.decoder)) {
          buffer.write(chunk);
          var content = buffer.toString();
          while (content.contains('\n')) {
            final index = content.indexOf('\n');
            final line = content.substring(0, index).trimRight();
            content = content.substring(index + 1);
            buffer.clear();
            buffer.write(content);

            if (line.isEmpty) continue;
            if (line.startsWith('event:')) {
              currentEvent = line.substring(6).trim();
            } else if (line.startsWith('data:')) {
              final data = line.substring(5).trim();
              controller.add(
                SseEvent(event: currentEvent ?? 'message', data: data),
              );
              if (currentEvent == 'done' || data == 'e') {
                await controller.close();
                client.close();
                return;
              }
            }
          }
        }
        await controller.close();
        client.close();
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
          await controller.close();
        }
      }
    }

    run();
    return controller.stream;
  }
}

class SseEvent {
  SseEvent({required this.event, required this.data});

  final String event;
  final String data;
}
