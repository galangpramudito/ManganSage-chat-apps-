import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/notifications/alarm_service.dart';
import '../../../core/notifications/notification_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/avatar_widget.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../attendance/providers/attendance_notifier.dart';
import '../../auth/providers/auth_notifier.dart';
import '../../schedules/providers/schedules_notifier.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(authNotifierProvider);
    final user = switch (asyncUser) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'PROFIL ANGGOTA',
            style: AppTypography.headingTitle(isDark).copyWith(fontSize: 16),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final activeEmail = user.email ?? Supabase.instance.client.auth.currentUser?.email;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PROFIL ANGGOTA',
          style: AppTypography.headingTitle(isDark).copyWith(fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
                // Hero / Info Container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.mono900 : AppColors.backgroundLight,
                    border: Border.all(color: isDark ? AppColors.mono800 : AppColors.mono200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    children: [
                      AvatarWidget(
                        nama: user.nama,
                        size: AvatarSize.profile,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        user.nama.toUpperCase(),
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (activeEmail != null && activeEmail.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.email_outlined, size: 14, color: isDark ? AppColors.mono400 : AppColors.mono600),
                            const SizedBox(width: 6),
                            Text(
                              activeEmail,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.mono300 : AppColors.mono700,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: isDark ? Colors.white : Colors.black),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          user.role.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      if (user.createdAt != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Member sejak ${DateFormat('dd MMM yyyy', 'id_ID').format(user.createdAt!.toLocal())}',
                          style: GoogleFonts.inter(
                            color: isDark ? AppColors.mono400 : AppColors.mono700,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // ─── Attendance Stats ──────────────────────────────────────
                _AttendanceStatsCard(isDark: isDark),

                const SizedBox(height: AppSpacing.md),

                // ─── Notification Settings Tile ────────────────────────────
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showNotificationSettings(context, ref);
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.mono900 : AppColors.backgroundLight,
                      border: Border.all(color: isDark ? AppColors.mono800 : AppColors.mono200),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active_outlined, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PENGATURAN NOTIFIKASI & ALARM',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Kelola alarm match, reminder deadline, & tes notifikasi',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isDark ? AppColors.mono400 : AppColors.mono700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: isDark ? AppColors.mono400 : AppColors.mono600),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Card Sesi & Verifikasi
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.mono900 : AppColors.backgroundLight,
                    border: Border.all(color: isDark ? AppColors.mono800 : AppColors.mono200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('SESI STATUS', style: AppTypography.badgeText(isDark)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.statusPresent),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              'VERIFIED',
                              style: TextStyle(
                                color: AppColors.statusPresent,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (activeEmail != null && activeEmail.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.verified_user_outlined, size: 16, color: AppColors.statusPresent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'EMAIL TERTAUT',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                      color: isDark ? AppColors.mono400 : AppColors.mono600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    activeEmail,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        'Tersambung langsung dengan portal cloud mngesports.my.id',
                        style: AppTypography.bodyText(isDark),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Logout — Sharp Minimalist
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context, ref),
                    icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
                    label: Text(
                      'TERMINATE SESSION (LOGOUT)',
                      style: GoogleFonts.inter(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ─── App Version & Info Footer ─────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Text(
                        'MNG GROUP // VALORANT',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                          color: isDark ? AppColors.mono600 : AppColors.mono400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Version 1.2.0 (Build 2) • Internal System',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: isDark ? AppColors.mono700 : AppColors.mono400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
    );
  }

  void _showNotificationSettings(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.mono900 : AppColors.backgroundLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final prefs = ref.watch(notificationPreferencesProvider);
          final notifier = ref.read(notificationPreferencesProvider.notifier);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.mono700 : AppColors.mono300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'PENGATURAN NOTIFIKASI & ALARM',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Toggle Match Reminder
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Alarm 15 Menit Sebelum Match',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'Pengingat agar segera kumpul dan login in-game',
                      style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppColors.mono400 : AppColors.mono600),
                    ),
                    value: prefs.matchReminderEnabled,
                    activeColor: AppColors.statusPresent,
                    onChanged: (val) {
                      HapticFeedback.lightImpact();
                      notifier.toggleMatchReminder(val);
                    },
                  ),

                  // Toggle Closing Deadline Reminder
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Alarm 15 Menit Sebelum Absen Ditutup',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'Peringatan deadline sebelum presensi hangus',
                      style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppColors.mono400 : AppColors.mono600),
                    ),
                    value: prefs.closingReminderEnabled,
                    activeColor: AppColors.statusPresent,
                    onChanged: (val) {
                      HapticFeedback.lightImpact();
                      notifier.toggleClosingReminder(val);
                    },
                  ),

                  // Toggle Broadcast Announcements
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Notifikasi Pengumuman Broadcast',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'Push notif instan saat admin menerbitkan pengumuman baru',
                      style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppColors.mono400 : AppColors.mono600),
                    ),
                    value: prefs.announcementsEnabled,
                    activeColor: AppColors.statusPresent,
                    onChanged: (val) {
                      HapticFeedback.lightImpact();
                      notifier.toggleAnnouncements(val);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Test Notification Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                        side: BorderSide(color: isDark ? AppColors.mono700 : AppColors.mono400),
                      ),
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        final alarm = ref.read(alarmServiceProvider);
                        await alarm.showInstantNotification(
                          title: 'Uji Coba Notifikasi',
                          body: 'Sistem notifikasi pada perangkat Anda berfungsi dengan normal.',
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notifikasi uji coba berhasil dikirim.'),
                              backgroundColor: AppColors.statusPresent,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.notifications_outlined, size: 18),
                      label: Text(
                        'TEST NOTIFIKASI DI PERANGKAT INI',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: Text(
          'LOGOUT SESSION',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0),
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari sesi akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('BATAL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade900,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx, true);
            },
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }
}

