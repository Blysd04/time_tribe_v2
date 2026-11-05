import 'package:flutter/material.dart';

/// Thẻ hoạt động trên lưới thời gian — dùng chung cho cá nhân, nhóm, lịch mẫu.
///
/// - [outlined]: viền nét, nền nhạt (VD hoạt động nhóm đang chờ xác nhận).
/// - [dimmed]: mờ đi (đã qua / không tham gia).
/// - [footer]: dòng phụ dưới cùng khi thẻ đủ cao (VD số người tham gia).
class TimeblockCard extends StatelessWidget {
  final String title;
  final String timeLabel;
  final Color color;
  final IconData? icon;
  final String? caption;
  final Widget? footer;
  final Widget? badge;
  final bool outlined;
  final bool dimmed;
  final bool done;
  final VoidCallback? onTap;

  const TimeblockCard({
    super.key,
    required this.title,
    required this.timeLabel,
    required this.color,
    this.icon,
    this.caption,
    this.footer,
    this.badge,
    this.outlined = false,
    this.dimmed = false,
    this.done = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = outlined ? color : Colors.white;
    final fgSoft = outlined ? color.withValues(alpha: 0.8) : Colors.white70;
    final surface = Theme.of(context).colorScheme.surface;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: dimmed ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: outlined
                ? Color.alphaBlend(color.withValues(alpha: 0.10), surface)
                : color,
            borderRadius: BorderRadius.circular(12),
            border: outlined ? Border.all(color: color, width: 1.4) : null,
            boxShadow: outlined || dimmed
                ? null
                : [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              if (c.maxHeight < 16) return const SizedBox.shrink();
              final small = TextStyle(
                color: fgSoft,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              );
              return ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  maxHeight: double.infinity,
                  child: SizedBox(
                    height: c.maxHeight < 64 ? null : c.maxHeight,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (icon != null) ...[
                              Icon(icon, size: 13, color: fg),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: fg,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (done)
                              Icon(Icons.check_circle, color: fg, size: 14),
                          ],
                        ),
                        if (c.maxHeight >= 40)
                          Text(
                            timeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: small,
                          ),
                        if (caption != null && c.maxHeight >= 56)
                          Text(
                            caption!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: small,
                          ),
                        if ((footer != null || badge != null) &&
                            c.maxHeight >= 64) ...[
                          const Spacer(),
                          Row(
                            children: [
                              if (footer != null)
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: DefaultTextStyle(
                                      style: small,
                                      child: IconTheme(
                                        data: IconThemeData(
                                          color: fg,
                                          size: 11,
                                        ),
                                        child: footer!,
                                      ),
                                    ),
                                  ),
                                ),
                              const Spacer(),
                              ?badge,
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Nhãn nhỏ nổi trên thẻ, VD "Chờ bạn".
class CardBadge extends StatelessWidget {
  final String text;
  final Color color;
  final bool inverted;

  const CardBadge(
    this.text, {
    super.key,
    required this.color,
    this.inverted = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(
      color: inverted ? color : Colors.white,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.bold,
        color: inverted ? Colors.white : color,
      ),
    ),
  );
}
