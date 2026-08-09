import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../../shared/models/supabase_models.dart';

class AnnouncementsApi {
  AnnouncementsApi(this._supabase);

  final SupabaseClient _supabase;

  Stream<Announcement?> getActiveAnnouncementStream() {
    return _supabase
        .from('announcements')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .map((event) {
          if (event.isEmpty) return null;
          // Mengurutkan secara descending agar yang terbaru selalu di atas
          final sorted = List.of(event)..sort((a, b) {
            final dateA = a['created_at'] ?? '';
            final dateB = b['created_at'] ?? '';
            return dateB.compareTo(dateA);
          });
          return Announcement.fromJson(sorted.first);
        });
  }
}

final announcementsApiProvider = Provider<AnnouncementsApi>((ref) {
  return AnnouncementsApi(ref.watch(supabaseProvider));
});
