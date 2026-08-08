import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../../shared/models/supabase_models.dart';
import 'auth_notifier.dart';

part 'profile_notifier.g.dart';

@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  @override
  FutureOr<void> build() async {
    // No initial state needed
  }

  Future<void> updateProfile({
    String? name,
  }) async {
    final supabase = ref.read(supabaseProvider);
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final currentUser = ref.read(authNotifierProvider).value;

    if (currentUser == null) return;

    final body = <String, dynamic>{};
    if (name != null) body['nama'] = name;
    
    if (body.isEmpty) return;
    body['updated_at'] = DateTime.now().toIso8601String();

    final res = await supabase
        .from('squad_members')
        .update(body)
        .eq('id', currentUser.id)
        .select()
        .single();

    final updatedUser = SquadMember.fromJson(res);
    authNotifier.state = AsyncData(updatedUser);
  }
}
