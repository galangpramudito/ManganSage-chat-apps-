import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/providers/auth_notifier.dart';
import '../providers/announcements_notifier.dart';
import '../../schedules/providers/schedules_notifier.dart';
import '../../squad/providers/squad_notifier.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(authNotifierProvider);
    final user = switch (asyncUser) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MANGAN SQUAD',
          style: AppTypography.headingTitle(isDark).copyWith(fontSize: 16),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeAnnouncementProvider);
          ref.invalidate(schedulesListProvider);
          ref.invalidate(leaderboardProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (user != null) _buildProfileHeader(context, user, isDark),
            const SizedBox(height: AppSpacing.sm),
            _buildAnnouncement(context, isDark, ref),
            const SizedBox(height: AppSpacing.sm),
            _buildTodayStatus(context, isDark, ref),
            const SizedBox(height: AppSpacing.lg),
            _buildQuickActions(context, isDark),
            const SizedBox(height: AppSpacing.lg),
            _buildLeaderboardPreview(context, isDark, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.mono900 : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isDark ? AppColors.mono800 : AppColors.mono200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.mono700,
            child: Text(
              user.nama[0].toUpperCase(),
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, ${user.nama}',
                  style: AppTypography.headingTitle(isDark).copyWith(fontSize: 14),
                ),
                Text(
                  user.role.toUpperCase(),
                  style: AppTypography.messagePreview.copyWith(
                    color: AppColors.mono400,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncement(BuildContext context, bool isDark, WidgetRef ref) {
    final asyncAnnouncement = ref.watch(activeAnnouncementProvider);
    
    return asyncAnnouncement.when(
      data: (announcement) {
        if (announcement == null || !announcement.isActive) return const SizedBox.shrink();
        
        return Container(
          margin: const EdgeInsets.only(top: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.blue.shade900.withOpacity(isDark ? 0.3 : 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.blue.shade700),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.campaign_outlined, color: Colors.blue.shade400, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PENGUMUMAN',
                      style: GoogleFonts.inter(
                        color: Colors.blue.shade400,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      announcement.message,
                      style: AppTypography.bodyText(isDark).copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildTodayStatus(BuildContext context, bool isDark, WidgetRef ref) {
    final asyncSchedules = ref.watch(schedulesListProvider);

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade900, Colors.red.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'JADWAL AKTIF HARI INI',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          asyncSchedules.when(
            data: (schedules) {
              final nowLocal = DateTime.now();
              final activeSchedules = schedules.where((s) {
                final startLocal = s.startTime.toLocal();
                return startLocal.year == nowLocal.year && 
                       startLocal.month == nowLocal.month && 
                       startLocal.day == nowLocal.day;
              }).toList();
              
              if (activeSchedules.isEmpty) {
                return Text(
                  'Belum ada jadwal match hari ini.',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                );
              }
              
              final schedule = activeSchedules.first;
              final timeStr = DateFormat('HH:mm', 'id_ID').format(schedule.startTime.toLocal());
              return Row(
                children: [
                  const Icon(Icons.sports_esports_outlined, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule.title.toUpperCase(),
                          style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'Pukul $timeStr WIB',
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
            error: (_, __) => Text('Gagal memuat jadwal.', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              context.go('/attendance');
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(
              'QUICK ABSEN',
              style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardPreview(BuildContext context, bool isDark, WidgetRef ref) {
    final asyncLeaderboard = ref.watch(leaderboardProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
                'TOP MVP PREVIEW',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.5,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/squad'),
                child: Icon(Icons.chevron_right, color: isDark ? AppColors.mono400 : AppColors.mono600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          asyncLeaderboard.when(
            data: (mvps) {
              if (mvps.isEmpty) {
                return Text('Belum ada data MVP.', style: AppTypography.bodyText(isDark));
              }
              return Column(
                children: mvps.take(3).map((mvp) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: mvp.rank == 1 ? Colors.amber.shade700 : (isDark ? AppColors.mono800 : AppColors.mono200),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${mvp.rank}',
                            style: GoogleFonts.inter(
                              color: mvp.rank == 1 ? Colors.black : (isDark ? Colors.white : Colors.black),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            mvp.nama.toUpperCase(),
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        Text(
                          '${mvp.pts} PTS',
                          style: GoogleFonts.inter(
                            color: AppColors.statusPresent,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2))),
            error: (_, __) => Text('Gagal memuat MVP.', style: AppTypography.bodyText(isDark)),
          ),
        ],
      ),
    );
  }
}
