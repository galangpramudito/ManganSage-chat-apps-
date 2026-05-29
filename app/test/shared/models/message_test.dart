import 'package:flutter_test/flutter_test.dart';
import 'package:mangansage/shared/models/message.dart';
import 'package:mangansage/shared/models/messages_page.dart';

void main() {
  group('Message.fromJson', () {
    test('parses chat payload', () {
      final msg = Message.fromJson({
        'id': 101,
        'sender_id': 1,
        'body': 'Hai',
        'is_read': false,
        'created_at': '2026-05-28T10:00:00.000000Z',
      });

      expect(msg.id, 101);
      expect(msg.senderId, 1);
      expect(msg.body, 'Hai');
      expect(msg.isRead, false);
      expect(msg.createdAt.year, 2026);
    });
  });

  group('MessagesPage.fromJson', () {
    test('parses Laravel pagination response (data + meta)', () {
      // Shape mengikuti `MessageResource::collection($paginator)` di Laravel.
      // Field tambahan di `meta` (from, to, total, links, path) di-ignore.
      final page = MessagesPage.fromJson({
        'data': [
          {
            'id': 1,
            'sender_id': 2,
            'body': 'Halo',
            'is_read': false,
            'created_at': '2026-05-28T10:00:00.000000Z',
          },
        ],
        'links': {'first': 'http://x', 'last': '', 'prev': null, 'next': null},
        'meta': {
          'current_page': 1,
          'from': 1,
          'last_page': 3,
          'links': [],
          'path': 'http://x',
          'per_page': 20,
          'to': 1,
          'total': 50,
        },
      });

      expect(page.data, hasLength(1));
      expect(page.meta.currentPage, 1);
      expect(page.meta.lastPage, 3);
      expect(page.meta.perPage, 20);
    });
  });
}
