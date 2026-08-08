import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  static Widget buildAttendanceBadge(String status) {
    Color badgeColor;
    String label = status;

    switch (status.toUpperCase()) {
      case 'PRESENT':
        badgeColor = AppColors.statusPresent;
        label = 'HADIR';
        break;
      case 'LATE':
        badgeColor = AppColors.statusLate;
        label = 'TERLAMBAT';
        break;
      case 'IZIN':
        badgeColor = AppColors.statusIzin;
        label = 'IZIN';
        break;
      case 'IZIN_LATE':
        badgeColor = AppColors.statusIzinLate;
        label = 'IZIN TERLAMBAT';
        break;
      default:
        badgeColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final asyncSchedules = ref.watch(schedulesListProvider);
    final asyncHistory = ref.watch(myAttendanceHistoryProvider);

    return Scaffold(
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
                final now = DateTime.now().toUtc();

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
                          size: 36,
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
                        const SizedBox(height: 4),
                        Text(
                          history.isNotEmpty
                              ? 'Kamu telah menyelesaikan semua presensi jadwal match aktif.'
                              : 'Admin belum membuka jadwal pertandingan baru saat ini.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isDark ? AppColors.mono400 : AppColors.mono700,
                          ),
                          textAlign: TextAlign.center,
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
                        initialValue: pendingSchedules.any((s) => s.id == _selectedScheduleId)
                            ? _selectedScheduleId
                            : pendingSchedules.first.id,
                        decoration: const InputDecoration(
                          labelText: 'PILIH JADWAL MATCH',
                          prefixIcon: Icon(Icons.sports_esports_outlined, size: 18),
                        ),
                        items: pendingSchedules.map((s) {
                          return DropdownMenuItem(
                            value: s.id,
                            child: Text(
                              s.title.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
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
                              onPressed: () => setState(() => _selectedStatus = 'PRESENT'),
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
                              onPressed: () => setState(() => _selectedStatus = 'IZIN'),
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
                              : () => _submit(pendingSchedules),
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
            const SizedBox(height: AppSpacing.lg),

            // ─── Riwayat Absensi ────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RIWAYAT PRESENSI SAYA',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0),
                ),
                Text('LOGS', style: AppTypography.badgeText(isDark)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            asyncHistory.when(
              data: (history) {
                if (history.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.mono900 : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: isDark ? AppColors.mono800 : AppColors.mono200),
                    ),
                    child: const Center(child: Text('Belum ada riwayat presensi.')),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final item = history[i];
                    final dateStr = DateFormat('dd MMM yyyy • HH:mm', 'id_ID').format(item.createdAt.toLocal());
                    final title = item.scheduleTitle ?? 'MATCH VALORANT';

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.mono900 : AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: isDark ? AppColors.mono800 : AppColors.mono200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Thumbnail foto bukti (Hanya jika ada URL valid dan bukan 'N/A')
                          if (item.imageUrl != null && item.imageUrl!.isNotEmpty && item.imageUrl != 'N/A')
                            Container(
                              width: 44,
                              height: 44,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(color: isDark ? AppColors.mono700 : AppColors.mono300),
                                image: DecorationImage(
                                  image: NetworkImage(item.imageUrl!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title.toUpperCase(),
                                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (item.alasan != null && item.alasan!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Alasan: ${item.alasan}',
                                    style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppColors.mono400 : AppColors.mono700),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  dateStr,
                                  style: GoogleFonts.inter(color: isDark ? AppColors.mono400 : AppColors.mono700, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          AttendanceScreen.buildAttendanceBadge(item.status),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2))),
              error: (err, _) => Text('Gagal memuat riwayat: $err'),
            ),
          ],
        ),
      ),
    );
  }
}
