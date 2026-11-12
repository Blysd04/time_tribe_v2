import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../features/home/viewmodels/home_viewmodel.dart';
import '../l10n/locale_provider.dart';
import '../../features/notifications/viewmodels/notification_viewmodel.dart';
import '../../features/profile/viewmodels/profile_viewmodel.dart';
import '../../features/template/viewmodels/template_viewmodel.dart';
import '../../features/timeblock/viewmodels/timeblock_viewmodel.dart';
import '../../features/tribe/viewmodels/tribe_viewmodel.dart';

/// Gom việc tải và xoá dữ liệu của mọi màn hình về một chỗ.
class AppData {
  AppData._();

  /// Sau khi đăng nhập (hoặc mở app đã có phiên): tải hồ sơ, nhóm, lịch, lịch mẫu, thông báo.
  static Future<void> loadAll(BuildContext context) async {
    final locale = context.read<LocaleProvider>();
    final profile = context.read<ProfileViewModel>();
    final tribes = context.read<TribeViewModel>();
    final timeblocks = context.read<TimeblockViewModel>();
    final templates = context.read<TemplateViewModel>();
    final notifications = context.read<NotificationViewModel>();
    // Gửi múi giờ trước để các API sau tính ngày theo đúng múi giờ
    await profile.loadFromSession();
    // Gửi ngôn ngữ đang dùng để thông báo đẩy đúng ngôn ngữ của app
    unawaited(locale.syncToServer());
    await Future.wait([
      tribes.load(),
      timeblocks.load(),
      templates.load(),
      notifications.load(),
    ]);
  }

  /// Đăng xuất hoặc bị đăng xuất: xoá dữ liệu của tài khoản cũ khỏi bộ nhớ, để tài khoản
  /// khác đăng nhập trên cùng máy không thấy dữ liệu của người trước.
  static void clearAll(BuildContext context) {
    context.read<TribeViewModel>().clear();
    context.read<TimeblockViewModel>().clear();
    context.read<TemplateViewModel>().clear();
    context.read<NotificationViewModel>().clear();
    context.read<ProfileViewModel>().clear();
    context.read<HomeViewModel>().reset();
  }
}
