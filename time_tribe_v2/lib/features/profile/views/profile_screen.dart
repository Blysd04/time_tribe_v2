import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/app_user.dart';
import '../../../core/session/session.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../viewmodels/profile_viewmodel.dart';
import 'edit_location_screen.dart';
import 'edit_text_screen.dart';

extension ProfileTextsX on AppLocalizations {
  /// "Theo thiết bị · Asia/Ho_Chi_Minh (GMT+07:00)" hoặc "Tokyo, Nhật Bản (GMT+09:00)"
  String locationLabel(ProfileViewModel vm) {
    final place = vm.isAutoTimezone || vm.manualCity == null
        ? followDevice(vm.deviceTimezoneLabel)
        : '${vm.manualCity}, ${countryName(vm.manualCountry ?? '')}';
    return '$place (${vm.timezoneOffset})';
  }

  /// Câu báo lỗi khi sửa hồ sơ.
  String profileError(ProfileError e, {String? suggestion}) => switch (e) {
    ProfileError.emailInvalid => errorEmailInvalid,
    ProfileError.emailTypo =>
      suggestion == null ? errorEmailInvalid : errorEmailTypo(suggestion),
    ProfileError.emailDomainInvalid => errorEmailDomainInvalid,
    ProfileError.emailUnavailable => errorEmailUnavailable,
    ProfileError.emailTaken => errorEmailTaken,
    ProfileError.nameLength => errorNameLength,
    ProfileError.nameTaken => errorNameTaken,
    ProfileError.network => errorNetwork,
    ProfileError.server => errorServer,
  };
}

/// Bấm vào ảnh đại diện: chọn ảnh từ thư viện hoặc chụp ảnh mới rồi tải lên.
Future<void> pickAndUploadAvatar(BuildContext context) async {
  final l = context.l10n;
  final vm = context.read<ProfileViewModel>();
  ImageSource? source;
  await showOptionsSheet(
    context,
    title: l.changeAvatar,
    options: [
      SheetOption(
        icon: Icons.photo_library_outlined,
        title: l.pickFromGallery,
        onTap: () => source = ImageSource.gallery,
      ),
      SheetOption(
        icon: Icons.photo_camera_outlined,
        color: AppColors.success,
        title: l.takePhoto,
        onTap: () => source = ImageSource.camera,
      ),
    ],
  );
  if (source == null) return;
  XFile? file;
  try {
    file = await ImagePicker().pickImage(
      source: source!,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
  } catch (_) {
    file = null;
  }
  if (file == null || !context.mounted) return;
  final err = await vm.uploadAvatar(await file.readAsBytes(), file.name);
  if (!context.mounted) return;
  if (err == null) {
    AppSnack.show(context, l.avatarUpdated);
  } else {
    AppSnack.show(context, l.profileError(err), type: AppSnackType.error);
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  /// Mở tab hồ sơ thì tải lại từ server, để biết email mới đã được xác nhận chưa.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProfileViewModel>().reloadMe();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Quay lại app (thường là sau khi bấm link xác nhận trong hộp thư) thì tải lại hồ sơ.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        context.read<ProfileViewModel>().pendingEmail != null) {
      context.read<ProfileViewModel>().reloadMe();
    }
  }

  /// Hỏi lại rồi huỷ yêu cầu đổi email đang chờ xác nhận.
  Future<void> _cancelEmailChange(ProfileViewModel vm) async {
    final l = context.l10n;
    final ok = await AppDialogs.confirm(
      context,
      title: l.emailPendingCancel,
      message: l.emailPendingLabel(vm.pendingEmail ?? ''),
      confirmLabel: l.emailPendingCancel,
    );
    if (!ok || !mounted) return;
    final err = await vm.cancelEmailChange();
    if (!mounted) return;
    if (err == null) {
      AppSnack.show(context, l.emailPendingCancelled);
    } else {
      AppSnack.show(context, l.profileError(err), type: AppSnackType.error);
    }
  }

  /// Dựng giao diện tab Hồ sơ.
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.watch<ProfileViewModel>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l.profile)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          8,
          AppSpacing.page,
          24,
        ),
        children: [
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            margin: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                GestureDetector(
                  onTap: vm.uploadingAvatar
                      ? null
                      : () => pickAndUploadAvatar(context),
                  child: Stack(
                    children: [
                      UserAvatar(
                        user: AppUser(
                          id: Session.currentUserId,
                          nickName: vm.name,
                          avatarUrl: vm.avatarUrl,
                        ),
                        size: 96,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: cs.surface, width: 3),
                          ),
                          child: vm.uploadingAvatar
                              ? const SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.white,
                                  size: 15,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  vm.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  vm.email,
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.55)),
                ),
              ],
            ),
          ),
          AppSection(
            title: l.personalInfo,
            children: [
              AppListTile(
                icon: Icons.badge_outlined,
                title: l.displayName,
                subtitle: vm.name,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditTextScreen(
                      field: EditField.name,
                      initialValue: vm.name,
                    ),
                  ),
                ),
              ),
              AppListTile(
                icon: Icons.email_outlined,
                color: AppColors.success,
                title: l.email,
                subtitle: vm.pendingEmail == null
                    ? vm.email
                    : '${vm.email}\n${l.emailPendingLabel(vm.pendingEmail!)}',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditTextScreen(
                      field: EditField.email,
                      initialValue: vm.pendingEmail ?? vm.email,
                    ),
                  ),
                ),
              ),
              if (vm.pendingEmail != null)
                AppListTile(
                  icon: Icons.cancel_schedule_send_outlined,
                  color: AppColors.warning,
                  title: l.emailPendingCancel,
                  subtitle: l.emailPendingHint,
                  onTap: () => _cancelEmailChange(vm),
                ),
              AppListTile(
                icon: Icons.public,
                color: const Color(0xFF9B5DE5),
                title: l.regionTimezone,
                subtitle: l.locationLabel(vm),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditLocationScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
