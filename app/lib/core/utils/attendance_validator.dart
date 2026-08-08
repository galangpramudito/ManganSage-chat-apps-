import 'dart:typed_data';

class AttendanceValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? detectedType;

  AttendanceValidationResult({
    required this.isValid,
    this.errorMessage,
    this.detectedType,
  });
}

class AttendanceValidator {
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> allowedMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
  ];

  /// 1. Validasi Ekstensi & Ukuran File
  static AttendanceValidationResult validateFileBasic({
    required int fileSizeBytes,
    required String fileName,
  }) {
    // Cek Ukuran
    if (fileSizeBytes > maxFileSizeBytes) {
      return AttendanceValidationResult(
        isValid: false,
        errorMessage: 'Ukuran file terlalu besar. Maksimal 5MB',
      );
    }

    // Cek Ekstensi
    final ext = fileName.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(ext)) {
      return AttendanceValidationResult(
        isValid: false,
        errorMessage: 'Format file tidak valid. Gunakan JPG, PNG, atau WEBP.',
      );
    }

    return AttendanceValidationResult(isValid: true);
  }

  /// 2. Validasi Magic Bytes (Deteksi isi biner file asli di HP)
  static AttendanceValidationResult validateMagicBytes(Uint8List bytes) {
    if (bytes.length < 12) {
      return AttendanceValidationResult(
        isValid: false,
        errorMessage: 'File rusak atau tidak terbaca.',
      );
    }

    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return AttendanceValidationResult(isValid: true, detectedType: 'image/jpeg');
    }

    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return AttendanceValidationResult(isValid: true, detectedType: 'image/png');
    }

    // WebP: RIFF (bytes 0-3) dan WEBP (bytes 8-11)
    if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46) {
      final webpTag = String.fromCharCodes(bytes.sublist(8, 12));
      if (webpTag == 'WEBP') {
        return AttendanceValidationResult(isValid: true, detectedType: 'image/webp');
      }
    }

    return AttendanceValidationResult(
      isValid: false,
      errorMessage: 'Konten file tidak valid. File harus berupa gambar JPG, PNG, atau WEBP asli.',
    );
  }

  /// 3. Validasi Waktu Jadwal (WIB UTC+7)
  static Map<String, dynamic> checkScheduleStatus({
    required DateTime startTimeUtc,
    required DateTime endTimeUtc,
  }) {
    final nowUtc = DateTime.now().toUtc();

    // Sebelum jam mulai -> Belum dibuka
    if (nowUtc.isBefore(startTimeUtc)) {
      // Konversi ke waktu lokal device (WIB jika device di Jakarta)
      final startLocal = startTimeUtc.toLocal();
      final timeStr = "${startLocal.hour.toString().padLeft(2, '0')}:${startLocal.minute.toString().padLeft(2, '0')}";
      return {
        'canSubmit': false,
        'status': 'EARLY',
        'error': 'Absen belum dibuka! Silakan kembali pada pukul $timeStr WIB',
      };
    }

    // Lewat jam selesai -> Terlambat
    if (nowUtc.isAfter(endTimeUtc)) {
      return {
        'canSubmit': true,
        'status': 'LATE',
        'izinStatus': 'IZIN_LATE',
      };
    }

    // Tepat waktu
    return {
      'canSubmit': true,
      'status': 'PRESENT',
      'izinStatus': 'IZIN',
    };
  }

  /// 4. Validasi Teks Izin (Minimal 10 Karakter)
  static String? validateAlasanIzin(String? value) {
    if (value == null || value.trim().length < 10) {
      return 'Alasan terlalu singkat. Jelaskan dengan detail (min. 10 karakter)!';
    }
    return null;
  }

  /// 5. Generator Nama File Unik (Sesuai Standar Web)
  static String generateUniqueFileName({
    required String memberName,
    bool isIzin = false,
  }) {
    final cleanName = memberName.replaceAll(RegExp(r'\s+'), '-');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final prefix = isIzin ? '$cleanName-izin-' : '$cleanName-';
    return '$prefix$timestamp.webp';
  }
}
