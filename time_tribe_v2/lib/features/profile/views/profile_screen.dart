import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/app_user.dart';
import '../../../core/session/session.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
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
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                  onTap: vm.updateAvatar,
                  child: Stack(
                    children: [
                      UserAvatar(
                        user: AppUser(
                          id: Session.currentUserId,
                          nickName: vm.name,
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
                          child: const Icon(
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
                subtitle: vm.email,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditTextScreen(
                      field: EditField.email,
                      initialValue: vm.email,
                    ),
                  ),
                ),
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
