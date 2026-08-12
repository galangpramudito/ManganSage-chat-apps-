import 'package:flutter/foundation.dart';

import 'env.dart';

/// Supabase configuration dan validation
/// Memastikan environment variables sudah di-set sebelum app start
class SupabaseConfig {
  SupabaseConfig._();

  /// Supabase URL dari environment
  static String get url {
    try {
      final envUrl = Env.supabaseUrl;
      if (envUrl.isEmpty || envUrl == 'your_supabase_url') {
        throw _ConfigurationException(
          'SUPABASE_URL not configured properly in .env file',
        );
      }
      return envUrl;
    } catch (e) {
      throw _ConfigurationException(
        'SUPABASE_URL not found. Create .env file with SUPABASE_URL=your_url',
      );
    }
  }

  /// Supabase Anon Key dari environment
  static String get anonKey {
    try {
      final envKey = Env.supabaseAnonKey;
      if (envKey.isEmpty || envKey == 'your_supabase_anon_key') {
        throw _ConfigurationException(
          'SUPABASE_ANON_KEY not configured properly in .env file',
        );
      }
      return envKey;
    } catch (e) {
      throw _ConfigurationException(
        'SUPABASE_ANON_KEY not found. Create .env file with SUPABASE_ANON_KEY=your_key',
      );
    }
  }

  /// Validate configuration - dipanggil di main() sebelum runApp()
  static void validate() {
    try {
      debugPrint('🔍 Validating Supabase configuration...');
      
      // Check URL
      final testUrl = url;
      if (!testUrl.startsWith('https://') || !testUrl.contains('supabase.co')) {
        throw _ConfigurationException(
          'Invalid SUPABASE_URL format. Expected: https://[PROJECT_REF].supabase.co',
        );
      }
      
      // Check Anon / Publishable Key
      final testKey = anonKey;
      if (testKey.length < 20) {
        throw _ConfigurationException(
          'SUPABASE_ANON_KEY seems invalid (too short). Check your .env file.',
        );
      }
      
      debugPrint('✅ Supabase configuration valid');
      debugPrint('   URL: ${testUrl.substring(0, 30)}...');
      debugPrint('   Key: ${testKey.substring(0, 20)}...');
    } catch (e) {
      if (e is _ConfigurationException) {
        debugPrint('❌ Configuration Error: ${e.message}');
        debugPrint('');
        debugPrint('📝 Setup Instructions:');
        debugPrint('   1. Copy .env.example to .env');
        debugPrint('   2. Add your Supabase credentials:');
        debugPrint('      SUPABASE_URL=https://[PROJECT_REF].supabase.co');
        debugPrint('      SUPABASE_ANON_KEY=your_anon_key_here');
        debugPrint('   3. Run: flutter pub run build_runner build');
        debugPrint('   4. Restart the app');
        debugPrint('');
        throw Exception('Configuration validation failed: ${e.message}');
      }
      rethrow;
    }
  }
}

class _ConfigurationException implements Exception {
  _ConfigurationException(this.message);
  final String message;

  @override
  String toString() => 'ConfigurationException: $message';
}
