/// Chia cột cho các khối bị trùng giờ, để hiển thị cạnh nhau thay vì đè lên nhau.
///
/// Thuật toán: sắp theo giờ bắt đầu, gom các khối chồng lấn thành "cụm",
/// trong mỗi cụm đặt từng khối vào cột trống đầu tiên. Mọi khối trong cùng
/// một cụm có chung số cột để độ rộng đồng đều.
class OverlapSlot {
  final int column;
  final int columns;
  const OverlapSlot(this.column, this.columns);
}

class OverlapLayout {
  OverlapLayout._();

  /// [ranges]: danh sách (bắt đầu, kết thúc) tính theo phút trong ngày.
  /// Trả về vị trí cột theo đúng thứ tự đầu vào.
  static List<OverlapSlot> compute(List<(double start, double end)> ranges) {
    final order = List<int>.generate(ranges.length, (i) => i)
      ..sort((a, b) {
        final c = ranges[a].$1.compareTo(ranges[b].$1);
        return c != 0 ? c : ranges[b].$2.compareTo(ranges[a].$2);
      });

    final column = List<int>.filled(ranges.length, 0);
    final columns = List<int>.filled(ranges.length, 1);

    var cluster = <int>[];
    var columnEnds = <double>[];
    double clusterEnd = double.negativeInfinity;

    void closeCluster() {
      for (final i in cluster) {
        columns[i] = columnEnds.length;
      }
      cluster = [];
      columnEnds = [];
    }

    for (final i in order) {
      final (start, end) = ranges[i];
      if (start >= clusterEnd && cluster.isNotEmpty) closeCluster();

      var placed = false;
      for (int c = 0; c < columnEnds.length; c++) {
        if (columnEnds[c] <= start) {
          column[i] = c;
          columnEnds[c] = end;
          placed = true;
          break;
        }
      }
      if (!placed) {
        column[i] = columnEnds.length;
        columnEnds.add(end);
      }
      cluster.add(i);
      if (cluster.length == 1 || end > clusterEnd) clusterEnd = end;
    }
    if (cluster.isNotEmpty) closeCluster();

    return [
      for (int i = 0; i < ranges.length; i++)
        OverlapSlot(column[i], columns[i]),
    ];
  }
}
