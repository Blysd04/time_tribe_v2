import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../theme/app_theme.dart';

/// Avatar tròn: dùng ảnh nếu có `avatar_url`, nếu không thì hiện chữ cái đầu.
class UserAvatar extends StatelessWidget {
  final AppUser user;
  final double size;
  final Color? borderColor;

  const UserAvatar({
    super.key,
    required this.user,
    this.size = 32,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.seeded(user.id);
    // Avatar nhỏ chỉ hiện 1 chữ cho dễ đọc
    final text = size < 26 ? user.initials.characters.last : user.initials;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.alphaBlend(
          color.withValues(alpha: 0.18),
          Theme.of(context).colorScheme.surface,
        ),
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: 2),
        image: user.avatarUrl == null
            ? null
            : DecorationImage(
                image: NetworkImage(user.avatarUrl!),
                fit: BoxFit.cover,
              ),
      ),
      alignment: Alignment.center,
      child: user.avatarUrl != null
          ? null
          : Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.38,
              ),
            ),
    );
  }
}

/// Tối đa [max] avatar chồng lên nhau, phần còn lại hiện "+n".
class AvatarStack extends StatelessWidget {
  final List<AppUser> users;
  final int max;
  final double size;

  const AvatarStack({
    super.key,
    required this.users,
    this.max = 3,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shown = users.take(max).toList();
    final rest = users.length - shown.length;
    final step = size * 0.68;
    final count = shown.length + (rest > 0 ? 1 : 0);
    if (count == 0) return SizedBox(height: size);

    return SizedBox(
      height: size,
      width: size + (count - 1) * step,
      child: Stack(
        children: [
          for (int i = 0; i < shown.length; i++)
            Positioned(
              left: i * step,
              child: UserAvatar(
                user: shown[i],
                size: size,
                borderColor: cs.surface,
              ),
            ),
          if (rest > 0)
            Positioned(
              left: shown.length * step,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.alphaBlend(
                    cs.onSurface.withValues(alpha: 0.08),
                    cs.surface,
                  ),
                  border: Border.all(color: cs.surface, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$rest',
                  style: TextStyle(
                    fontSize: size * 0.34,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
