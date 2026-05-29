import 'package:intl/intl.dart';

/// Format status presence pengguna untuk UI:
/// - Online   → "Online"
/// - Recently → "Aktif barusan", "Aktif 5 menit lalu", dst
/// - Lama     → "Aktif 10 Mei"
class PresenceFormat {
  PresenceFormat._();

  /// Formal text status untuk subtitle (mis. di header ChatRoom).
  static String describe({
    required bool isOnline,
    DateTime? lastSeen,
    DateTime? now,
  }) {
    if (isOnline) return 'Online';
    if (lastSeen == null) return 'Offline';

    final ref = now ?? DateTime.now();
    final diff = ref.difference(lastSeen.toLocal());

    if (diff.isNegative) return 'Online';
    if (diff.inMinutes < 1) return 'Aktif barusan';
    if (diff.inMinutes < 60) return 'Aktif ${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return 'Aktif ${diff.inHours} jam lalu';
    if (diff.inDays < 7) return 'Aktif ${diff.inDays} hari lalu';

    return 'Aktif ${DateFormat('dd MMM', 'id_ID').format(lastSeen.toLocal())}';
  }

  /// Versi singkat untuk inline (mis. UserTile next to email).
  static String short({
    required bool isOnline,
    DateTime? lastSeen,
    DateTime? now,
  }) {
    if (isOnline) return 'Online';
    if (lastSeen == null) return '';
    final ref = now ?? DateTime.now();
    final diff = ref.difference(lastSeen.toLocal());
    if (diff.isNegative) return 'Online';
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}j';
    if (diff.inDays < 7) return '${diff.inDays}h';
    return DateFormat('dd MMM', 'id_ID').format(lastSeen.toLocal());
  }
}
