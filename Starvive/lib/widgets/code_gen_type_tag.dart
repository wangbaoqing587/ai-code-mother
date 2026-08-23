import 'package:flutter/material.dart';
import 'package:starvive/core/constants/code_gen_type.dart';

class CodeGenTypeTag extends StatelessWidget {
  const CodeGenTypeTag({super.key, required this.codeGenType});

  final String codeGenType;

  @override
  Widget build(BuildContext context) {
    final option = getCodeGenTypeOption(codeGenType);
    final color = _parseColor(option?.color ?? '#5b8ff9');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        option?.label ?? codeGenType,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  Color _parseColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }
}
