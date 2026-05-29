import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/storage_keys.dart';

/// Wrapper sekali-pakai di atas `flutter_secure_storage`.
/// - Android: pakai EncryptedSharedPreferences
/// - iOS: pakai Keychain (default)
class SecureStorage {
  SecureStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token) =>
      _storage.write(key: StorageKeys.sanctumToken, value: token);

  Future<String?> getToken() =>
      _storage.read(key: StorageKeys.sanctumToken);

  Future<void> clear() => _storage.deleteAll();
}

/// Provider singleton untuk SecureStorage.
final secureStorageProvider = Provider<SecureStorage>((ref) => SecureStorage());
