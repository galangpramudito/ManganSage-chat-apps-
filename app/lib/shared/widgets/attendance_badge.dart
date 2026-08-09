import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Reusable badge widget for attendance status.
/// Used by SchedulesScreen (history list) and AttendanceScreen.
class AttendanceBadge extends StatelessWidget {
  const AttendanceBadge({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
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
}
