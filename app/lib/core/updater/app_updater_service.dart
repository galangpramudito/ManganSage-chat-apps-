import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Model untuk data release dari tabel `app_releases` di Supabase.
class AppRelease {
  final String id;
  final String version;
  final int buildNumber;
  final String downloadUrl;
  final String? releaseNotes;
  final bool forceUpdate;
  final DateTime createdAt;
  final String? sha256Checksum; // Security: APK integrity verification

  const AppRelease({
    required this.id,
    required this.version,
    required this.buildNumber,
    required this.downloadUrl,
    this.releaseNotes,
    this.forceUpdate = false,
    required this.createdAt,
    this.sha256Checksum,
  });

  factory AppRelease.fromJson(Map<String, dynamic> json) {
    return AppRelease(
      id: json['id'] as String,
      version: json['version'] as String,
      buildNumber: json['build_number'] as int,
      downloadUrl: json['download_url'] as String,
      releaseNotes: json['release_notes'] as String?,
      forceUpdate: json['force_update'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      sha256Checksum: json['sha256_checksum'] as String?,
    );
  }
}

/// Service utama untuk mengecek dan mendownload update APK.
///
/// Alur:
/// 1. [checkForUpdate] → query Supabase `app_releases`, bandingkan build_number
/// 2. [downloadAndInstall] → download APK via Dio dengan progress, lalu trigger installer
class AppUpdaterService {
  AppUpdaterService._();

  static final _supabase = Supabase.instance.client;
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 10), // Allow 10 min for large APK
    sendTimeout: const Duration(seconds: 30),
  ));

  /// Ambil info versi aplikasi saat ini (misal: "v1.2.0 (Build 2)")
  static Future<String> getCurrentVersionString() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return 'v${info.version} (Build ${info.buildNumber})';
    } catch (_) {
      return 'v1.2.0 (Build 2)';
    }
  }

  /// Cek apakah ada versi baru di Supabase.
  /// Return [AppRelease] jika ada update, `null` jika sudah terbaru.
  /// Throw exception jika ada error (network, parse, dll).
  static Future<AppRelease?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      debugPrint('🔍 Checking update... current build: $currentBuild');

      // Query versi terbaru dari Supabase
      final response = await _supabase
          .from('app_releases')
          .select()
          .order('build_number', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        debugPrint('ℹ️ No releases found in app_releases table');
        return null;
      }

      final latestRelease = AppRelease.fromJson(response);

      if (latestRelease.buildNumber > currentBuild) {
        debugPrint(
          '🚀 Update available! '
          '${packageInfo.version}+$currentBuild → '
          '${latestRelease.version}+${latestRelease.buildNumber}',
        );
        return latestRelease;
      }

      debugPrint('✅ App is up to date (build $currentBuild)');
      return null;
    } catch (e, stackTrace) {
      debugPrint('⚠️ Update check failed: $e');
      debugPrint('Stack trace: $stackTrace');
      // Re-throw untuk di-handle di UI layer
      rethrow;
    }
  }

  /// Download APK dari [release.downloadUrl] lalu trigger Android installer.
  ///
  /// [onProgress] dipanggil dengan value 0.0 – 1.0 untuk progress bar.
  /// 
  /// Security: Jika [release.sha256Checksum] tersedia, akan verifikasi
  /// integritas file sebelum install. Jika checksum tidak match, throw exception.
  static Future<void> downloadAndInstall(
    AppRelease release, {
    ValueChanged<double>? onProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/mangan-group-${release.version}.apk';
    final file = File(filePath);

    // Hapus file lama jika ada
    if (await file.exists()) {
      await file.delete();
    }

    debugPrint('⬇️ Downloading APK to: $filePath');

    // Download dengan progress tracking
    await _dio.download(
      release.downloadUrl,
      filePath,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          final progress = received / total;
          onProgress?.call(progress);
        }
      },
    );

    debugPrint('✅ Download complete');

    // Verify checksum jika tersedia (SECURITY)
    if (release.sha256Checksum != null && release.sha256Checksum!.isNotEmpty) {
      debugPrint('🔒 Verifying APK integrity...');
      
      // Import checksum_verifier
      final crypto = await compute<File, String>(
        (file) async {
          // Lazy import untuk avoid dependency di web
          final bytes = await file.readAsBytes();
          final digest = sha256.convert(bytes);
          return digest.toString();
        },
        file,
      );

      final isValid = crypto.toLowerCase() == release.sha256Checksum!.toLowerCase();
      
      if (!isValid) {
        debugPrint('❌ Checksum verification FAILED!');
        debugPrint('   Expected: ${release.sha256Checksum}');
        debugPrint('   Got:      $crypto');
        
        // Delete corrupted/tampered file
        await file.delete();
        
        throw Exception(
          'Verifikasi integritas APK gagal. File mungkin rusak atau tidak aman. '
          'Silakan coba lagi atau hubungi administrator.'
        );
      }
      
      debugPrint('✅ Checksum verified successfully');
    } else {
      debugPrint('⚠️ No checksum provided - skipping verification (not recommended)');
    }

    debugPrint('📦 Opening installer...');

    // Trigger Android installer
    final result = await OpenFilex.open(filePath);

    if (result.type != ResultType.done) {
      debugPrint('⚠️ Failed to open APK: ${result.message}');
      throw Exception('Gagal membuka file APK: ${result.message}');
    }
  }
}
