import 'package:flutter/material.dart';
import 'package:starvive/core/constants/app_constants.dart';
import 'package:starvive/models/models.dart';
import 'package:starvive/widgets/app_card.dart';

class AppListSection extends StatelessWidget {
  const AppListSection({
    super.key,
    required this.title,
    required this.apps,
    required this.total,
    required this.loading,
    required this.pageNum,
    required this.pageSize,
    required this.onPageChange,
  });

  final String title;
  final List<AppVO> apps;
  final int total;
  final bool loading;
  final int pageNum;
  final int pageSize;
  final ValueChanged<int> onPageChange;

  @override
  Widget build(BuildContext context) {
    final totalPages = (total / pageSize).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900
                    ? 3
                    : constraints.maxWidth > 600
                        ? 2
                        : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: apps.length,
                  itemBuilder: (_, index) => AppCard(app: apps[index]),
                );
              },
            ),
          if (totalPages > 1)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: pageNum > 1
                        ? () => onPageChange(pageNum - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('$pageNum / $totalPages'),
                  IconButton(
                    onPressed: pageNum < totalPages
                        ? () => onPageChange(pageNum + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
