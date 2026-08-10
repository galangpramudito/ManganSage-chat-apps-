import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../data/auth_api.dart';
import '../data/auth_exception.dart';
import '../providers/auth_notifier.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _needsMigration = false;
  bool _verificationSent = false;
  String? _migrationCodename;
  String? _generalError;
  Map<String, List<String>> _fieldErrors = const {};

  @override
  void dispose() {
    _namaCtrl.dispose();
    _passwordCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _generalError = null;
      _fieldErrors = const {};
    });

    if (!_formKey.currentState!.validate()) return;

    final cleanNama = _namaCtrl.text.trim();
    final password = _passwordCtrl.text;

    // Check if input is codename (not email)
    if (!cleanNama.contains('@')) {
      final authApi = ref.read(authApiProvider);
      final existingEmail = await authApi.getMemberEmail(cleanNama);

      if (existingEmail == null) {
        // Check if member is registered in squad_members
        final exists = await authApi.checkMemberExists(cleanNama);
        if (exists) {
          // Member exists but has no email -> Trigger Upgrade Akun flow
          setState(() {
            _needsMigration = true;
            _migrationCodename = cleanNama;
            _generalError = null;
            _verificationSent = false;
          });
          return;
        }
      }
    }

    try {
      await ref.read(authNotifierProvider.notifier).login(
            nama: cleanNama,
            password: password,
          );
    } on AuthException catch (e) {
      if (!mounted) return;
      if (!cleanNama.contains('@')) {
        final authApi = ref.read(authApiProvider);
        final existingEmail = await authApi.getMemberEmail(cleanNama);
        if (existingEmail == null) {
          final exists = await authApi.checkMemberExists(cleanNama);
          if (exists) {
            setState(() {
              _needsMigration = true;
              _migrationCodename = cleanNama;
              _generalError = null;
              _verificationSent = false;
            });
            return;
          }
        }
      }
      setState(() {
        _generalError = e.isValidation ? null : e.message;
        _fieldErrors = e.fieldErrors;
      });
    }
  }

  Future<void> _submitMigration() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _generalError = null;
      _fieldErrors = const {};
    });

    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _generalError = 'Masukkan alamat email yang valid.');
      return;
    }

    try {
      await ref.read(authNotifierProvider.notifier).registerAndLinkEmail(
            nama: _migrationCodename!,
            email: email,
            password: _passwordCtrl.text,
          );
    } on AuthException catch (e) {
      if (!mounted) return;
      if (e.message != null && e.message!.startsWith('VERIFICATION_SENT:')) {
        setState(() {
          _verificationSent = true;
          _generalError = null;
        });
      } else {
        setState(() {
          _generalError = e.isValidation ? null : e.message;
          _fieldErrors = e.fieldErrors;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: SvgPicture.asset(
                        isDark ? 'assets/manganlogo.svg' : 'assets/manganlogo_themelight.svg',
                        width: 180,
                        height: 180,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _verificationSent
                          ? 'VERIFIKASI EMAIL'
                          : (_needsMigration ? 'UPGRADE AKUN' : 'SYSTEM LOGIN'),
                      style: GoogleFonts.montserrat(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        letterSpacing: 2.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _verificationSent
                          ? 'ACTION REQUIRED'
                          : (_needsMigration ? 'EMAIL REQUIRED' : 'MNG GROUP IDENTITY REQUIRED'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        color: isDark ? AppColors.mono400 : AppColors.mono500,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (_needsMigration && !_verificationSent) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Halo $_migrationCodename, tautkan email aktif untuk mengamankan akun dan menerima notifikasi resmi.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? AppColors.mono400 : AppColors.mono600,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    if (_generalError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          border: Border.all(color: Colors.red),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          _generalError!,
                          style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (_verificationSent) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.mono900 : AppColors.mono50,
                          border: Border.all(color: AppColors.statusPresent),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.mark_email_read_outlined, size: 48, color: AppColors.statusPresent),
                            const SizedBox(height: 12),
                            Text(
                              'Link Verifikasi Terkirim!',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Kami telah mengirim link konfirmasi ke ${_emailCtrl.text.trim()}.\n\nHarap periksa inbox (atau folder spam) di Gmail Anda dan klik link konfirmasi untuk mengaktifkan akun MNG Group Anda.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(fontSize: 12, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white : Colors.black,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                          ),
                          onPressed: () {
                            setState(() {
                              _needsMigration = false;
                              _verificationSent = false;
                              _generalError = null;
                            });
                          },
                          child: Text(
                            'SAYA SUDAH VERIFIKASI (MASUK)',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ] else if (!_needsMigration) ...[
                      TextFormField(
                        controller: _namaCtrl,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        enableSuggestions: false,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          labelText: 'CODENAME / USERNAME',
                          labelStyle: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                          prefixIcon: const Icon(Icons.person_outline, size: 20),
                          errorText: _fieldErrors['nama']?.firstOrNull,
                        ),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Codename / Username wajib diisi.';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        enabled: !isLoading,
                        onFieldSubmitted: (_) {
                          if (!isLoading) _submit();
                        },
                        decoration: InputDecoration(
                          labelText: 'PASSCODE',
                          labelStyle: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          errorText: _fieldErrors['password']?.firstOrNull,
                        ),
                        validator: (v) {
                          final value = v ?? '';
                          if (value.isEmpty) return 'Passcode wajib diisi.';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white : Colors.black,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                          ),
                          onPressed: isLoading ? null : _submit,
                          child: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                                )
                              : Text(
                                  'AUTHENTICATE',
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                        ),
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        autocorrect: false,
                        enableSuggestions: false,
                        enabled: !isLoading,
                        onFieldSubmitted: (_) {
                          if (!isLoading) _submitMigration();
                        },
                        decoration: InputDecoration(
                          labelText: 'ALAMAT EMAIL AKTIF',
                          hintText: 'contoh@gmail.com',
                          labelStyle: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                          prefixIcon: const Icon(Icons.email_outlined, size: 20),
                        ),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Alamat email wajib diisi.';
                          if (!value.contains('@')) return 'Format email tidak valid.';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white : Colors.black,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                          ),
                          onPressed: isLoading ? null : _submitMigration,
                          child: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                                )
                              : Text(
                                  'UPGRADE & MASUK',
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                setState(() {
                                  _needsMigration = false;
                                  _migrationCodename = null;
                                  _generalError = null;
                                });
                              },
                        child: Text(
                          'KEMBALI KE LOGIN',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.mono400 : AppColors.mono600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Authorized Personnel Only · © 2026 MNG Group',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: isDark ? AppColors.mono500 : AppColors.mono600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
