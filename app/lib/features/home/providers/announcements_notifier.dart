import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/alarm_service.dart';
import '../../../shared/models/supabase_models.dart';
import '../data/announcements_api.dart';

final activeAnnouncementProvider = StreamProvider<Announcement?>((ref) {
  final api = ref.watch(announcementsApiProvider);
  final alarmService = ref.watch(alarmServiceProvider);

  String? lastAnnouncementId;

  return api.getActiveAnnouncementStream().map((announcement) {
    if (announcement != null && announcement.isActive) {
      // Trigger notification if a new broadcast announcement is pushed while app is active
      if (lastAnnouncementId != null && lastAnnouncementId != announcement.id) {
        alarmService.showInstantNotification(
          title: '📢 PENGUMUMAN MANGAN GROUP',
          body: announcement.message,
        );
      }
      lastAnnouncementId = announcement.id;
    }
    return announcement;
  });
});
