import 'package:supabase/supabase.dart';

void main() async {
  const url = 'https://vcsvbeepbzmcfnwapqog.supabase.co';
  const anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZjc3ZiZWVwYnptY2Zud2FwcW9nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQwMzk2MzksImV4cCI6MjA5OTYxNTYzOX0.JZPX8HXEvgDv-khEuaNJFeXUojCzI3LUJ8uRGO6-FAI';

  final client = SupabaseClient(url, anonKey);

  try {
    final res = await client.from('squad_members').select().limit(1);
    print('squad_members: $res');
  } catch (e) {
    print('Error reading squad_members: $e');
  }

  try {
    final res = await client.from('announcements').select().limit(1);
    print('announcements: $res');
  } catch (e) {
    print('Error reading announcements: $e');
  }
}
