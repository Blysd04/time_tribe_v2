import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/form_widgets.dart';
import '../../tribe/viewmodels/tribe_viewmodel.dart';
import '../../tribe/views/widgets/tribe_block_response_buttons.dart';
import '../models/app_notification.dart';
import '../viewmodels/notification_viewmodel.dart';
import 'notification_text.dart';

/// Tab Thông báo: 30 ngày gần nhất, lọc theo Cá nhân hoặc từng nhóm.
/// Thanh lọc luôn hiện đủ các nhóm, kể cả nhóm chưa có thông báo nào.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with WidgetsBindingObserver {
  /// Vẽ lại mỗi 30 giây để nhãn "x phút trước" luôn đúng với giờ hiện tại
  /// (trước đây nhãn chỉ tính một lần nên để lâu sẽ hiện sai giờ).
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// App quay lại từ nền: tải lại danh sách (có thể đã có thông báo mới
  /// trong lúc app ở nền) và cập nhật nhãn thời gian.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<NotificationViewModel>().load(silent: true);
      setState(() {});
    }
  }

  /// Dựng giao diện tab Thông báo.
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.watch<NotificationViewModel>();
    final tribes = context.watch<TribeViewModel>().tribes;
    final cs = Theme.of(context).colorScheme;

    // Nhóm đang chọn đã bị rời/giải tán -> quay về "Toàn bộ"
    final filter = vm.selectedFilter;
    final validFilter =
        filter == NotificationFilter.all ||
        filter == NotificationFilter.personal ||
        tribes.any((t) => t.id == filter);
    if (!validFilter) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => vm.setFilter(NotificationFilter.all),
      );
    }

    final filters = <(String, String)>[
      (NotificationFilter.all, l.filterAll),
      (NotificationFilter.personal, l.filterPersonal),
      for (final t in tribes) (t.id, t.name),
    ];
    final items = vm.filteredNotifications;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.notifications),
        actions: [
          if (vm.unreadCount > 0)
            IconButton(
              tooltip: l.markAllRead,
              icon: const Icon(Icons.done_all),
              onPressed: vm.markAllAsRead,
            ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final (id, label) in filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 6),
                    child: AppFilterChip(
                      label: label,
                      count: vm.unreadCountFor(id),
                      selected: vm.selectedFilter == id,
                      onTap: () => vm.setFilter(id),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l.last30Days,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                // Kéo xuống để tải lại thông báo
                : RefreshIndicator(
                    onRefresh: vm.load,
                    child: items.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 80),
                              EmptyState(
                                icon: Icons.notifications_none_outlined,
                                title: l.noNotifications,
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            itemCount: items.length,
                            itemBuilder: (context, i) =>
                                _NotificationCard(item: items[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification item;
  const _NotificationCard({required this.item});

  /// Icon theo loại thông báo.
  IconData get _icon => switch (item.type) {
    'group_schedule' => Icons.event_available_outlined,
    'tribe_join' => Icons.group_add_outlined,
    'tribe_role' => Icons.workspace_premium_outlined,
    'reminder' => Icons.alarm_outlined,
    'system_broadcast' => Icons.campaign_outlined,
    _ => Icons.notifications_active_outlined,
  };

  /// "Vừa xong", "5 phút trước", "2 giờ trước", "3 ngày trước".
  String _timeAgo(AppLocalizations l) {
    final diff = DateTime.now().difference(item.createdAt);
    if (diff.inMinutes < 1) return l.justNow;
    if (diff.inHours < 1) return l.minutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return l.hoursAgo(diff.inHours);
    return l.daysAgo(diff.inDays);
  }

  /// Dựng giao diện thẻ một thông báo.
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.read<NotificationViewModel>();
    final cs = Theme.of(context).colorScheme;
    final tribe = item.tribeId == null
        ? null
        : context.watch<TribeViewModel>().tribeById(item.tribeId!);
    final unread = item.isUnread;
    final accent = tribe?.color ?? AppColors.primary;

    return GestureDetector(
      onTap: () => vm.markAsRead(item.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: unread
              ? Color.alphaBlend(
                  AppColors.primary.withValues(alpha: 0.06),
                  cs.surface,
                )
              : cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: unread
                ? AppColors.primary.withValues(alpha: 0.3)
                : cs.onSurface.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_icon, color: accent, size: 22),
                ),
                if (unread)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.surface, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.notificationTitle(item),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: unread
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 15,
                            color: unread
                                ? cs.onSurface
                                : cs.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _timeAgo(l),
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (tribe != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        tribe.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    l.notificationBody(item),
                    style: TextStyle(
                      color: cs.onSurface.withValues(
                        alpha: unread ? 0.8 : 0.55,
                      ),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  // Lời mời tham gia hoạt động nhóm: xác nhận ngay tại thông báo
                  if (item.isAttendanceRequest && item.referenceId != null)
                    TribeBlockResponseButtons(
                      blockId: item.referenceId!,
                      onResponded: () => vm.markAsRead(item.id),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
