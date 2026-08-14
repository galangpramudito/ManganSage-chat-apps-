import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/updater/app_updater_service.dart';

/// Flag guard agar dialog tidak pernah terbuka lebih dari 1 kali secara bersamaan
bool _isUpdateDialogShowing = false;

/// Dialog yang muncul saat update tersedia.
///
/// - Menampilkan versi baru + release notes
/// - Tombol "Update Sekarang" dengan progress bar
/// - Jika [release.forceUpdate] = true, dialog tidak bisa di-dismiss
void showUpdateDialog(BuildContext context, WidgetRef ref, AppRelease release) {
  if (_isUpdateDialogShowing) return;
  _isUpdateDialogShowing = true;

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!context.mounted) {
      _isUpdateDialogShowing = false;
      return;
    }
    try {
      await showDialog(
        context: context,
        barrierDismissible: !release.forceUpdate,
        builder: (_) => PopScope(
          canPop: !release.forceUpdate,
          child: _UpdateDialogContent(release: release),
        ),
      );
    } finally {
      _isUpdateDialogShowing = false;
    }
  });
}

class _UpdateDialogContent extends ConsumerStatefulWidget {
  final AppRelease release;
  const _UpdateDialogContent({required this.release});

  @override
  ConsumerState<_UpdateDialogContent> createState() => _UpdateDialogContentState();
}

class _UpdateDialogContentState extends ConsumerState<_UpdateDialogContent> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String? _error;

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _error = null;
    });

    try {
      await AppUpdaterService.downloadAndInstall(
        widget.release,
        onProgress: (progress) {
          if (mounted) {
            setState(() => _progress = progress);
          }
        },
      );
      // Installer terbuka — dialog bisa ditutup
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _error = 'Gagal mengunduh update. Coba lagi.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.mono900 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Row(
        children: [
          Icon(
            Icons.system_update_outlined,
            color: Colors.blue.shade400,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Update Tersedia',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Versi baru
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade900.withOpacity(isDark ? 0.3 : 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue.shade700.withOpacity(0.5)),
            ),
            child: Text(
              'Versi terbaru: v${widget.release.version}',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Colors.blue.shade400,
              ),
            ),
          ),

          // Release notes
          if (widget.release.releaseNotes != null &&
              widget.release.releaseNotes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Catatan update:',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: isDark ? AppColors.mono400 : AppColors.mono600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.release.releaseNotes!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],

          // Force update warning
          if (widget.release.forceUpdate) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red.shade700.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Update wajib. Kamu harus update untuk melanjutkan.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Progress bar saat download
          if (_isDownloading) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 8,
                backgroundColor: isDark ? AppColors.mono800 : AppColors.mono200,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Mengunduh... ${(_progress * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isDark ? AppColors.mono400 : AppColors.mono600,
              ),
            ),
          ],

          // Error message
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.red.shade400),
            ),
          ],
        ],
      ),
      actions: [
        // Tombol "Nanti" (hanya muncul jika bukan force update & belum download)
        if (!widget.release.forceUpdate && !_isDownloading)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Nanti',
              style: GoogleFonts.inter(
                color: isDark ? AppColors.mono400 : AppColors.mono600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

        // Tombol "Update Sekarang"
        if (!_isDownloading)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              elevation: 0,
            ),
            onPressed: _startDownload,
            icon: const Icon(Icons.download_rounded, size: 18),
            label: Text(
              'Update Sekarang',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
      ],
    );
  }
}
