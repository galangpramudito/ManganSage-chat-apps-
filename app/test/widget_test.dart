// Smoke test untuk app routing & auth flow.
//
// Catatan: kita override `secureStorageProvider` dengan implementasi
// in-memory karena `flutter_secure_storage` tidak berjalan di host test env.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mangansage/core/network/secure_storage.dart';
import 'package:mangansage/main.dart';

class _FakeSecureStorage extends SecureStorage {
  String? _token;

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> saveToken(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}

void main() {
  testWidgets('App boots dan redirect ke /login saat tidak ada token',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStorageProvider.overrideWithValue(_FakeSecureStorage()),
        ],
        child: const MangansageApp(),
      ),
    );

    // Beberapa frame untuk redirect + animasi splash.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // LoginScreen punya heading "Mangansage" dan tombol "Masuk".
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Mangansage'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Belum punya akun? Daftar'), findsOneWidget);
  });
}
