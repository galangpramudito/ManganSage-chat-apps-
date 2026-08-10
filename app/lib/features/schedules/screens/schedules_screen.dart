import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/attendance_badge.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../attendance/data/attendance_api.dart';
import '../../attendance/providers/attendance_notifier.dart';

class SchedulesScreen extends ConsumerStatefulWidget {
  const SchedulesScreen({super.key});

  @override
  ConsumerState<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends ConsumerState<SchedulesScreen> {
  // Active status filter: 'ALL', 'PRESENT', 'LATE', 'IZIN'
  String _activeFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final asyncHistory = ref.watch(myAttendanceHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'RIWAYAT PRESENSI',
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
        onRefresh: () async {
          ref.invalidate(myAttendanceHistoryProvider);
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: asyncHistory.when(
          data: (history) {
            if (history.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100),
                  EmptyState(
                    icon: Icons.history_outlined,
                    title: 'Belum ada riwayat',
                    subtitle: 'Belum ada data presensi yang tercatat.',
                  ),
                ],
              );
            }

            final stats = _computeStats(history);

            // Filter history according to active filter
            final filteredHistory = _filterRecords(history, _activeFilter);
            final groups = _groupByDate(filteredHistory);

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // ─── Stats Summary & Interactive Filter ─────────────────
                _StatsSummary(
                  stats: stats,
                  activeFilter: _activeFilter,
                  onSelectFilter: (filter) {
                    setState(() => _activeFilter = filter);
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.md),

                if (filteredHistory.isEmpty) ...[
                  const SizedBox(height: 40),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_list_off, size: 36, color: isDark ? AppColors.mono600 : AppColors.mono400),
                        const SizedBox(height: 8),
                        Text(
                          'Tidak ada riwayat dengan filter "$_activeFilter"',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? AppColors.mono400 : AppColors.mono600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => setState(() => _activeFilter = 'ALL'),
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('RESET FILTER'),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // ─── Grouped History ────────────────────────────────────
                  ...groups.entries.expand((entry) {
                    return [
                      _DateHeader(label: entry.key, isDark: isDark),
                      const SizedBox(height: 8),
                      ...entry.value.map((record) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _HistoryCard(record: record, isDark: isDark),
                      )),
                      const SizedBox(height: 8),
                    ];
                  }),
                ],
              ],
            );
          },
          loading: () => ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, __) => const SkeletonCard(),
          ),
          error: (err, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 100),
              EmptyState(
                icon: Icons.error_outline,
                title: 'Gagal memuat riwayat',
                subtitle: err.toString(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<AttendanceRecord> _filterRecords(List<AttendanceRecord> records, String filter) {
    if (filter == 'ALL') return records;
    if (filter == 'IZIN') {
      return records.where((r) => r.status.toUpperCase().contains('IZIN')).toList();
    }
    return records.where((r) => r.status.toUpperCase() == filter).toList();
  }

  /// Group records by date label ("Hari Ini", "Kemarin", "dd MMM yyyy")
  Map<String, List<AttendanceRecord>> _groupByDate(List<AttendanceRecord> records) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<AttendanceRecord>> groups = {};

    for (final record in records) {
      final recordDate = record.createdAt.toLocal();
      final dateOnly = DateTime(recordDate.year, recordDate.month, recordDate.day);

      String label;
      if (dateOnly == today) {
        label = 'Hari Ini';
      } else if (dateOnly == yesterday) {
        label = 'Kemarin';
      } else {
        label = DateFormat('dd MMM yyyy', 'id_ID').format(recordDate);
      }

      groups.putIfAbsent(label, () => []).add(record);
    }

    return groups;
  }

  /// Compute attendance stats
  Map<String, int> _computeStats(List<AttendanceRecord> records) {
    int present = 0, late = 0, izin = 0;
    for (final r in records) {
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
    return {
      'total': records.length,
      'present': present,
      'late': late,
      'izin': izin,
    };
  }
}

// ─── Stats Summary & Interactive Filter Widget ────────────────────────────────

class _StatsSummary extends StatelessWidget {
  const _StatsSummary({
    required this.stats,
    required this.activeFilter,
    required this.onSelectFilter,
    required this.isDark,
  });

  final Map<String, int> stats;
  final String activeFilter;
  final ValueChanged<String> onSelectFilter;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.mono900 : AppColors.mono50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isDark ? AppColors.mono800 : AppColors.mono200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _filterPill('ALL', 'TOTAL', stats['total'] ?? 0, isDark ? Colors.white : Colors.black),
          _divider(),
          _filterPill('PRESENT', 'HADIR', stats['present'] ?? 0, AppColors.statusPresent),
          _divider(),
          _filterPill('LATE', 'TELAT', stats['late'] ?? 0, AppColors.statusLate),
          _divider(),
          _filterPill('IZIN', 'IZIN', stats['izin'] ?? 0, AppColors.statusIzin),
        ],
      ),
    );
  }

  Widget _filterPill(String filterKey, String label, int count, Color color) {
    final isSelected = activeFilter == filterKey;

    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onSelectFilter(isSelected && filterKey != 'ALL' ? 'ALL' : filterKey);
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.mono800 : AppColors.mono200)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  letterSpacing: 1.2,
                  color: isSelected
                      ? color
                      : (isDark ? AppColors.mono400 : AppColors.mono600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 24,
      color: isDark ? AppColors.mono800 : AppColors.mono200,
    );
  }
}

