import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../../shared/models/supabase_models.dart';

class SquadApi {
  SquadApi(this._supabase);

  final SupabaseClient _supabase;

  Future<List<SquadMember>> getMembers() async {
    try {
      final List<dynamic> res = await _supabase
          .from('squad_members')
          .select('id, nama, role, email, user_id, created_at')
          .neq('role', 'admin')
          .order('nama', ascending: true);

      return res
          .map((m) => SquadMember.fromJson(m as Map<String, dynamic>))
          .where((m) => !m.role.toLowerCase().contains('admin'))
          .toList();
    } catch (e, stack) {
      // ignore: avoid_print
      print('⚠️ Error getMembers: $e\n$stack');
      return [];
    }
  }

  Future<List<Mvp>> getLeaderboard() async {
    try {
      final List<dynamic> res = await _supabase
          .from('mvps')
          .select('id, rank, pts, squad_members(nama)')
          .order('rank', ascending: true);

      return res.map((m) {
        final map = Map<String, dynamic>.from(m as Map);
        if (map['squad_members'] != null && map['squad_members'] is Map) {
          map['nama'] = map['squad_members']['nama'] ?? 'Unknown';
        } else {
          map['nama'] = 'Unknown';
        }
        return Mvp.fromJson(map);
      }).toList();
    } catch (e, stack) {
      // ignore: avoid_print
      print('⚠️ Error getLeaderboard: $e\n$stack');
      return [];
    }
  }
}

final squadApiProvider = Provider<SquadApi>((ref) {
  return SquadApi(ref.watch(supabaseProvider));
});

