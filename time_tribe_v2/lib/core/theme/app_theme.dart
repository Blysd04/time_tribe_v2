import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bảng màu dùng chung cho toàn app. Mọi màn hình lấy màu từ đây
/// thay vì tự ghi mã màu để giao diện luôn đồng nhất.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF3A86FF);
  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFF4A100);
  static const Color danger = Color(0xFFE5484D);
  static const Color leader = Color(0xFFE09F3E);
  static const Color night = Color(0xFF7986CB);

  /// Bảng màu chọn cho timeblock / nhóm.
  static const List<String> palette = [
    '#3A86FF',
    '#00B894',
    '#9B5DE5',
    '#FF007F',
    '#FFB703',
    '#FF7F50',
    '#0FA3B1',
    '#6C757D',
  ];

  /// Đổi mã màu "#RRGGBB" thành Color.
  static Color fromHex(String hex) =>
      Color(int.parse(hex.replaceAll('#', '0xFF')));

  /// Màu cố định theo id (avatar...).
  static Color seeded(String id) {
    const colors = [
      Color(0xFF3A86FF),
      Color(0xFF00B894),
      Color(0xFF9B5DE5),
      Color(0xFFFF7F50),
      Color(0xFFFF007F),
      Color(0xFF0FA3B1),
      Color(0xFFE09F3E),
      Color(0xFF6A4C93),
    ];
    return colors[id.hashCode.abs() % colors.length];
  }
}

/// Khoảng cách & bo góc chuẩn.
class AppSpacing {
  AppSpacing._();

  static const double page = 20;
  static const double radiusCard = 20;
  static const double radiusField = 12;
  static const double radiusSheet = 20;
}

class AppTheme {
  AppTheme._();

  static const Color primaryBlue = AppColors.primary;

  static const SystemUiOverlayStyle lightStatusBar = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, // Android
    statusBarBrightness: Brightness.light, // iOS
  );

  static const SystemUiOverlayStyle darkStatusBar = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );

  static final ThemeData lightTheme = _build(
    brightness: Brightness.light,
    scaffold: const Color(0xFFF8FAFC),
    surface: Colors.white,
    onSurface: Colors.black87,
    statusBar: lightStatusBar,
  );

  static final ThemeData darkTheme = _build(
    brightness: Brightness.dark,
    scaffold: const Color(0xFF0B1120),
    surface: const Color(0xFF161E31),
    onSurface: Colors.white,
    statusBar: darkStatusBar,
  );

  /// Tạo bộ theme dùng chung cho cả chế độ sáng và tối, chỉ khác màu nền và màu chữ.
  static ThemeData _build({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color onSurface,
    required SystemUiOverlayStyle statusBar,
  }) {
    final scheme = brightness == Brightness.light
        ? ColorScheme.light(
            primary: AppColors.primary,
            surface: surface,
            onSurface: onSurface,
            error: AppColors.danger,
          )
        : ColorScheme.dark(
            primary: AppColors.primary,
            surface: surface,
            onSurface: onSurface,
            error: AppColors.danger,
          );
    final fieldRadius = BorderRadius.circular(AppSpacing.radiusField);

    return ThemeData(
      brightness: brightness,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: scaffold,
      colorScheme: scheme,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: onSurface,
        systemOverlayStyle: statusBar,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          fontFamily: 'Roboto',
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.4)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(64, 48),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          minimumSize: const Size(64, 48),
          side: BorderSide(color: onSurface.withValues(alpha: 0.15)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: TextStyle(
          color: onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          fontFamily: 'Roboto',
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusSheet),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.primary : null,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: onSurface.withValues(alpha: 0.06),
        space: 1,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
