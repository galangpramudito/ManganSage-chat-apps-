import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/notifications/alarm_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/supabase_models.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/schedules_notifier.dart';

class SchedulesScreen extends ConsumerWidget {
  const SchedulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final asyncSchedules = ref.watch(schedulesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'JADWAL MATCH & SCRIM',
          style: AppTypography.headingTitle(isDark).copyWith(fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () => ref.invalidate(schedulesListProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(schedulesListProvider),
        child: asyncSchedules.when(
          data: (schedules) {
            final now = DateTime.now().toUtc();
            // Filter hanya jadwal yang belum lewat (aktif atau upcoming)
            final availableSchedules = schedules.where((s) => s.endTime.toUtc().isAfter(now)).toList();

            if (availableSchedules.isEmpty) {
              return const EmptyState(
                icon: Icons.calendar_today_outlined,
                title: 'Belum ada jadwal pertandingan',
                subtitle: 'Admin belum membuka jadwal match baru.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: availableSchedules.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) => _ScheduleCard(schedule: availableSchedules[i], isDark: isDark),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (err, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'Gagal memuat jadwal',
            subtitle: err.toString(),
          ),
        ),
      ),
    );
  }
}

class _ScheduleCard extends ConsumerWidget {
  const _ScheduleCard({required this.schedule, required this.isDark});
  final ScheduleModel schedule;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now().toUtc();
    final isUpcoming = schedule.startTime.toUtc().isAfter(now);
    final isActive = now.isAfter(schedule.startTime.toUtc()) && now.isBefore(schedule.endTime.toUtc());

    final statusText = isActive
        ? 'LIVE NOW'
        : isUpcoming
            ? 'UPCOMING'
            : 'COMPLETED';

    final statusColor = isActive
        ? AppColors.statusPresent
        : isUpcoming
            ? AppColors.statusIzin
            : (isDark ? AppColors.mono400 : AppColors.mono700);

    // .toLocal() hanya di sini untuk TAMPILAN ke user (WIB/Asia Jakarta)
    final dateStr = DateFormat('EEEE, dd MMM yyyy • HH:mm', 'id_ID').format(schedule.startTime.toLocal());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.mono900 : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isActive ? AppColors.statusPresent : (isDark ? AppColors.mono800 : AppColors.mono200),
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: statusColor),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.inter(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Text(
                'VALORANT SCRIM',
                style: AppTypography.badgeText(isDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            schedule.title.toUpperCase(),
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: isDark ? AppColors.mono400 : AppColors.mono700),
              const SizedBox(width: 6),
              Text(
                dateStr,
                style: GoogleFonts.inter(
                  color: isDark ? AppColors.mono400 : AppColors.mono700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (isUpcoming) ...[
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                      side: BorderSide(color: isDark ? AppColors.mono700 : AppColors.mono400),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      final alarm = ref.read(alarmServiceProvider);
                      await alarm.scheduleCustom(
                        scheduleId: schedule.id,
                        title: '⏰ MATCH REMINDER: ${schedule.title}',
                        body: 'Match dimulai dalam 15 menit! Segera kumpul di Valorant.',
                        scheduledTime: schedule.startTime.subtract(const Duration(minutes: 15)),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Alarm pengingat 15 menit berhasil dipasang!')),
                        );
                      }
                    },
                    child: Text(
                      'SET ALARM',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 1.5,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Buka tab Presensi untuk submit kehadiran!')),
                    );
                  },
                  child: Text(
                    'TRANSMIT ABSEN',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

