import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/supabase_models.dart';
import '../data/announcements_api.dart';

final activeAnnouncementProvider = StreamProvider<Announcement?>((ref) {
  final api = ref.watch(announcementsApiProvider);
  return api.getActiveAnnouncementStream();
});
