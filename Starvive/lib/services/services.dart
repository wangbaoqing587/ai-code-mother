import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:starvive/core/network/api_client.dart';
import 'package:starvive/core/network/api_exception.dart';
import 'package:starvive/core/network/base_response.dart';
import 'package:starvive/models/models.dart';

class UserService {
  UserService(this._client);

  final ApiClient _client;

  Future<BaseResponse<LoginUser>> getLoginUser() {
    return _client.request(
      '/user/get/login',
      fromJsonT: (data) =>
          data != null ? LoginUser.fromJson(data as Map<String, dynamic>) : null,
    );
  }

  Future<BaseResponse<LoginUser>> login({
    required String userAccount,
    required String userPassword,
  }) {
    return _client.request(
      '/user/login',
      method: 'POST',
      data: {'userAccount': userAccount, 'userPassword': userPassword},
      fromJsonT: (data) =>
          data != null ? LoginUser.fromJson(data as Map<String, dynamic>) : null,
    );
  }

  Future<BaseResponse<String>> register({
    required String userAccount,
    required String userPassword,
    required String checkPassword,
    required int gender,
  }) {
    return _client.request(
      '/user/register',
      method: 'POST',
      data: {
        'userAccount': userAccount,
        'userPassword': userPassword,
        'checkPassword': checkPassword,
        'gender': gender,
      },
      fromJsonT: (data) => data?.toString(),
    );
  }

  Future<BaseResponse<bool>> logout() {
    return _client.request('/user/logout', method: 'POST',
        fromJsonT: (data) => data as bool?);
  }

  Future<BaseResponse<bool>> updateUser({
    required String id,
    String? userName,
    String? userAvatar,
    String? userProfile,
    int? gender,
    String? userRole,
  }) {
    return _client.request(
      '/user/update',
      method: 'POST',
      data: {
        'id': id,
        'userName': userName,
        'userAvatar': userAvatar,
        'userProfile': userProfile,
        'gender': gender,
        'userRole': userRole,
      },
      fromJsonT: (data) => data as bool?,
    );
  }

  Future<BaseResponse<PageResult<UserVO>>> listUserVoByPage(
    Map<String, dynamic> query,
  ) {
    return _client.request(
      '/user/list/page/vo',
      method: 'POST',
      data: query,
      fromJsonT: (data) => data != null
          ? PageResult.fromJson(
              data as Map<String, dynamic>,
              (json) => UserVO.fromJson(json),
            )
          : null,
    );
  }

  Future<BaseResponse<bool>> deleteUser(String id) {
    return _client.request(
      '/user/delete',
      method: 'POST',
      data: {'id': id},
      fromJsonT: (data) => data as bool?,
    );
  }
}

class AppService {
  AppService(this._client);

  final ApiClient _client;

  Future<BaseResponse<String>> addApp({String? initPrompt, String? appName}) {
    return _client.request(
      '/app/add',
      method: 'POST',
      data: {'initPrompt': initPrompt, 'appName': appName},
      fromJsonT: (data) => data?.toString(),
    );
  }

  Future<BaseResponse<AppVO>> getAppVoById(String id) {
    return _client.request(
      '/app/get/vo',
      queryParameters: {'id': id},
      fromJsonT: (data) =>
          data != null ? AppVO.fromJson(data as Map<String, dynamic>) : null,
    );
  }

  Future<BaseResponse<AppVO>> getAppByIdByAdmin(String id) {
    return _client.request(
      '/app/admin/get',
      queryParameters: {'id': id},
      fromJsonT: (data) =>
          data != null ? AppVO.fromJson(data as Map<String, dynamic>) : null,
    );
  }

  Future<BaseResponse<PageResult<AppVO>>> listMyAppVoByPage(
    Map<String, dynamic> query,
  ) {
    return _client.request(
      '/app/my/list/page/vo',
      method: 'POST',
      data: query,
      fromJsonT: (data) => data != null
          ? PageResult.fromJson(
              data as Map<String, dynamic>,
              (json) => AppVO.fromJson(json),
            )
          : null,
    );
  }

  Future<BaseResponse<PageResult<AppVO>>> listGoodAppVoByPage(
    Map<String, dynamic> query,
  ) {
    return _client.request(
      '/app/good/list/page/vo',
      method: 'POST',
      data: query,
      fromJsonT: (data) => data != null
          ? PageResult.fromJson(
              data as Map<String, dynamic>,
              (json) => AppVO.fromJson(json),
            )
          : null,
    );
  }

  Future<BaseResponse<PageResult<AppVO>>> listAppPlazaVoByPage(
    Map<String, dynamic> query,
  ) {
    return _client.request(
      '/app/plaza/list/page/vo',
      method: 'POST',
      data: query,
      fromJsonT: (data) => data != null
          ? PageResult.fromJson(
              data as Map<String, dynamic>,
              (json) => AppVO.fromJson(json),
            )
          : null,
    );
  }

