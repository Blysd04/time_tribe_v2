import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session.dart';
import '../models/template_model.dart';

/// Kết quả nhập lịch mẫu bằng mã chia sẻ.
enum TemplateImportResult {
  success,
  invalidCode,
  notFound,
  duplicate,
  limitExceeded,
  failed,
}

/// Kết quả áp dụng lịch mẫu vào lịch cá nhân.
class ApplyTemplateResult {
  /// Số hoạt động đã thêm và số hoạt động cũ bị thay thế.
  final int added;
  final int overwritten;

  /// Có trùng giờ mà chưa đồng ý thay thế: số hoạt động bị trùng và các ngày bị trùng.
  final int conflictCount;
  final List<DateTime> conflictDates;

  /// Mã lỗi khác (mất mạng...), null là không có lỗi.
  final String? error;

  const ApplyTemplateResult({
    this.added = 0,
    this.overwritten = 0,
    this.conflictCount = 0,
    this.conflictDates = const [],
    this.error,
  });

  /// Server báo có hoạt động bị trùng giờ và chưa thêm gì.
  bool get hasConflict => conflictCount > 0 && error == null && added == 0;
}

class TemplateLimits {
  static const int maxTemplates = 10;
}

class TemplateViewModel extends ChangeNotifier {
  TemplateViewModel({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  List<TemplateModel> _templates = [];

  /// Các lịch mẫu đã tải về.
  List<TemplateModel> get templates => _templates;

  bool _isLoading = false;

  /// Đang tải danh sách lịch mẫu hay không.
  bool get isLoading => _isLoading;

  TemplateModel? _draftTemplate;

  /// Bản nháp lịch mẫu chưa lưu (nếu có).
  TemplateModel? get draftTemplate => _draftTemplate;

  /// TP-01: tải danh sách lịch mẫu của mình.
  Future<void> load() async {
    if (Session.currentUserId.isEmpty) return;
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.get('/templates');
      _templates = [
        for (final j in (data['templates'] as List)) TemplateModel.fromJson(j),
      ];
    } on ApiException catch (e) {
      debugPrint('tải lịch mẫu lỗi: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Xoá dữ liệu khi đăng xuất.
  void clear() {
    _templates = [];
    _draftTemplate = null;
    notifyListeners();
  }

  /// TP-02: thoát màn hình khi chưa bấm Lưu thì giữ lại bản nháp trên máy.
  void saveDraft(TemplateModel draft) {
    _draftTemplate = draft;
    notifyListeners();
  }

  /// Bỏ bản nháp sau khi đã lưu thật.
  void clearDraft() {
    _draftTemplate = null;
    notifyListeners();
  }

  /// TP-02, TP-04, TP-05, TP-07: lưu lịch mẫu lên server (tạo mới hoặc ghi đè toàn bộ khối).
  /// Trả về mã lỗi nếu có, null là thành công.
  Future<String?> saveTemplate(
    TemplateModel template, {
    required bool isNew,
  }) async {
    try {
      final data = isNew
          ? await _api.post('/templates', template.toJson())
          : await _api.put('/templates/${template.id}', template.toJson());
      final saved = TemplateModel.fromJson(data);
      final index = _templates.indexWhere((t) => t.id == saved.id);
      if (index == -1) {
        _templates.insert(0, saved);
      } else {
        _templates[index] = saved;
      }
      _draftTemplate = null;
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.code;
    }
  }

  /// TP-06: xoá lịch mẫu.
  Future<bool> deleteTemplate(String id) async {
    try {
      await _api.delete('/templates/$id');
      _templates.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    } on ApiException {
      return false;
    }
  }

  /// TP-08: lấy mã chia sẻ (server tạo mới nếu mẫu chưa từng được chia sẻ).
  Future<String?> shareCodeOf(TemplateModel template) async {
    if (template.shareCode != null) return template.shareCode;
    try {
      final data = await _api.post('/templates/${template.id}/share');
      await load();
      return data['share_code'];
    } on ApiException {
      return null;
    }
  }

  /// TP-03: nhập lịch mẫu bằng mã chia sẻ người khác gửi.
  Future<TemplateImportResult> importByCode(String code) async {
    if (code.trim().isEmpty) return TemplateImportResult.invalidCode;
    if (_templates.length >= TemplateLimits.maxTemplates) {
      return TemplateImportResult.limitExceeded;
    }
    try {
      final data = await _api.post('/templates/import', {
        'share_code': code.trim(),
      });
      _templates.insert(0, TemplateModel.fromJson(data));
      notifyListeners();
      return TemplateImportResult.success;
    } on ApiException catch (e) {
      return switch (e.code) {
        'invalid_code' => TemplateImportResult.invalidCode,
        'not_found' => TemplateImportResult.notFound,
        'duplicate' => TemplateImportResult.duplicate,
        'limit_exceeded' => TemplateImportResult.limitExceeded,
        _ => TemplateImportResult.failed,
      };
    }
  }

  /// TP-09: áp dụng lịch mẫu cho các thứ đã chọn trong [weeks] tuần tới.
  /// Lần đầu gọi với replace = false, nếu trùng giờ thì kết quả có hasConflict để
  /// hỏi người dùng, đồng ý thì gọi lại với replace = true.
  Future<ApplyTemplateResult> applyTemplate(
    String templateId, {
    required List<int> days,
    required int weeks,
    required bool replace,
  }) async {
    try {
      final data = await _api.post('/templates/$templateId/apply', {
        'day_indexes': days,
        'weeks': weeks,
        'replace_conflicts': replace,
      });
      return ApplyTemplateResult(
        added: data['added'] ?? 0,
        overwritten: data['overwritten'] ?? 0,
      );
    } on ApiException catch (e) {
      if (e.code == 'conflict' && e.details is Map) {
        final d = e.details as Map;
        return ApplyTemplateResult(
          conflictCount: d['conflict_count'] ?? 0,
          conflictDates: [
            for (final s in (d['conflict_dates'] as List? ?? const []))
              DateTime.parse(s.toString()),
          ],
        );
      }
      return ApplyTemplateResult(error: e.code);
    }
  }
}
