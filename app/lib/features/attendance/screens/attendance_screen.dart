import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';


import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/supabase_models.dart';
import '../../auth/providers/auth_notifier.dart';
import '../../schedules/providers/schedules_notifier.dart';
import '../data/attendance_api.dart';
import '../providers/attendance_notifier.dart';

import '../../../shared/widgets/attendance_badge.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  /// Backward-compatible delegate to shared [AttendanceBadge] widget.
  static Widget buildAttendanceBadge(String status) =>
      AttendanceBadge(status: status);

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  String _selectedStatus = 'PRESENT';
  String? _selectedScheduleId;
  final _alasanCtrl = TextEditingController();
  bool _submitting = false;

  // Image picker state
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;

  @override
  void dispose() {
    _alasanCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final xFile = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 720,
        imageQuality: 70,
      );
      if (xFile != null) {
        final bytes = await xFile.readAsBytes();
        setState(() {
          _pickedImage = xFile;
          _pickedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil gambar: $e')),
        );
      }
    }
  }

  Future<void> _submit(List<ScheduleModel> schedules) async {
    final user = ref.read(authNotifierProvider).value;
    if (user == null) return;

    final nowLocal = DateTime.now();
    final availableSchedules = schedules.where((s) {
      final startLocal = s.startTime.toLocal();
      return startLocal.year == nowLocal.year && 
             startLocal.month == nowLocal.month && 
             startLocal.day == nowLocal.day;
    }).toList();

    if (availableSchedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada jadwal pertandingan aktif yang dibuka saat ini.')),
      );
      return;
    }

    final selectedId = _selectedScheduleId ?? availableSchedules.first.id;
    final currentSchedule = availableSchedules.firstWhere(
      (s) => s.id == selectedId,
      orElse: () => availableSchedules.first,
    );

    final isIzin = _selectedStatus == 'IZIN';

    if (isIzin && _alasanCtrl.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alasan terlalu singkat. Jelaskan minimal 10 karakter!')),
      );
      return;
    }

    // Wajib foto jika HADIR
    if (!isIzin && _pickedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wajib melampirkan foto bukti screenshot lobby Valorant!')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final api = ref.read(attendanceApiProvider);
      await api.submitAttendance(
        memberId: user.id,
        memberName: user.nama,
        scheduleId: currentSchedule.id,
        scheduleStartTime: currentSchedule.startTime,
        scheduleEndTime: currentSchedule.endTime,
        isIzin: isIzin,
        alasan: isIzin ? _alasanCtrl.text.trim() : null,
        imageBytes: _pickedImageBytes,
        fileName: _pickedImage?.name,
      );

      ref.invalidate(myAttendanceHistoryProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Presensi berhasil dikirim ke portal MNG!'),
            backgroundColor: AppColors.statusPresent,
          ),
        );
        _alasanCtrl.clear();
        setState(() {
          _pickedImage = null;
          _pickedImageBytes = null;
        });

        // Auto-pop back to Home after short delay
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Show confirmation dialog before submitting (irreversible action)
  Future<void> _confirmAndSubmit(List<ScheduleModel> schedules) async {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusLabel = _selectedStatus == 'PRESENT' ? 'HADIR' : 'IZIN';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        backgroundColor: isDark ? AppColors.mono900 : AppColors.backgroundLight,
        title: Text(
          'KONFIRMASI PRESENSI',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0),
        ),
        content: Text(
          'Kamu akan mengirim presensi sebagai "$statusLabel".\n\nData ini tidak dapat diubah setelah dikirim. Lanjutkan?',
          style: GoogleFonts.inter(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('BATAL', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx, true);
            },
            child: Text('KIRIM', style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _submit(schedules);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final asyncSchedules = ref.watch(schedulesListProvider);
    final asyncHistory = ref.watch(myAttendanceHistoryProvider);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'PRESENSI SQUAD MNG',
            style: AppTypography.headingTitle(isDark).copyWith(fontSize: 16),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              onPressed: () => ref.invalidate(myAttendanceHistoryProvider),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async => ref.invalidate(myAttendanceHistoryProvider),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // ─── Form Card ──────────────────────────────────────────────────
              Builder(
                builder: (context) {
                  final schedules = asyncSchedules.value ?? [];
                  final history = asyncHistory.value ?? [];

                  // Set ID schedule yang sudah pernah diisi oleh user
                  final submittedScheduleIds = history.map((h) => h.scheduleId).toSet();

                  final nowLocal = DateTime.now();
                  // Filter hanya jadwal hari ini DAN belum diisi oleh user
                  final pendingSchedules = schedules.where((s) {
                    final startLocal = s.startTime.toLocal();
                    final isToday = startLocal.year == nowLocal.year && 
                                    startLocal.month == nowLocal.month && 
                                    startLocal.day == nowLocal.day;
                    final isNotSubmitted = !submittedScheduleIds.contains(s.id);
                    return isToday && isNotSubmitted;
                  }).toList();

                  // Jika SEMUA jadwal aktif sudah diisi atau tidak ada jadwal
                  if (pendingSchedules.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.mono900 : AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: history.isNotEmpty
                              ? AppColors.statusPresent
                              : (isDark ? AppColors.mono800 : AppColors.mono200),
                          width: history.isNotEmpty ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            history.isNotEmpty ? Icons.verified_outlined : Icons.calendar_today_outlined,
                            size: 40,
                            color: history.isNotEmpty
                                ? AppColors.statusPresent
                                : (isDark ? AppColors.mono400 : AppColors.mono700),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            history.isNotEmpty ? 'SEMUA PRESENSI COMPLETED' : 'TIDAK ADA JADWAL MATCH DIBUKA',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 1.0,
                              color: history.isNotEmpty ? AppColors.statusPresent : null,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            history.isNotEmpty
                                ? 'Kamu telah menyelesaikan semua presensi jadwal match aktif hari ini.'
                                : 'Admin belum membuka jadwal pertandingan baru saat ini.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? AppColors.mono400 : AppColors.mono700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          // Action buttons to guide user out of empty state
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.white : Colors.black,
                                foregroundColor: isDark ? Colors.black : Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                              ),
                              onPressed: () {
                                context.pop();
                                context.go('/schedules');
                              },
                              icon: const Icon(Icons.history_rounded, size: 18),
                              label: Text(
                                'LIHAT RIWAYAT PRESENSI',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                side: BorderSide(color: isDark ? AppColors.mono700 : AppColors.mono400),
                              ),
                              onPressed: () => context.pop(),
                              icon: const Icon(Icons.home_outlined, size: 18),
                              label: Text(
                                'KEMBALI KE BERANDA',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Masih ada jadwal aktif yang BELUM diisi user -> Tampilkan Form Presensi
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.mono900 : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: isDark ? AppColors.mono800 : AppColors.mono200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedStatus == 'PRESENT' ? 'FORM PRESENSI HADIR' : 'FORM PENGAJUAN IZIN',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Text(_selectedStatus == 'PRESENT' ? 'HADIR // PROOF' : 'IZIN // REASON', style: AppTypography.badgeText(isDark)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Pilih Jadwal (Hanya memuat jadwal yang BELUM diisi)
                        DropdownButtonFormField<String>(
                          value: pendingSchedules.any((s) => s.id == _selectedScheduleId)
                              ? _selectedScheduleId
                              : pendingSchedules.first.id,
                          decoration: const InputDecoration(
                            labelText: 'PILIH JADWAL MATCH',
                            prefixIcon: Icon(Icons.sports_esports_outlined, size: 18),
                          ),
                          items: pendingSchedules.map((s) {
                            final startStr = DateFormat('HH:mm', 'id_ID').format(s.startTime.toLocal());
                            final endStr = DateFormat('HH:mm', 'id_ID').format(s.endTime.toLocal());
                            return DropdownMenuItem(
                              value: s.id,
                              child: Text(
                                '${s.title.toUpperCase()} ($startStr — $endStr WIB)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedScheduleId = val),
                        ),
                        const SizedBox(height: 12),

                      // Status Hadir vs Izin
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: _selectedStatus == 'PRESENT'
                                    ? (isDark ? Colors.white : Colors.black)
                                    : Colors.transparent,
                                foregroundColor: _selectedStatus == 'PRESENT'
                                    ? (isDark ? Colors.black : Colors.white)
                                    : (isDark ? Colors.white : Colors.black),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                side: BorderSide(color: isDark ? AppColors.mono700 : AppColors.mono400),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                setState(() => _selectedStatus = 'PRESENT');
                              },
                              child: Text(
                                'HADIR (READY)',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.0),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: _selectedStatus == 'IZIN'
                                    ? (isDark ? Colors.white : Colors.black)
                                    : Colors.transparent,
                                foregroundColor: _selectedStatus == 'IZIN'
                                    ? (isDark ? Colors.black : Colors.white)
                                    : (isDark ? Colors.white : Colors.black),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                side: BorderSide(color: isDark ? AppColors.mono700 : AppColors.mono400),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                setState(() => _selectedStatus = 'IZIN');
                              },
                              child: Text(
                                'IZIN / ABSEN',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Alasan izin (hanya jika IZIN)
                      if (_selectedStatus == 'IZIN') ...[
                        TextField(
                          controller: _alasanCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'ALASAN IZIN (MIN. 10 KARAKTER)',
                            hintText: 'Contoh: Ada kuliah malam / lembur kantor',
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ─── IMAGE PICKER SECTION ─────────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _pickedImage != null
                                ? AppColors.statusPresent
                                : (isDark ? AppColors.mono700 : AppColors.mono300),
                            width: _pickedImage != null ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          children: [
                            if (_pickedImage != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: Image.file(
                                  File(_pickedImage!.path),
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.check_circle, size: 14, color: AppColors.statusPresent),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'BUKTI TERLAMPIR',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                        color: AppColors.statusPresent,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setState(() {
                                      _pickedImage = null;
                                      _pickedImageBytes = null;
                                    }),
                                    child: Text(
                                      'HAPUS',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 36,
                                color: isDark ? AppColors.mono400 : AppColors.mono700,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedStatus == 'PRESENT'
                                    ? 'UPLOAD SCREENSHOT LOBBY VALORANT (WAJIB)'
                                    : 'LAMPIRAN BUKTI KENDALA (OPSIONAL)',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  color: isDark ? AppColors.mono400 : AppColors.mono700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'JPG, PNG, atau WEBP • Maksimal 5MB',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: isDark ? AppColors.mono500 : AppColors.mono600,
                                ),
                              ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                          side: BorderSide(color: isDark ? AppColors.mono700 : AppColors.mono400),
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                        ),
                                        onPressed: () => _pickImage(ImageSource.camera),
                                        icon: const Icon(Icons.camera_alt, size: 16),
                                        label: Text('KAMERA', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                          side: BorderSide(color: isDark ? AppColors.mono700 : AppColors.mono400),
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                        ),
                                        onPressed: () => _pickImage(ImageSource.gallery),
                                        icon: const Icon(Icons.photo_library_outlined, size: 16),
                                        label: Text('GALERI', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Tombol Submit
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white : Colors.black,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                          ),
                          onPressed: _submitting
                              ? null
                              : () => _confirmAndSubmit(pendingSchedules),
                          child: _submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                                )
                              : Text(
                                  _selectedStatus == 'PRESENT' ? 'TRANSMIT KEHADIRAN' : 'KIRIM PENGAJUAN IZIN',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
