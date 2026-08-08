import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/supabase_models.dart';
import '../data/squad_api.dart';

final squadMembersProvider = FutureProvider<List<SquadMember>>((ref) async {
  final api = ref.watch(squadApiProvider);
  return api.getMembers();
});

final leaderboardProvider = FutureProvider<List<Mvp>>((ref) async {
  final api = ref.watch(squadApiProvider);
  return api.getLeaderboard();
});

