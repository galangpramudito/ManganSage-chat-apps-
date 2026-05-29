/// Exception khusus untuk error otentikasi.
/// Membedakan validasi field (422) vs error general/network.
class AuthException implements Exception {
  const AuthException.validation(this.fieldErrors, {this.message})
      : isValidation = true;

  const AuthException.message(this.message)
      : fieldErrors = const {},
        isValidation = false;

  /// Pesan general untuk ditampilkan di banner atas form.
  final String? message;

  /// Map error per field — `{'email': ['email sudah dipakai'], ...}`.
  /// Cocok dengan format response Laravel 422.
  final Map<String, List<String>> fieldErrors;

  final bool isValidation;

  /// Helper: ambil error pertama untuk field tertentu (untuk InputDecoration).
  String? errorFor(String field) => fieldErrors[field]?.firstOrNull;

  @override
  String toString() => 'AuthException(${message ?? fieldErrors})';
}