// ─── Attendance Stats Card ────────────────────────────────────────────────────

class _AttendanceStatsCard extends ConsumerWidget {
  const _AttendanceStatsCard({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHistory = ref.watch(myAttendanceHistoryProvider);
    final asyncSchedules = ref.watch(schedulesListProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.mono900 : AppColors.backgroundLight,
        border: Border.all(color: isDark ? AppColors.mono800 : AppColors.mono200),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('STATISTIK PRESENSI & JADWAL', style: AppTypography.badgeText(isDark)),
              const Icon(Icons.analytics_outlined, size: 16),
            ],
          ),
          const SizedBox(height: 14),
          asyncHistory.when(
            data: (history) {
              final schedules = asyncSchedules.value ?? [];
              final now = DateTime.now();

              // Jadwal masa lalu (yang sudah dibuka / sedang / telah selesai)
              final pastSchedules = schedules.where((s) {
                return s.startTime.toLocal().isBefore(now) || 
                       s.endTime.toLocal().isBefore(now);
              }).toList();

              final totalSessions = schedules.length;
              final totalPast = pastSchedules.length;

              // Set ID jadwal yang sudah disubmit presensinya oleh user
              final attendedScheduleIds = history
                  .map((r) => r.scheduleId)
                  .where((id) => id.isNotEmpty)
                  .toSet();

              int present = 0, late = 0, izin = 0;
              for (final r in history) {
                switch (r.status.toUpperCase()) {
                  case 'PRESENT':
                    present++;
                    break;
                  case 'LATE':
                    late++;
                    break;
                  case 'IZIN':
                  case 'IZIN_LATE':
                    izin++;
                    break;
                }
              }

              // Hitung Alpha (Jadwal masa lalu yang tidak dihadiri dan tidak izin)
              int alpha = 0;
              if (totalPast > 0) {
                alpha = pastSchedules.where((s) => !attendedScheduleIds.contains(s.id)).length;
              }

              // Kehadiran Rate (%) dihitung terhadap total jadwal yang sudah berjalan
              final totalHadir = present + late;
              final double progressValue = totalPast > 0 
                  ? (totalHadir / totalPast).clamp(0.0, 1.0)
                  : (history.isNotEmpty ? (totalHadir / history.length).clamp(0.0, 1.0) : 1.0);
              
              final attendanceRate = (progressValue * 100).toStringAsFixed(0);

              // Tentukan warna bar kehadiran berdasarkan rate
              final Color rateColor = progressValue >= 0.75
                  ? AppColors.statusPresent
                  : (progressValue >= 0.5 ? AppColors.statusLate : Colors.redAccent);

              return Column(
                children: [
                  Row(
                    children: [
                      _StatTile(
                        label: 'SESI',
                        value: '$totalSessions',
                        color: isDark ? Colors.white : Colors.black,
                        isDark: isDark,
                      ),
                      _StatTile(
                        label: 'HADIR',
                        value: '$present',
                        color: AppColors.statusPresent,
                        isDark: isDark,
                      ),
                      _StatTile(
                        label: 'TELAT',
                        value: '$late',
                        color: AppColors.statusLate,
                        isDark: isDark,
                      ),
                      _StatTile(
                        label: 'IZIN',
                        value: '$izin',
                        color: AppColors.statusIzin,
                        isDark: isDark,
                      ),
                      _StatTile(
                        label: 'ALPHA',
                        value: '$alpha',
                        color: Colors.redAccent,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Attendance rate bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'KEHADIRAN RATE',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: isDark ? AppColors.mono500 : AppColors.mono600,
                            ),
                          ),
                          Text(
                            '$attendanceRate%',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: rateColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progressValue,
                          minHeight: 6,
                          backgroundColor: isDark ? AppColors.mono800 : AppColors.mono200,
                          valueColor: AlwaysStoppedAnimation<Color>(rateColor),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$totalHadir dari $totalPast match dihadiri • $alpha match alpha',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: isDark ? AppColors.mono500 : AppColors.mono600,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => Column(
              children: const [
                SkeletonLoader(height: 36, margin: EdgeInsets.only(bottom: 8)),
                SkeletonLoader(height: 12),
              ],
            ),
            error: (_, __) => Text(
              'Gagal memuat statistik.',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: isDark ? AppColors.mono500 : AppColors.mono600,
            ),
          ),
        ],
      ),
    );
  }
}
