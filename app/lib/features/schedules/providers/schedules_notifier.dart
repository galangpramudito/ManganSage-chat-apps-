import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/alarm_service.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../shared/models/supabase_models.dart';

/// StreamProvider with Supabase Realtime so whenever Admin opens a new schedule,
/// ALL devices instantly refresh schedules, show pop-up notification & set alarms!
final schedulesListProvider = StreamProvider<List<ScheduleModel>>((ref) {
  final supabase = ref.watch(supabaseProvider);
  final alarmService = ref.watch(alarmServiceProvider);

  debugPrint('⚡ [schedulesListProvider] INITIALIZING STREAM...');

  List<ScheduleModel> previousSchedules = [];

  return supabase
      .from('schedules')
      .stream(primaryKey: ['id'])
      .order('start_time', ascending: false)
      .map((data) {
    debugPrint('⚡ [schedulesListProvider] STREAM EMITTED DATA: ${data.length} rows');
    
    final newSchedules = data.map((map) {
      final startRaw = DateTime.tryParse(map['start_time']?.toString() ?? '');
      final endRaw = DateTime.tryParse(map['end_time']?.toString() ?? '');
      final createdRaw = DateTime.tryParse(map['created_at']?.toString() ?? '');

      return ScheduleModel(
        id: map['id'].toString(),
        title: map['title']?.toString() ?? 'Match Valorant MNG',
        startTime: startRaw ?? DateTime.now(),
        endTime: endRaw ?? DateTime.now().add(const Duration(hours: 2)),
        createdAt: createdRaw,
      );
    }).toList();

    // Trigger instant notification when admin opens a new schedule
    final currentIds = previousSchedules.map((s) => s.id).toSet();
    for (final s in newSchedules) {
      if (!currentIds.contains(s.id) && previousSchedules.isNotEmpty) {
        debugPrint('⚡ [schedulesListProvider] NEW SCHEDULE DETECTED: ${s.title}');
        alarmService.showInstantNotification(
          title: 'Jadwal Pertandingan: ${s.title}',
          body: 'Sesi pertandingan baru telah dibuka. Harap konfirmasi presensi Anda.',
        );
      }
    }
    previousSchedules = newSchedules;

    // Process schedules for background countdown alarms (15 min reminders)
    _processSchedules(newSchedules, alarmService);
    
    return newSchedules;
  }).handleError((error) {
    debugPrint('🔴 [schedulesListProvider] STREAM ERROR: $error');
    throw error;
  });
});

void _processSchedules(List<ScheduleModel> schedules, AlarmService alarmService) {
  final now = DateTime.now().toUtc();
  for (final s in schedules) {
    if (s.startTime.toUtc().isAfter(now)) alarmService.scheduleFor(s);
    if (s.endTime.toUtc().isAfter(now)) alarmService.scheduleClosingReminder(s);
  }
}
