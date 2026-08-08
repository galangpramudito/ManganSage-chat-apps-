import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_notifier.dart';
import '../data/attendance_api.dart';

final myAttendanceHistoryProvider = FutureProvider<List<AttendanceRecord>>((ref) async {
  final auth = ref.watch(authNotifierProvider).value;
  if (auth == null) return [];
  final api = ref.watch(attendanceApiProvider);
  return api.getMyHistory(auth.id);
});
