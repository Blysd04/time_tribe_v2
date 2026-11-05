import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/tribe_model.dart';
import '../tribe_texts.dart';

/// Ảnh đại diện của nhóm: ô màu nhóm + chữ cái đầu.
class TribeAvatar extends StatelessWidget {
  final TribeModel tribe;
  final double size;

  const TribeAvatar({super.key, required this.tribe, this.size = 52});

  @override
  Widget build(BuildContext context) {
    final c = tribe.color;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.27),
        gradient: LinearGradient(
          colors: [c, Color.lerp(c, Colors.black, 0.25)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        tribe.name.characters.first.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.42,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Nhãn chức vụ nhỏ (Trưởng nhóm / Phó nhóm). Thành viên thường không hiện.
class RoleBadge extends StatelessWidget {
  final TribeRole role;
  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    if (role == TribeRole.member) return const SizedBox.shrink();
    final color = role == TribeRole.leader
        ? AppColors.leader
        : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            role == TribeRole.leader
                ? Icons.workspace_premium
                : Icons.shield_outlined,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            context.l10n.roleLabel(role),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
