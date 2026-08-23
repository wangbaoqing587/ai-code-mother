import 'package:flutter/material.dart';
import 'package:starvive/core/constants/app_constants.dart';

enum PromptVariant { hero, chat }

class PromptInputBox extends StatelessWidget {
  const PromptInputBox({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.placeholder = '请输入提示词',
    this.loading = false,
    this.disabled = false,
    this.variant = PromptVariant.hero,
    this.minLines = 2,
    this.maxLines = 6,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final String placeholder;
  final bool loading;
  final bool disabled;
  final PromptVariant variant;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final isHero = variant == PromptVariant.hero;
    return Container(
      margin: isHero ? null : const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isHero ? 20 : 16),
        border: Border.all(
          color: isHero
              ? AppColors.mintBorder
              : AppColors.mintBorder.withValues(alpha: 0.5),
          width: isHero ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.mintLight.withValues(alpha: isHero ? 0.18 : 0.1),
            blurRadius: isHero ? 24 : 12,
            offset: Offset(0, isHero ? 8 : 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            enabled: !disabled && !loading,
            minLines: minLines,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(color: AppColors.textPlaceholder),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: (disabled || loading || controller.text.trim().isEmpty)
                  ? null
                  : onSubmit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(88, 38),
                backgroundColor: AppColors.mintPrimary,
                disabledBackgroundColor:
                    AppColors.mintPrimary.withValues(alpha: 0.4),
              ),
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('生成'),
            ),
          ),
        ],
      ),
    );
  }
}
