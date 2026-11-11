/// Một thành phố có thể chọn trong Profile, gắn với 1 múi giờ IANA.
/// `timezoneId` chính là giá trị lưu vào cột `users.timezone` trong database.
class TimezoneCity {
  final String city;
  final String timezoneId;

  const TimezoneCity(this.city, this.timezoneId);
}

/// Danh sách Quốc gia (mã ISO) -> Thành phố. Tên quốc gia được dịch ở giao
/// diện. Độ lệch GMT tính từ cơ sở dữ liệu IANA lúc chạy (đúng cả giờ mùa hè).
const Map<String, List<TimezoneCity>> kTimezoneLocations = {
  'vn': [
    TimezoneCity('Hồ Chí Minh', 'Asia/Ho_Chi_Minh'),
    TimezoneCity('Hà Nội', 'Asia/Ho_Chi_Minh'),
  ],
  'ca': [
    TimezoneCity('Courtenay', 'America/Vancouver'),
    TimezoneCity('Vancouver', 'America/Vancouver'),
    TimezoneCity('Toronto', 'America/Toronto'),
  ],
  'jp': [
    TimezoneCity('Tokyo', 'Asia/Tokyo'),
    TimezoneCity('Osaka', 'Asia/Tokyo'),
  ],
  'kr': [TimezoneCity('Seoul', 'Asia/Seoul')],
  'gb': [TimezoneCity('London', 'Europe/London')],
  'fr': [TimezoneCity('Paris', 'Europe/Paris')],
  'us': [
    TimezoneCity('New York', 'America/New_York'),
    TimezoneCity('Los Angeles', 'America/Los_Angeles'),
  ],
  'au': [TimezoneCity('Sydney', 'Australia/Sydney')],
};
