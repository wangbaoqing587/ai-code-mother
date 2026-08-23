import 'package:intl/intl.dart';

String formatDateTime(String? value) {
  if (value == null || value.isEmpty) return '-';
  try {
    final date = DateTime.parse(value);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  } catch (_) {
    return value;
  }
}

String formatRegisterDate(String? value) {
  if (value == null || value.isEmpty) return '-';
  try {
    final date = DateTime.parse(value);
    return DateFormat('yyyy年MM月dd日').format(date);
  } catch (_) {
    return value;
  }
}

String formatMessageType(String? messageType) {
  if (messageType == 'user' || messageType == 'USER') return '用户';
  if (messageType == 'ai' || messageType == 'AI') return 'AI';
  return messageType ?? '-';
}

String createMessageId() {
  return '${DateTime.now().millisecondsSinceEpoch}-${DateTime.now().microsecond}';
}
