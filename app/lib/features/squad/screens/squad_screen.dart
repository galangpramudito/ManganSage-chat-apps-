import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/supabase_models.dart';
import '../../../shared/widgets/avatar_widget.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../auth/providers/auth_notifier.dart';

import '../providers/squad_notifier.dart';

class SquadScreen extends ConsumerWidget {
  const SquadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final asyncMembers = ref.watch(squadMembersProvider);
    final asyncLeaderboard = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'ROSTER & LEADERBOARD',
              style: AppTypography.headingTitle(isDark).copyWith(fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () {
              ref.invalidate(squadMembersProvider);
              ref.invalidate(leaderboardProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(squadMembersProvider);
          ref.invalidate(leaderboardProvider);
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // ─── Header Banner ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? AppColors.mono900 : AppColors.mono50,
                border: Border.all(color: isDark ? AppColors.mono800 : AppColors.mono200),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MNG GROUP // VALORANT',
                        style: AppTypography.badgeText(isDark),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.statusPresent),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          'SYNC ACTIVE',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: AppColors.statusPresent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'OFFICIAL ROSTER',
                    style: AppTypography.headingTitle(isDark).copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sinkronisasi data real-time dengan portal mngesports.my.id',
                    style: AppTypography.bodyText(isDark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ─── Section: MVP Leaderboard ──────────────────────────────────
            Row(
              children: [
                const Icon(Icons.emoji_events_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  'MVP LEADERBOARD (TOP 3)',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            asyncLeaderboard.when(
              data: (mvps) => _MvpPodiumList(mvps: mvps, isDark: isDark),
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2))),
              error: (err, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Gagal memuat MVP',
                subtitle: err.toString(),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ─── Section: Squad Members Roster ─────────────────────────────
            Row(
              children: [
                const Icon(Icons.people_outline, size: 20),
                const SizedBox(width: 8),
                Text(
                  asyncMembers.maybeWhen(
                    data: (m) => 'DAFTAR ANGGOTA TIM (${m.length})',
                    orElse: () => 'DAFTAR ANGGOTA TIM',
                  ),
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            asyncMembers.when(
              data: (members) {
                if (members.isEmpty) {
                  return const EmptyState(
                    icon: Icons.people_outline,
                    title: 'Belum ada anggota terdaftar',
                  );
                }
                final currentUserId = ref.watch(authNotifierProvider).value?.id;

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: members.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final member = members[i];
                    final isCurrentUser = member.id == currentUserId;
                    return _MemberCard(
                      user: member,
                      isDark: isDark,
                      isCurrentUser: isCurrentUser,
                    );
                  },
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2))),
              error: (err, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Gagal memuat roster',
                subtitle: err.toString(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MvpPodiumList extends StatelessWidget {
  const _MvpPodiumList({required this.mvps, required this.isDark});
  final List<Mvp> mvps;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (mvps.isEmpty) {
      return const EmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'Belum ada data MVP',
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: mvps.take(3).map((mvp) {
          final isTop1 = mvp.rank == 1;
          final isTop2 = mvp.rank == 2;

          final rankColor = isTop1
              ? const Color(0xFFEAB308) // Amber gold
              : isTop2
                  ? const Color(0xFF94A3B8) // Silver
                  : const Color(0xFFB45309); // Bronze

          return Container(
            width: 145,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.mono900 : AppColors.mono50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isTop1 ? rankColor : (isDark ? AppColors.mono800 : AppColors.mono200),
                width: isTop1 ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: rankColor.withValues(alpha: 0.15),
                        border: Border.all(color: rankColor),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        '#0${mvp.rank}',
                        style: TextStyle(
                          color: rankColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const Icon(Icons.star, size: 14, color: Color(0xFFEAB308)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  mvp.nama,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'MVP', // You can modify this later if MVP has role
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.mono400 : AppColors.mono700,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : Colors.black,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Center(
                    child: Text(
                      '${mvp.pts} PTS',
                      style: GoogleFonts.inter(
                        color: isDark ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.user,
    required this.isDark,
    this.isCurrentUser = false,
  });

  final SquadMember user;
  final bool isDark;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? (isDark ? AppColors.mono900 : Colors.white)
            : (isDark ? AppColors.mono900 : AppColors.backgroundLight),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isCurrentUser
              ? AppColors.statusPresent
              : (isDark ? AppColors.mono800 : AppColors.mono200),
          width: isCurrentUser ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          AvatarWidget(nama: user.nama),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.nama.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 1.0,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.statusPresent.withValues(alpha: 0.15),
                          border: Border.all(color: AppColors.statusPresent),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text(
                          'KAMU',
                          style: TextStyle(
                            color: AppColors.statusPresent,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'MEMBER',
                  style: GoogleFonts.inter(
                    color: isDark ? AppColors.mono400 : AppColors.mono700,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

