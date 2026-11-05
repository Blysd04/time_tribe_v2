import 'package:flutter/material.dart';

/// Logo TimeTribe. Ở chế độ tối, logo được đặt trên nền trắng bo góc để
/// chữ xanh đậm vẫn đọc rõ.
class AppLogo extends StatelessWidget {
  final double height;
  const AppLogo({super.key, this.height = 120});

  @override
  Widget build(BuildContext context) {
    final image = Image.asset('assets/images/splash_logo.png', height: height);
    if (Theme.of(context).brightness == Brightness.light) return image;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: image,
    );
  }
}
