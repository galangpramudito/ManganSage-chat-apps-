import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Note: SupabaseConfig moved to core/env/env_validator.dart
// Import from there if needed for validation

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