  Future<BaseResponse<PageResult<AppVO>>> listAppVoByPageByAdmin(
    Map<String, dynamic> query,
  ) {
    return _client.request(
      '/app/admin/list/page/vo',
      method: 'POST',
      data: query,
      fromJsonT: (data) => data != null
          ? PageResult.fromJson(
              data as Map<String, dynamic>,
              (json) => AppVO.fromJson(json),
            )
          : null,
    );
  }

  Future<BaseResponse<bool>> updateApp({
    required String id,
    required String appName,
  }) {
    return _client.request(
      '/app/update',
      method: 'POST',
      data: {'id': id, 'appName': appName},
      fromJsonT: (data) => data as bool?,
    );
  }

  Future<BaseResponse<bool>> updateAppByAdmin({
    required String id,
    String? appName,
    String? cover,
    int? priority,
  }) {
    return _client.request(
      '/app/admin/update',
      method: 'POST',
      data: {
        'id': id,
        'appName': appName,
        'cover': cover,
        'priority': priority,
      },
      fromJsonT: (data) => data as bool?,
    );
  }

  Future<BaseResponse<bool>> deleteApp(String id) {
    return _client.request(
      '/app/delete',
      method: 'POST',
      data: {'id': id},
      fromJsonT: (data) => data as bool?,
    );
  }

  Future<BaseResponse<bool>> deleteAppByAdmin(String id) {
    return _client.request(
      '/app/admin/delete',
      method: 'POST',
      data: {'id': id},
      fromJsonT: (data) => data as bool?,
    );
  }

  Future<BaseResponse<String>> deployApp(String appId) {
    return _client.request(
      '/app/deploy',
      method: 'POST',
      data: {'appId': appId},
      fromJsonT: (data) => data as String?,
    );
  }

  Future<Uint8List> downloadAppCode(String appId) async {
    final response = await _client.download('/app/download/$appId');
    return Uint8List.fromList(response.data as List<int>);
  }

  Stream<String> generateCodeStream({
    required String appId,
    required String message,
  }) {
    final stream = _client.streamSse(
      '/app/chat/gen/code',
      queryParameters: {'appId': appId, 'message': message},
    );

    final controller = StreamController<String>();

    stream.listen(
      (event) {
        if (event.event == 'business-error') {
          try {
            final json = jsonDecode(event.data) as Map<String, dynamic>;
            controller.addError(
              ApiException(json['message'] as String? ?? '生成过程中出现错误'),
            );
          } catch (_) {
            controller.addError(ApiException('生成过程中出现错误'));
          }
          return;
        }
        if (event.event == 'done') {
          controller.close();
          return;
        }
        try {
          final parsed = jsonDecode(event.data) as Map<String, dynamic>;
          final chunk = parsed['d'];
          if (chunk != null) {
            controller.add(chunk.toString());
          }
        } catch (_) {
          if (event.data.isNotEmpty && event.data != '[DONE]') {
            controller.add(event.data);
          }
        }
      },
      onError: controller.addError,
      onDone: () {
        if (!controller.isClosed) controller.close();
      },
    );

    return controller.stream;
  }
}

class ChatHistoryService {
  ChatHistoryService(this._client);

  final ApiClient _client;

  Future<BaseResponse<PageResult<ChatHistory>>> listAppChatHistory({
    required String appId,
    int? pageSize,
    String? lastCreateTime,
  }) {
    return _client.request(
      '/chatHistory/app/$appId',
      queryParameters: {
        if (pageSize != null) 'pageSize': pageSize,
        if (lastCreateTime != null) 'lastCreateTime': lastCreateTime,
      },
      fromJsonT: (data) => data != null
          ? PageResult.fromJson(
              data as Map<String, dynamic>,
              (json) => ChatHistory.fromJson(json),
            )
          : null,
    );
  }

  Future<BaseResponse<PageResult<ChatHistory>>> listAllChatHistoryByPageForAdmin(
    Map<String, dynamic> query,
  ) {
    return _client.request(
      '/chatHistory/admin/list/page/vo',
      method: 'POST',
      data: query,
      fromJsonT: (data) => data != null
          ? PageResult.fromJson(
              data as Map<String, dynamic>,
              (json) => ChatHistory.fromJson(json),
            )
          : null,
    );
  }
}

String compressImageToBase64(Uint8List bytes, int maxEdge) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw ApiException('图片解析失败');

  final w = decoded.width;
  final h = decoded.height;
  final maxSide = w > h ? w : h;
  img.Image output = decoded;
  if (maxSide > maxEdge) {
    final scale = maxEdge / maxSide;
    output = img.copyResize(
      decoded,
      width: (w * scale).round(),
      height: (h * scale).round(),
    );
  }
  final encoded = img.encodeJpg(output, quality: 85);
  return 'data:image/jpeg;base64,${base64Encode(encoded)}';
}
