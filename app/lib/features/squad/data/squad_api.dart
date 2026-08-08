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
          .select('id, nama, role, user_id, created_at, updated_at')
          .order('nama', ascending: true);

      return res.map((m) => SquadMember.fromJson(m as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Mvp>> getLeaderboard() async {
    try {
      final List<dynamic> res = await _supabase
          .from('mvps')
          .select('id, rank, pts, created_at, member_id, squad_members(nama)')
          .order('pts', ascending: false);

      return res.map((m) {
        final map = Map<String, dynamic>.from(m as Map);
        if (map['squad_members'] != null) {
          map['nama'] = map['squad_members']['nama'];
        } else {
          map['nama'] = 'Unknown';
        }
        return Mvp.fromJson(map);
      }).toList();
    } catch (e) {
      return [];
    }
  }
}

final squadApiProvider = Provider<SquadApi>((ref) {
  return SquadApi(ref.watch(supabaseProvider));
});

