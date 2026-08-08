import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../../shared/models/supabase_models.dart';

class SchedulesApi {
  SchedulesApi(this._supabase);

  final SupabaseClient _supabase;

  Stream<List<ScheduleModel>> listStream() {
    return _supabase
        .from('schedules')
        .stream(primaryKey: ['id'])
        .map((event) {
          final sorted = List.of(event)..sort((a, b) {
            final dateA = a['start_time'] ?? '';
            final dateB = b['start_time'] ?? '';
            return dateB.compareTo(dateA); // Descending
          });
          return sorted.map((s) => ScheduleModel.fromJson(s)).toList();
        });
  }
}

final schedulesApiProvider = Provider<SchedulesApi>((ref) {
  return SchedulesApi(ref.watch(supabaseProvider));
});
