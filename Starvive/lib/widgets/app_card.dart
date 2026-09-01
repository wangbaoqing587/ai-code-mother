import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starvive/config/env.dart';
import 'package:starvive/core/constants/app_constants.dart';
import 'package:starvive/models/models.dart';
import 'package:starvive/providers/providers.dart';
import 'package:starvive/widgets/code_gen_type_tag.dart';
import 'package:starvive/widgets/user_avatar.dart';
import 'package:url_launcher/url_launcher.dart';

class AppCard extends ConsumerWidget {
  const AppCard({super.key, required this.app});

  final AppVO app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coverUrl = app.cover?.isNotEmpty == true
        ? app.cover!
        : AppAssets.productCoverDefault;
    final isAsset = !coverUrl.startsWith('http') && !coverUrl.startsWith('data:');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.cardBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.mintLight.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (isAsset)
                  Image.asset(coverUrl, fit: BoxFit.cover)
                else if (coverUrl.startsWith('data:image'))
                  Image.memory(
                    Uri.dataFromString(coverUrl).data!.contentAsBytes(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Image.asset(AppAssets.productCoverDefault, fit: BoxFit.cover),
                  )
                else
                  Image.network(
                    coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Image.asset(AppAssets.productCoverDefault, fit: BoxFit.cover),
                  ),
                Container(
                  color: Colors.black.withValues(alpha: 0.02),
                  child: Center(
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      alignment: WrapAlignment.center,
                      children: [
                        _ActionBtn(
                          label: '查看对话',
                          primary: true,
                          onTap: () {
                            if (app.id != null) {
                              ref.read(currentChatAppIdProvider.notifier).state =
                                  app.id;
                              ref.read(mainTabIndexProvider.notifier).state = 0;
                            }
                          },
                        ),
                        if (app.deployKey != null)
                          _ActionBtn(
                            label: '查看作品',
                            onTap: () {
                              final url = getDeployUrl(
                                app.deployKey!,
                                app.codeGenType,
                              );
                              launchUrl(Uri.parse(url),
                                  mode: LaunchMode.externalApplication);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              14,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                UserAvatar(size: 36, src: app.user?.userAvatar, gender: app.user?.gender),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              app.appName ?? '未命名应用',
                              style: const TextStyle(
                                fontSize: AppFontSize.md,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (app.codeGenType != null)
                            CodeGenTypeTag(codeGenType: app.codeGenType!),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        app.user?.userName ?? '未知用户',
                        style: const TextStyle(
                          fontSize: AppFontSize.sm,
                          color: Colors.black45,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary ? AppColors.mintPrimary : Colors.white,
      borderRadius: BorderRadius.circular(999),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Text(
            label,
            style: TextStyle(
              color: primary ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: AppFontSize.sm,
            ),
          ),
        ),
      ),
    );
  }
}