// ─── Date Group Header ────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.label, required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
          color: isDark ? AppColors.mono500 : AppColors.mono400,
        ),
      ),
    );
  }
}

// ─── History Card ─────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.record, required this.isDark});
  final AttendanceRecord record;
  final bool isDark;

  void _openImageZoom(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy • HH:mm', 'id_ID').format(record.createdAt.toLocal());

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.mono900 : AppColors.backgroundLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DETAIL KEHADIRAN',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0),
                  ),
                  AttendanceBadge(status: record.status),
                ],
              ),
              const SizedBox(height: 16),
              _infoRow('JADWAL MATCH', record.scheduleTitle ?? 'N/A'),
              const SizedBox(height: 10),
              _infoRow('WAKTU TRANSMIT', dateStr),
              const SizedBox(height: 10),
              if (record.status.contains('IZIN')) ...[
                _infoRow('ALASAN IZIN', record.alasan ?? 'Tidak ada alasan'),
                const SizedBox(height: 10),
              ],
              if (record.imageUrl != null && record.imageUrl!.isNotEmpty && record.imageUrl != 'N/A') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'BUKTI FOTO',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: isDark ? AppColors.mono500 : AppColors.mono600,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.zoom_in, size: 14, color: isDark ? AppColors.mono400 : AppColors.mono600),
                        const SizedBox(width: 4),
                        Text(
                          'KETUK UNTUK ZOOM',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.mono400 : AppColors.mono600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _openImageZoom(context, record.imageUrl!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      record.imageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      cacheWidth: 600,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          color: isDark ? AppColors.mono800 : AppColors.mono100,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.mono800 : AppColors.mono100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.broken_image_outlined, size: 28, color: isDark ? AppColors.mono600 : AppColors.mono400),
                                const SizedBox(height: 4),
                                Text(
                                  'Gagal memuat gambar',
                                  style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppColors.mono500 : AppColors.mono600),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.mono800 : AppColors.mono100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.image_not_supported_outlined, size: 18, color: isDark ? AppColors.mono500 : AppColors.mono600),
                      const SizedBox(width: 8),
                      Text(
                        'Tidak ada lampiran bukti',
                        style: GoogleFonts.inter(fontSize: 12, color: isDark ? AppColors.mono500 : AppColors.mono600, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: isDark ? AppColors.mono500 : AppColors.mono600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm', 'id_ID').format(record.createdAt.toLocal());
    final title = record.scheduleTitle ?? 'MATCH VALORANT';

    return GestureDetector(
      onTap: () => _showDetailSheet(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.mono900 : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isDark ? AppColors.mono800 : AppColors.mono200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Time pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.mono800 : AppColors.mono100,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                timeStr,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.mono400 : AppColors.mono600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            AttendanceBadge(status: record.status),
          ],
        ),
      ),
    );
  }
}
