import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Utility untuk verifikasi integritas file APK menggunakan SHA-256 checksum.
/// 
/// Security best practice: Selalu verify downloaded APK sebelum install
/// untuk mencegah tampering atau man-in-the-middle attacks.
class ChecksumVerifier {
  ChecksumVerifier._();

  /// Hitung SHA-256 hash dari file.
  /// 
  /// Returns hex string (lowercase) dari hash, contoh:
  /// "a1b2c3d4e5f6..."
  static Future<String> calculateSHA256(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      debugPrint('⚠️ Failed to calculate SHA256: $e');
      rethrow;
    }
  }

  /// Verify bahwa file sesuai dengan expected checksum.
  /// 
  /// Returns `true` jika match, `false` jika tidak.
  /// Throws exception jika file tidak bisa dibaca.
  static Future<bool> verifyFile({
    required File file,
    required String expectedChecksum,
  }) async {
    final actualChecksum = await calculateSHA256(file);
    final match = actualChecksum.toLowerCase() == expectedChecksum.toLowerCase();
    
    if (match) {
      debugPrint('✅ Checksum verified: $actualChecksum');
    } else {
      debugPrint('❌ Checksum mismatch!');
      debugPrint('   Expected: ${expectedChecksum.toLowerCase()}');
      debugPrint('   Actual:   $actualChecksum');
    }
    
    return match;
  }
}
