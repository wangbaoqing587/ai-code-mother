import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> saveBytesToFile(List<int> bytes, String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);
  return file.path;
}

String? parseFilenameFromContentDisposition(String? header, String fallback) {
  if (header == null) return fallback;
  final match = RegExp(r'filename="?([^";]+)"?').firstMatch(header);
  return match?.group(1) ?? fallback;
}
