import 'package:intl/intl.dart';

/// Format timestamp ramah-pengguna untuk Inbox / chat:
/// - Hari ini       → "HH.mm" (mis. "14.32")
/// - Kemarin        → "Kemarin"
/// - Dalam 7 hari   → nama hari (Sen / Sel / ...)
/// - Lebih lama     → "dd MMM" (mis. "10 Mei")
/// - Beda tahun     → "dd MMM yyyy"
class TimestampFormat {
  TimestampFormat._();

  static String inbox(DateTime time, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final t = time.toLocal();

    final today = DateTime(ref.year, ref.month, ref.day);
    final that = DateTime(t.year, t.month, t.day);

    final diffDays = today.difference(that).inDays;

    if (diffDays == 0) {
      return DateFormat('HH.mm', 'id_ID').format(t);
    }
    if (diffDays == 1) return 'Kemarin';
    if (diffDays < 7) return _shortDayId(t.weekday);
    if (t.year == ref.year) return DateFormat('dd MMM', 'id_ID').format(t);
    return DateFormat('dd MMM yyyy', 'id_ID').format(t);
  }

  /// Untuk timestamp di bubble chat — selalu jam.
  static String bubble(DateTime time) {
    return DateFormat('HH.mm').format(time.toLocal());
  }

  static String _shortDayId(int weekday) {
    const map = {
      DateTime.monday: 'Sen',
      DateTime.tuesday: 'Sel',
      DateTime.wednesday: 'Rab',
      DateTime.thursday: 'Kam',
      DateTime.friday: 'Jum',
      DateTime.saturday: 'Sab',
      DateTime.sunday: 'Min',
    };
    return map[weekday] ?? '';
  }
}
