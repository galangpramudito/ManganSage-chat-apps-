import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://vcsvbeepbzmcfnwapqog.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZjc3ZiZWVwYnptY2Zud2FwcW9nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQwMzk2MzksImV4cCI6MjA5OTYxNTYzOX0.JZPX8HXEvgDv-khEuaNJFeXUojCzI3LUJ8uRGO6-FAI';
  static const String storageBucket = 'image';
}

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

