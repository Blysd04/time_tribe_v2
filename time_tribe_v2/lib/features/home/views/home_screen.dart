import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/services/push_service.dart';
import '../../../core/session/app_reset.dart';
import '../../../core/theme/app_theme.dart';
import '../../notifications/viewmodels/notification_viewmodel.dart';
import '../../notifications/views/notification_screen.dart';
import '../../onboarding/onboarding_service.dart';
import '../../onboarding/views/home_tour.dart';
import '../../profile/views/profile_screen.dart';
import '../../settings/views/settings_page.dart';
import '../../template/views/template_dialogs.dart';
import '../../template/views/template_screen.dart';
import '../../timeblock/viewmodels/timeblock_viewmodel.dart';
import '../../timeblock/views/add_edit_timeblock_screen.dart';
import '../../timeblock/views/timeblock_home_tab.dart';
import '../../tribe/views/tribe_dialogs.dart';
import '../../tribe/viewmodels/tribe_viewmodel.dart';
import '../../tribe/views/tribe_list_screen.dart';
import '../viewmodels/home_viewmodel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  /// Tạo phần state giữ dữ liệu thay đổi của trang chủ.
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _tourKeys = HomeTourKeys();

  /// Mở hướng dẫn từng bước (người mới chọn "Tôi là người mới", hoặc bấm xem lại ở Cài đặt).
  /// Đưa về tab Trang chủ + Lịch cá nhân trước để các nút cần chỉ đều đang hiện.
  Future<void> _startTour() async {
    final home = context.read<HomeViewModel>();
    _scaffoldKey.currentState?.closeDrawer();
    home.changeDrawerSubFeature(HomeViewModel.personal);
    // Chờ hiệu ứng chuyển trang kết thúc và các nút được vẽ xong
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    HomeTour.show(context, _tourKeys);
  }

  /// Chạy một lần lúc trang chủ vừa được tạo, chuẩn bị dữ liệu ban đầu.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  /// Dọn controller, listener khi trang chủ bị đóng để không rò bộ nhớ.
  @override
  void dispose() {
    PushService.onMessage = null;
    PushService.onTokenRefresh = null;
    PushService.onOpenNotifications = null;
    super.dispose();
  }

  /// Vừa vào trang chủ: tải dữ liệu thật từ server và bật thông báo đẩy.
  Future<void> _bootstrap() async {
    final notifications = context.read<NotificationViewModel>();
    final tribes = context.read<TribeViewModel>();
    // Có thông báo đẩy mới lúc app đang mở thì tải lại thông báo và nhóm
    PushService.onMessage = () {
      notifications.load(silent: true);
      tribes.load();
    };
    // Bấm vào thông báo -> mở tab Thông báo (đóng các trang đang mở đè lên trang chủ)
    final home = context.read<HomeViewModel>();
    void openNotifications() {
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
      home.changeTab(3);
      notifications.load(silent: true);
    }

    PushService.onOpenNotifications = openNotifications;
    // Firebase cấp mã FCM mới thì gửi lên server
    PushService.onTokenRefresh = (token) {
      ApiClient.instance
          .put('/users/me/fcm-token', {'fcm_token': token})
          .catchError((_) => null);
    };
    final load = AppData.loadAll(context);
    await PushService.requestPermission();
    // Mỗi lần mở app đều gửi mã FCM hiện tại lên server. Trước đây chỉ gửi lúc bấm đăng nhập,
    // nên tự đăng nhập lại / cài lại app / server đã xoá mã thì users.fcm_token bị null
    // và không bao giờ nhận được thông báo đẩy.
    final token = await PushService.getToken();
    if (token != null && token.isNotEmpty) {
      ApiClient.instance
          .put('/users/me/fcm-token', {'fcm_token': token})
          .catchError((_) => null);
    }
    await load;
    if (await PushService.launchedFromNotification()) openNotifications();
  }

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

  /// Dựng giao diện trang chủ.
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final home = context.watch<HomeViewModel>();
    final unread = context.watch<NotificationViewModel>().unreadCount;
    if (Onboarding.pendingTour) {
      Onboarding.pendingTour = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _startTour());
    }
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
                key: _tourKeys.menu,
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
      body: KeyedSubtree(
        key: _tourKeys.content,
        child: IndexedStack(index: home.currentTabIndex, children: tabs),
      ),
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
            icon: Icon(Icons.person_outline, key: _tourKeys.profile),
            activeIcon: const Icon(Icons.person),
            label: l.profile,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: l.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.add_circle,
              key: _tourKeys.add,
              size: 42,
              color: AppColors.primary,
            ),
            label: '',
            tooltip: l.add,
          ),
          BottomNavigationBarItem(
            icon: Badge(
              key: _tourKeys.notifications,
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              backgroundColor: AppColors.danger,
              child: const Icon(Icons.notifications_none_outlined),
            ),
            activeIcon: const Icon(Icons.notifications),
            label: l.notifications,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined, key: _tourKeys.settings),
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

  /// Dựng giao diện một mục trong menu bên trái.
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
