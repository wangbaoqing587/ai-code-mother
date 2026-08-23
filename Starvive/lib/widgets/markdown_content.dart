import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:starvive/core/constants/app_constants.dart';

class MarkdownContent extends StatelessWidget {
  const MarkdownContent({super.key, required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(
          fontSize: 14,
          height: 1.6,
          color: AppColors.textSecondary,
        ),
        code: TextStyle(
          fontSize: 13,
          backgroundColor: Colors.grey.shade100,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
