import 'package:flutter_test/flutter_test.dart';
import 'package:mangansage/shared/models/user.dart';

void main() {
  group('User.fromJson', () {
    test('parses full payload from /api/login response', () {
      final json = {
        'id': 42,
        'name': 'Andi Pratama',
        'email': 'andi@example.com',
        'avatar': null,
        'is_online': true,
        'last_seen': '2026-05-28T08:30:00.000000Z',
      };

      final user = User.fromJson(json);

      expect(user.id, 42);
      expect(user.name, 'Andi Pratama');
      expect(user.email, 'andi@example.com');
      expect(user.avatar, isNull);
      expect(user.isOnline, isTrue);
      expect(user.lastSeen, isNotNull);
      expect(user.lastSeen!.year, 2026);
    });

    test('handles null last_seen and avatar', () {
      final user = User.fromJson({
        'id': 1,
        'name': 'New User',
        'email': 'new@example.com',
        'avatar': null,
        'is_online': false,
        'last_seen': null,
      });

      expect(user.avatar, isNull);
      expect(user.lastSeen, isNull);
      expect(user.isOnline, isFalse);
    });
  });
}
