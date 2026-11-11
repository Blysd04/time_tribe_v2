import 'package:flutter/material.dart';

/// Vẽ sọc chéo (giống phác thảo) cho các khung "có người bận".
class HatchPainter extends CustomPainter {
  final Color color;
  final double gap;

  const HatchPainter({required this.color, this.gap = 8});

  /// Vẽ các sọc chéo báo giờ bận lên canvas.
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    for (double x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  /// Có cần vẽ lại các sọc chéo báo giờ bận không.
  @override
  bool shouldRepaint(HatchPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.gap != gap;
}
