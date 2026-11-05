import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../notifications/viewmodels/notification_viewmodel.dart';
import '../../notifications/views/notification_screen.dart';
import '../../profile/views/profile_screen.dart';
import '../../settings/views/settings_page.dart';
import '../../template/views/template_dialogs.dart';
import '../../template/views/template_screen.dart';
import '../../timeblock/viewmodels/timeblock_viewmodel.dart';
import '../../timeblock/views/add_edit_timeblock_screen.dart';
import '../../timeblock/views/timeblock_home_tab.dart';
import '../../tribe/views/tribe_dialogs.dart';
import '../../tribe/views/tribe_list_screen.dart';
import '../viewmodels/home_viewmodel.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Nút "+" giữa thanh điều hướng: hành động theo mục đang mở.
  void _onAdd(BuildContext context, HomeViewModel home) {
    switch (home.currentDrawerIndex) {
      case HomeViewModel.personal:
        final date = context.read<TimeblockViewModel>().selectedDate;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddEditTimeblockScreen(initialDate: date),
          ),
        );
      case HomeViewModel.tribes:
        showTribeAddOptions(context);
      case HomeViewModel.templates:
        showTemplateAddOptions(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final home = context.watch<HomeViewModel>();
    final unread = context.watch<NotificationViewModel>().unreadCount;
    final cs = Theme.of(context).colorScheme;

    final sections = [
      (
        Icons.person_outline_rounded,
        l.personalSchedule,
        const TimeblockHomeTab() as Widget,
      ),
      (Icons.groups_outlined, l.tribes, const TribeListScreen() as Widget),
      (
        Icons.dashboard_customize_outlined,
        l.templates,
        const TemplateScreen() as Widget,
      ),
    ];
    final current = sections[home.currentDrawerIndex];

    final tabs = <Widget>[
      const ProfileScreen(),
      current.$3,
      const SizedBox.shrink(), // nút "+"
      const NotificationScreen(),
      const SettingsPage(),
    ];
    final showMainAppBar = home.currentTabIndex == 1;

    return Scaffold(
      key: _scaffoldKey,
      appBar: showMainAppBar
          ? AppBar(
              leading: IconButton(
                tooltip: l.menu,
                icon: const Icon(
                  Icons.menu,
                  color: AppColors.primary,
                  size: 28,
                ),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: Text(current.$2),
              actions: const [SizedBox(width: 56)],
            )
          : null,
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.78,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 28),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          width: 44,
                          height: 44,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.workspace,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l.workspaceSubtitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                for (int i = 0; i < sections.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _DrawerItem(
                      icon: sections[i].$1,
                      title: sections[i].$2,
                      selected: home.currentDrawerIndex == i,
                      onTap: () {
                        Navigator.pop(context);
                        home.changeDrawerSubFeature(i);
                      },
                    ),
                  ),
                const Spacer(),
                Center(
                  child: Text(
                    'TimeTribe v2.0.0',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.35),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: IndexedStack(index: home.currentTabIndex, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: cs.surface,
        currentIndex: home.currentTabIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: cs.onSurface.withValues(alpha: 0.4),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (i) => i == 2 ? _onAdd(context, home) : home.changeTab(i),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: l.profile,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: l.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(
              Icons.add_circle,
              size: 42,
              color: AppColors.primary,
            ),
            label: '',
            tooltip: l.add,
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              backgroundColor: AppColors.danger,
              child: const Icon(Icons.notifications_none_outlined),
            ),
            activeIcon: const Icon(Icons.notifications),
            label: l.notifications,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: l.settings,
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected
                  ? AppColors.primary
                  : cs.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? AppColors.primary : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
