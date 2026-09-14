String? _jsonStringify(dynamic value) {
  if (value == null) return null;
  return value.toString();
}

int? _parseGender(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

class LoginUser {
  const LoginUser({
    this.id,
    this.userAccount,
    this.userName,
    this.userAvatar,
    this.userProfile,
    this.gender,
    this.userRole,
    this.createTime,
    this.updateTime,
  });

  factory LoginUser.fromJson(Map<String, dynamic> json) {
    return LoginUser(
      id: _jsonStringify(json['id']),
      userAccount: json['userAccount'] as String?,
      userName: json['userName'] as String?,
      userAvatar: json['userAvatar'] as String?,
      userProfile: json['userProfile'] as String?,
      gender: _parseGender(json['gender']),
      userRole: json['userRole'] as String?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }

  final String? id;
  final String? userAccount;
  final String? userName;
  final String? userAvatar;
  final String? userProfile;
  final int? gender;
  final String? userRole;
  final String? createTime;
  final String? updateTime;

  bool get isLoggedIn => id != null && id!.isNotEmpty;
  bool get isAdmin => userRole == 'admin';

  Map<String, dynamic> toJson() => {
        'id': id,
        'userAccount': userAccount,
        'userName': userName,
        'userAvatar': userAvatar,
        'userProfile': userProfile,
        'gender': gender,
        'userRole': userRole,
        'createTime': createTime,
        'updateTime': updateTime,
      };

}

class UserVO {
  UserVO({
    this.id,
    this.userAccount,
    this.userName,
    this.userAvatar,
    this.userProfile,
    this.gender,
    this.userRole,
    this.createTime,
  });

  factory UserVO.fromJson(Map<String, dynamic> json) {
    return UserVO(
      id: _jsonStringify(json['id']),
      userAccount: json['userAccount'] as String?,
      userName: json['userName'] as String?,
      userAvatar: json['userAvatar'] as String?,
      userProfile: json['userProfile'] as String?,
      gender: _parseGender(json['gender']),
      userRole: json['userRole'] as String?,
      createTime: json['createTime'] as String?,
    );
  }

  final String? id;
  final String? userAccount;
  final String? userName;
  final String? userAvatar;
  final String? userProfile;
  final int? gender;
  final String? userRole;
  final String? createTime;
}

class AppVO {
  AppVO({
    this.id,
    this.appName,
    this.cover,
    this.initPrompt,
    this.codeGenType,
    this.deployKey,
    this.deployedTime,
    this.priority,
    this.visibility,
    this.userId,
    this.createTime,
    this.updateTime,
    this.user,
  });

  factory AppVO.fromJson(Map<String, dynamic> json) {
    return AppVO(
      id: _jsonStringify(json['id']),
      appName: json['appName'] as String?,
      cover: json['cover'] as String?,
      initPrompt: json['initPrompt'] as String?,
      codeGenType: json['codeGenType'] as String?,
      deployKey: json['deployKey'] as String?,
      deployedTime: json['deployedTime'] as String?,
      priority: json['priority'] as int?,
      visibility: json['visibility'] as String?,
      userId: _jsonStringify(json['userId']),
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
      user: json['user'] != null
          ? UserVO.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  final String? id;
  final String? appName;
  final String? cover;
  final String? initPrompt;
  final String? codeGenType;
  final String? deployKey;
  final String? deployedTime;
  final int? priority;
  final String? visibility;
  final String? userId;
  final String? createTime;
  final String? updateTime;
  final UserVO? user;
}

class ChatHistory {
  ChatHistory({
    this.id,
    this.message,
    this.messageType,
    this.appId,
    this.userId,
    this.createTime,
    this.updateTime,
  });

  factory ChatHistory.fromJson(Map<String, dynamic> json) {
    return ChatHistory(
      id: _jsonStringify(json['id']),
      message: json['message'] as String?,
      messageType: json['messageType'] as String?,
      appId: _jsonStringify(json['appId']),
      userId: _jsonStringify(json['userId']),
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }

  final String? id;
  final String? message;
  final String? messageType;
  final String? appId;
  final String? userId;
  final String? createTime;
  final String? updateTime;

  bool get isUserMessage =>
      messageType == 'user' || messageType == 'USER';
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.createTime,
    this.isStreaming = false,
  });

  final String id;
  final String role;
  final String content;
  final String? createTime;
  final bool isStreaming;
}
