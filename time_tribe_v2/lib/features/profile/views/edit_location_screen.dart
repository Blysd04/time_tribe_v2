import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_time.dart';
import '../../../core/utils/timezone_locations.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/form_widgets.dart';
import '../viewmodels/profile_viewmodel.dart';

/// Khu vực & Múi giờ: tự động theo thiết bị, hoặc chọn thành phố.
class EditLocationScreen extends StatefulWidget {
  const EditLocationScreen({super.key});

  /// Tạo phần state giữ dữ liệu thay đổi của màn hình chọn khu vực và múi giờ.
  @override
  State<EditLocationScreen> createState() => _EditLocationScreenState();
}

class _EditLocationScreenState extends State<EditLocationScreen> {
  late bool _isAuto;
  String? _country;
  String? _city;

  /// Chạy một lần lúc màn hình chọn khu vực và múi giờ vừa được tạo, chuẩn bị dữ liệu ban đầu.
  @override
  void initState() {
    super.initState();
    final vm = context.read<ProfileViewModel>();
    _isAuto = vm.isAutoTimezone;
    final country = vm.manualCountry;
    if (country != null &&
        (kTimezoneLocations[country]?.any((c) => c.city == vm.manualCity) ??
            false)) {
      _country = country;
      _city = vm.manualCity;
    }
    vm.refreshDeviceTimezone(); // Đọc lại múi giờ thiết bị mỗi lần mở
  }

  /// Thành phố đang chọn trong danh sách, chưa chọn thì trả null.
  TimezoneCity? get _selected {
    if (_country == null || _city == null) return null;
    for (final c in kTimezoneLocations[_country!]!) {
      if (c.city == _city) return c;
    }
    return null;
  }

  /// Chữ GMT+07:00 tương ứng với một múi giờ IANA.
  String _offsetLabel(String timezoneId) {
    final offset = AppTime.offsetOf(timezoneId);
    return offset == null ? '' : AppTime.formatOffset(offset);
  }

  /// Bấm Lưu: hỏi xác nhận rồi áp dụng múi giờ tự động hoặc thành phố đã chọn (có gửi lên server).
  Future<void> _save(ProfileViewModel vm) async {
    final l = context.l10n;
    if (!_isAuto && _selected == null) {
      AppSnack.show(context, l.errorPickCountryCity, type: AppSnackType.error);
      return;
    }
    final ok = await AppDialogs.confirm(
      context,
      title: l.confirmSaveTitle,
      message: l.confirmSaveTimezone,
      confirmLabel: l.save,
    );
    if (!ok) return;
    _isAuto
        ? await vm.useDeviceTimezone()
        : await vm.useManualTimezone(_country!, _city!, _selected!.timezoneId);
    if (!mounted) return;
    Navigator.pop(context);
    AppSnack.show(context, l.saved);
  }

  /// Dựng giao diện màn hình chọn khu vực và múi giờ.
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.watch<ProfileViewModel>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l.regionTimezone),
        actions: [
          TextButton(onPressed: () => _save(vm), child: Text(l.save)),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          AppCard(
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              title: Text(
                l.autoTimezone,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${vm.deviceTimezoneLabel} (${vm.deviceTimezoneOffset})',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.55)),
              ),
              secondary: const IconBadge(icon: Icons.phone_android),
              value: _isAuto,
              onChanged: (v) => setState(() => _isAuto = v),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _isAuto ? 0.4 : 1,
            child: IgnorePointer(
              ignoring: _isAuto,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FieldLabel(l.country),
                  DropdownButtonFormField<String>(
                    initialValue: _country,
                    isExpanded: true,
                    hint: Text(l.chooseCountry),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    items: [
                      for (final code in kTimezoneLocations.keys)
                        DropdownMenuItem(
                          value: code,
                          child: Text(l.countryName(code)),
                        ),
                    ],
                    onChanged: (v) => setState(() {
                      _country = v;
                      _city = null;
                    }),
                  ),
                  const SizedBox(height: 16),
                  FieldLabel(l.city, hint: l.cityHint),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_country), // làm mới khi đổi quốc gia
                    initialValue: _city,
                    isExpanded: true,
                    hint: Text(l.chooseCity),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    items: [
                      for (final c
                          in kTimezoneLocations[_country] ??
                              const <TimezoneCity>[])
                        DropdownMenuItem(
                          value: c.city,
                          child: Text(
                            '${c.city} (${_offsetLabel(c.timezoneId)})',
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() => _city = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          InfoBanner(text: l.timezoneExplanation, color: AppColors.primary),
        ],
      ),
    );
  }
}
