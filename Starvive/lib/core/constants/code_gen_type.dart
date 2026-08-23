class CodeGenType {
  static const html = 'html';
  static const multiFile = 'multi_file';
  static const vueProject = 'vue_project';
}

class CodeGenTypeOption {
  const CodeGenTypeOption({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final String color;
}

const codeGenTypeOptions = [
  CodeGenTypeOption(value: CodeGenType.html, label: '原生 HTML 模式', color: '#5b8ff9'),
  CodeGenTypeOption(value: CodeGenType.multiFile, label: '原生多文件模式', color: '#5b8ff9'),
  CodeGenTypeOption(value: CodeGenType.vueProject, label: 'Vue 工程模式', color: '#9270ca'),
];

CodeGenTypeOption? getCodeGenTypeOption(String? codeGenType) {
  if (codeGenType == null) return null;
  for (final item in codeGenTypeOptions) {
    if (item.value == codeGenType) return item;
  }
  return null;
}

String formatCodeGenType(String? codeGenType) {
  final option = getCodeGenTypeOption(codeGenType);
  return option?.label ?? codeGenType ?? '-';
}
