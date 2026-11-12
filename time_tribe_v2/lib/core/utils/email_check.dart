/// Kiểm tra email ngay trên máy, trước khi gửi lên server (server cũng kiểm tra lại,
/// kèm tra DNS xem tên miền có nhận thư không).
class EmailCheck {
  EmailCheck._();

  /// Phần trước @ gồm chữ, số và . _ % + -; tên miền có ít nhất một dấu chấm,
  /// đuôi cuối từ 2 chữ cái trở lên. Chặn "abc@gmail", "abc@gmail.c", "a b@x.com".
  static final _re = RegExp(
    r'^[a-z0-9._%+\-]+@[a-z0-9](?:[a-z0-9\-]*[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9\-]*[a-z0-9])?)*\.[a-z]{2,}$',
  );

  /// Nhà cung cấp email phổ biến, dùng để đoán lỗi gõ nhầm.
  static const _popular = [
    'gmail.com',
    'yahoo.com',
    'yahoo.com.vn',
    'hotmail.com',
    'outlook.com',
    'icloud.com',
    'live.com',
    'protonmail.com',
  ];

  /// Tên miền thật dù gần giống tên miền phổ biến, không coi là gõ nhầm.
  static const _real = {
    'mail.com',
    'gmx.com',
    'ymail.com',
    'me.com',
    'mac.com',
    'msn.com',
    'aol.com',
    'live.vn',
    'outlook.com.vn',
    'hotmail.com.vn',
    'googlemail.com',
    'proton.me',
    'zoho.com',
    'yandex.com',
  };

  /// Email (đã cắt khoảng trắng, viết thường) có đúng dạng không.
  static bool isValid(String raw) {
    final s = raw.trim().toLowerCase();
    if (s.length > 254 || !_re.hasMatch(s)) return false;
    final local = s.substring(0, s.lastIndexOf('@'));
    return local.length <= 64 &&
        !local.startsWith('.') &&
        !local.endsWith('.') &&
        !s.contains('..');
  }

  /// Nếu tên miền có vẻ gõ nhầm (gmial.com, gmail.con, yahooo.com...) thì trả email gợi ý, không thì null.
  static String? suggest(String raw) {
    final s = raw.trim().toLowerCase();
    final at = s.lastIndexOf('@');
    if (at < 0) return null;
    final local = s.substring(0, at);
    final domain = s.substring(at + 1);
    if (_real.contains(domain) || _popular.contains(domain)) return null;
    String? best;
    var bestDist = 3;
    for (final d in _popular) {
      final dist = _distance(domain, d);
      if (dist < bestDist) {
        best = d;
        bestDist = dist;
      }
    }
    return best == null ? null : '$local@$best';
  }

  /// Số lần thêm/xoá/thay ký tự ít nhất để biến a thành b (Levenshtein).
  static int _distance(String a, String b) {
    var prev = List<int>.generate(b.length + 1, (j) => j);
    for (var i = 1; i <= a.length; i++) {
      final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        cur[j] = [
          prev[j] + 1,
          cur[j - 1] + 1,
          prev[j - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
      }
      prev = cur;
    }
    return prev[b.length];
  }
}
