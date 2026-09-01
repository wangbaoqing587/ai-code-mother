import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starvive/core/constants/app_constants.dart';
import 'package:starvive/pages/chat_tab_page.dart';
import 'package:starvive/pages/plaza_tab_page.dart';
import 'package:starvive/pages/profile_tab_page.dart';
import 'package:starvive/providers/providers.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _tabs = [
    _TabItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: '对话'),
    _TabItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view, label: '广场'),
    _TabItem(icon: Icons.person_outline, activeIcon: Icons.person, label: '我的'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mainTabIndexProvider);

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: currentIndex,
          children: const [
            ChatTabPage(),
            PlazaTabPage(),
            ProfileTabPage(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(mainTabIndexProvider.notifier).state = index;
        },
        backgroundColor: Colors.white,
        indicatorColor: AppColors.mintLight.withValues(alpha: 0.3),
        destinations: _tabs
            .map(
              (tab) => NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.activeIcon, color: AppColors.mintPrimary),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
