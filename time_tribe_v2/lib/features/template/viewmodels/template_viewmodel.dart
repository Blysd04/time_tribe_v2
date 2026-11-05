import 'package:flutter/material.dart';
import '../models/template_model.dart';

/// Kết quả nhập lịch mẫu từ link.
enum TemplateImportResult {
  success,
  invalidLink,
  notFound,
  duplicate,
  limitExceeded,
}

class TemplateLimits {
  static const int maxTemplates = 10;
}

class TemplateViewModel extends ChangeNotifier {
  final List<TemplateModel> _templates = [
    TemplateModel(
      id: 'tpl-1',
      userId: 'user-123',
      templateName: 'Tuần học NIC & Đi làm',
      blocks: [
        // Các block Thứ 2 (dayIndex: 1)
        TemplateBlockModel(
          id: 'tb-1',
          templateId: 'tpl-1',
          dayIndex: 1,
          title: 'Học UI/UX',
          startTime: const TimeOfDay(hour: 8, minute: 0),
          endTime: const TimeOfDay(hour: 11, minute: 30),
          colorCode: '#3A86FF',
          description: 'Phòng Lab 3',
        ),
        // Các block Thứ 4 (dayIndex: 3)
        TemplateBlockModel(
          id: 'tb-2',
          templateId: 'tpl-1',
          dayIndex: 3,
          title: 'Làm part-time',
          startTime: const TimeOfDay(hour: 13, minute: 0),
          endTime: const TimeOfDay(hour: 17, minute: 0),
          colorCode: '#FFB703',
        ),
      ],
    ),
    TemplateModel(
      id: 'tpl-2',
      userId: 'user-123',
      templateName: 'Quy trình tập Gym 4 ngày',
      blocks: [
        TemplateBlockModel(
          id: 'tb-3',
          templateId: 'tpl-2',
          dayIndex: 2,
          title: 'Push Day',
          startTime: const TimeOfDay(hour: 17, minute: 30),
          endTime: const TimeOfDay(hour: 19, minute: 0),
          colorCode: '#FF007F',
          description: 'Ngực, Vai, Tay sau',
        ),
        TemplateBlockModel(
          id: 'tb-4',
          templateId: 'tpl-2',
          dayIndex: 4,
          title: 'Pull Day',
          startTime: const TimeOfDay(hour: 17, minute: 30),
          endTime: const TimeOfDay(hour: 19, minute: 0),
          colorCode: '#9B5DE5',
          description: 'Lưng, Tay trước',
        ),
      ],
    ),
  ];

  List<TemplateModel> get templates => _templates;

  TemplateModel? _draftTemplate;
  TemplateModel? get draftTemplate => _draftTemplate;

  void saveDraft(TemplateModel draft) {
    _draftTemplate = draft;
    notifyListeners();
  }

  void clearDraft() {
    _draftTemplate = null;
    notifyListeners();
  }

  void deleteTemplate(String id) {
    _templates.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void saveTemplate(TemplateModel savedTemplate) {
    final index = _templates.indexWhere((t) => t.id == savedTemplate.id);
    if (index != -1) {
      _templates[index] = savedTemplate; // Ghi đè nếu sửa
    } else {
      _templates.add(savedTemplate); // Lưu mới
    }
    clearDraft();
    notifyListeners();
  }

  // Giả lập kho Lịch mẫu được chia sẻ công khai trên server.
  // Key = share_token (phần cuối của link https://timetribe.app/t/<token>).
  // TODO(backend): thay bằng GET /templates/shared/{token}
  final Map<String, TemplateModel> _mockSharedTemplates = {
    'study-week': TemplateModel(
      id: 'shared-1',
      userId: 'other-user',
      templateName: 'Tuần ôn thi cuối kỳ',
      shareToken: 'study-week',
      blocks: [
        TemplateBlockModel(
          id: 'sb-1',
          templateId: 'shared-1',
          dayIndex: 1,
          title: 'Ôn Toán',
          startTime: const TimeOfDay(hour: 19, minute: 0),
          endTime: const TimeOfDay(hour: 21, minute: 0),
          colorCode: '#3A86FF',
        ),
        TemplateBlockModel(
          id: 'sb-2',
          templateId: 'shared-1',
          dayIndex: 3,
          title: 'Ôn Tiếng Anh',
          startTime: const TimeOfDay(hour: 19, minute: 0),
          endTime: const TimeOfDay(hour: 21, minute: 0),
          colorCode: '#00F5D4',
        ),
      ],
    ),
  };

  Future<TemplateModel?> _fetchSharedTemplate(String token) async {
    await Future.delayed(const Duration(milliseconds: 400)); // giả lập gọi API
    return _mockSharedTemplates[token];
  }

  /// Lấy share token từ link người dùng dán vào.
  /// Chấp nhận: "https://timetribe.app/t/abc", "timetribe.app/t/abc/", "abc".
  static String? extractShareToken(String link) {
    final segments =
        (Uri.tryParse(link.trim())?.pathSegments ?? const <String>[])
            .where((s) => s.isNotEmpty)
            .toList();
    if (segments.isEmpty) return null;
    return segments.last;
  }

  Future<TemplateImportResult> importTemplateByLink(String link) async {
    // Chỉ cho phép lưu tối đa 10 template
    if (_templates.length >= TemplateLimits.maxTemplates) {
      return TemplateImportResult.limitExceeded;
    }

    final token = extractShareToken(link);
    if (token == null) return TemplateImportResult.invalidLink;

    bool alreadyInStore(String key) => _templates.any(
      (t) => t.id == key || t.originalTemplateId == key || t.shareToken == key,
    );

    // Link trỏ tới mẫu đang có sẵn trong kho của mình
    if (alreadyInStore(token)) return TemplateImportResult.duplicate;

    final shared = await _fetchSharedTemplate(token);
    if (shared == null) return TemplateImportResult.notFound;

    if (alreadyInStore(shared.id)) return TemplateImportResult.duplicate;

    // Chép mẫu về kho (id mới, ghi nhớ id gốc để chặn nhập trùng lần sau)
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newTemplate = TemplateModel(
      id: newId,
      userId: 'current-user-id',
      originalTemplateId: shared.id,
      templateName: shared.templateName,
      blocks: shared.blocks
          .map(
            (b) => TemplateBlockModel(
              id: '$newId-${b.id}',
              templateId: newId,
              dayIndex: b.dayIndex,
              title: b.title,
              description: b.description,
              startTime: b.startTime,
              endTime: b.endTime,
              colorCode: b.colorCode,
              remind: b.remind,
            ),
          )
          .toList(),
    );

    _templates.add(newTemplate);
    notifyListeners();

    return TemplateImportResult.success;
  }
}
