import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://vcsvbeepbzmcfnwapqog.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZjc3ZiZWVwYnptY2Zud2FwcW9nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQwMzk2MzksImV4cCI6MjA5OTYxNTYzOX0.JZPX8HXEvgDv-khEuaNJFeXUojCzI3LUJ8uRGO6-FAI';
  static const String serviceRoleKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZjc3ZiZWVwYnptY2Zud2FwcW9nIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NDAzOTYzOSwiZXhwIjoyMDk5NjE1NjM5fQ.cr8ANwR1w8E7xH3ht86mdtFeWltoCHhDrZU0DtPEiHY';

  static const String storageBucket = 'image';
}

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final adminSupabaseProvider = Provider<SupabaseClient>((ref) {
  // Gunakan serviceRoleKey untuk membypass RLS saat menggunakan Stream Realtime
  // Hal ini penting jika tabel dibatasi oleh RLS untuk user 'anon'.
  final client = SupabaseClient(
    SupabaseConfig.url,
    SupabaseConfig.serviceRoleKey,
  );
  
  ref.onDispose(() {
    client.dispose();
  });
  
  return client;
});

