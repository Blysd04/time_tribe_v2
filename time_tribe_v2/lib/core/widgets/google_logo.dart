import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Logo chữ G nhiều màu của Google, vẽ bằng code nên không cần thêm file ảnh.
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 22});

  /// Dựng giao diện logo Google.
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  /// Vẽ 4 cung tròn màu xanh dương, xanh lá, vàng, đỏ và thanh ngang của chữ G.
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.2;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    double rad(double deg) => deg * math.pi / 180;

    // Góc 0 độ là phía bên phải, tăng theo chiều kim đồng hồ
    void arc(Color color, double from, double to) {
      canvas.drawArc(
        rect,
        rad(from),
        rad(to - from),
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
    }

    arc(_blue, 0, 48);
    arc(_green, 48, 145);
    arc(_yellow, 145, 215);
    arc(_red, 215, 318);

    // Thanh ngang màu xanh dương nối từ giữa ra mép phải
    final center = size.height / 2;
    canvas.drawRect(
      Rect.fromLTRB(
        size.width / 2,
        center - stroke / 2,
        size.width,
        center + stroke / 2,
      ),
      Paint()..color = _blue,
    );
  }

  /// Logo không bao giờ đổi nên không cần vẽ lại.
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
