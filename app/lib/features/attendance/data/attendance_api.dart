import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../../core/utils/attendance_validator.dart';

class AttendanceRecord {
  AttendanceRecord({
    required this.id,
    required this.memberId,
    required this.scheduleId,
    required this.status,
    this.scheduleTitle,
    this.imageUrl,
    this.alasan,
    required this.createdAt,
  });

  final String id;
  final String memberId;
  final String scheduleId;
  final String status;
  final String? scheduleTitle;
  final String? imageUrl;
  final String? alasan;
  final DateTime createdAt;

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    // Extract schedule title from joined data
    String? title;
    final scheduleData = map['schedule'];
    if (scheduleData is Map<String, dynamic>) {
      title = scheduleData['title']?.toString();
    }

    final createdRaw = DateTime.tryParse(map['created_at']?.toString() ?? '');

    return AttendanceRecord(
      id: map['id'].toString(),
      memberId: map['member_id'].toString(),
      scheduleId: map['schedule_id'].toString(),
      status: map['status']?.toString() ?? 'PRESENT',
      scheduleTitle: title,
      imageUrl: map['image_url']?.toString(),
      alasan: map['alasan']?.toString(),
      createdAt: createdRaw ?? DateTime.now(),
    );
  }
}

class AttendanceApi {
  AttendanceApi(this._supabase);

  final SupabaseClient _supabase;

  /// Submit absensi/izin lengkap dengan validasi jadwal, duplikasi, dan upload bukti
  Future<void> submitAttendance({
    required String memberId,
    required String memberName,
    required String scheduleId,
    required DateTime scheduleStartTime,
    required DateTime scheduleEndTime,
    required bool isIzin,
    String? alasan,
    Uint8List? imageBytes,
    String? fileName,
  }) async {
    // 1. Validasi Jadwal
    final scheduleCheck = AttendanceValidator.checkScheduleStatus(
      startTimeUtc: scheduleStartTime.toUtc(),
      endTimeUtc: scheduleEndTime.toUtc(),
    );

    if (scheduleCheck['canSubmit'] == false) {
      throw Exception(scheduleCheck['error']);
    }

    // Tentukan status (PRESENT/LATE/IZIN/IZIN_LATE)
    final calculatedStatus = isIzin
        ? (scheduleCheck['izinStatus'] as String)
        : (scheduleCheck['status'] as String);

    // 2. Validasi Alasan jika Izin (min. 10 karakter)
    if (isIzin) {
      final alasanErr = AttendanceValidator.validateAlasanIzin(alasan);
      if (alasanErr != null) {
        throw Exception(alasanErr);
      }
    }

    // 3. Validasi & Upload Gambar
    String? uploadedImageUrl;
    if (imageBytes != null && imageBytes.isNotEmpty) {
      final basicCheck = AttendanceValidator.validateFileBasic(
        fileSizeBytes: imageBytes.lengthInBytes,
        fileName: fileName ?? 'upload.webp',
      );
      if (!basicCheck.isValid) {
        throw Exception(basicCheck.errorMessage);
      }

      final magicCheck = AttendanceValidator.validateMagicBytes(imageBytes);
      if (!magicCheck.isValid) {
        throw Exception(magicCheck.errorMessage);
      }

      // Upload ke Storage Bucket "image"
      final uniqueFileName = AttendanceValidator.generateUniqueFileName(
        memberName: memberName,
        isIzin: isIzin,
      );

      await _supabase.storage.from(SupabaseConfig.storageBucket).uploadBinary(
            uniqueFileName,
            imageBytes,
            fileOptions: const FileOptions(
              contentType: 'image/webp',
              cacheControl: '3600',
              upsert: false,
            ),
          );

      uploadedImageUrl = _supabase.storage
          .from(SupabaseConfig.storageBucket)
          .getPublicUrl(uniqueFileName);
    } else if (!isIzin) {
      throw Exception('Wajib melampirkan foto bukti screenshot lobby Valorant!');
    }

    // 4. Cek Duplikasi 1 Member = 1 Absen per Schedule
    final existing = await _supabase
        .from('absensi')
        .select('id')
        .eq('member_id', memberId)
        .eq('schedule_id', scheduleId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('Kamu sudah mengisi absensi untuk jadwal ini!');
    }

    // 5. Simpan ke Database (Handling terpisah Hadir vs Izin)
    final Map<String, dynamic> insertPayload = {
      'member_id': memberId,
      'schedule_id': scheduleId,
      'status': calculatedStatus,
      'alasan': isIzin ? alasan?.trim() : null,
      'image_url': uploadedImageUrl ?? (isIzin ? 'N/A' : ''),
    };

    await _supabase.from('absensi').insert(insertPayload);
  }

  /// Ambil riwayat absensi pribadi + JOIN schedule untuk ambil judul
  Future<List<AttendanceRecord>> getMyHistory(String memberId) async {
    try {
      final List<dynamic> res = await _supabase
          .from('absensi')
          .select('*, schedule:schedules(title)')
          .eq('member_id', memberId)
          .order('created_at', ascending: false);

      return res.map((m) => AttendanceRecord.fromMap(m as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }
}

final attendanceApiProvider = Provider<AttendanceApi>((ref) {
  return AttendanceApi(ref.watch(supabaseProvider));
});


