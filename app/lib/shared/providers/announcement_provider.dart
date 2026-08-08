import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_service.dart';

/// Provider for active broadcast announcement ticker
final activeAnnouncementProvider = StreamProvider<String?>((ref) async* {
  final supabase = ref.watch(supabaseProvider);

  // Initial fetch
  try {
    final res = await supabase
        .from('announcements')
        .select('message')
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (res != null && res['message'] != null) {
      yield res['message'].toString();
    } else {
      yield null;
    }
  } catch (_) {
    yield null;
  }

  // Realtime stream of announcements table
  final stream = supabase
      .from('announcements')
      .stream(primaryKey: ['id'])
      .eq('is_active', true);

  await for (final data in stream) {
    if (data.isNotEmpty) {
      yield data.first['message']?.toString();
    } else {
      yield null;
    }
  }
});
