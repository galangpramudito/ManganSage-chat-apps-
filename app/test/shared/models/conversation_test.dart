import 'package:flutter_test/flutter_test.dart';
import 'package:mangansage/shared/models/conversation.dart';

void main() {
  group('Conversation.fromJson', () {
    test('parses inbox payload with last_message', () {
      final conv = Conversation.fromJson({
        'id': 1,
        'participant': {'id': 2, 'name': 'Budi Santoso', 'avatar': null},
        'last_message': {
          'body': 'Hei, apa kabar?',
          'created_at': '2026-05-28T10:00:00.000000Z',
          'is_read': false,
        },
        'unread_count': 3,
      });

      expect(conv.id, 1);
      expect(conv.participant.id, 2);
      expect(conv.participant.name, 'Budi Santoso');
      expect(conv.participant.avatar, isNull);
      expect(conv.lastMessage, isNotNull);
      expect(conv.lastMessage!.body, 'Hei, apa kabar?');
      expect(conv.lastMessage!.isRead, false);
      expect(conv.unreadCount, 3);
    });

    test('parses conversation with no last_message yet', () {
      final conv = Conversation.fromJson({
        'id': 5,
        'participant': {'id': 9, 'name': 'Test', 'avatar': null},
        'last_message': null,
        'unread_count': 0,
      });

      expect(conv.lastMessage, isNull);
      expect(conv.unreadCount, 0);
    });
  });
}
