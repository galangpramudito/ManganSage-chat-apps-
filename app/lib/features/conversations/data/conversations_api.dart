import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/conversation.dart';

/// Hasil dari POST /api/conversations.
typedef ConversationCreateResult = ({
  int id,
  Participant participant,
  bool wasCreated, // true kalau 201 (baru), false kalau 200 (sudah ada)
});

/// HTTP wrapper untuk endpoint conversations (technical-spec.md §2.3).
class ConversationsApi {
  ConversationsApi(this._dio);

  final Dio _dio;

  /// GET /api/conversations
  Future<List<Conversation>> list() async {
    try {
      final res = await _dio.get<dynamic>(ApiConstants.conversations);
      
      if (res.data == null) return const [];
      
      // Handle both array directly or wrapped in {data: [...]}
      final List<dynamic> data;
      if (res.data is List) {
        data = res.data as List;
      } else if (res.data is Map && res.data['data'] is List) {
        data = res.data['data'] as List;
      } else {
        throw Exception('Invalid response format from /api/conversations');
      }
      
      return data
          .map((e) => Conversation.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    } catch (e) {
      debugPrint('❌ Conversations API error: $e');
      rethrow;
    }
  }

  /// POST /api/conversations
  Future<ConversationCreateResult> startWith(int otherUserId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiConstants.conversations,
      data: {'user_id': otherUserId},
    );
    final body = res.data!;
    return (
      id: body['id'] as int,
      participant: Participant.fromJson(
        Map<String, dynamic>.from(body['participant'] as Map),
      ),
      wasCreated: res.statusCode == 201,
    );
  }

  /// DELETE /api/conversations/{id} — soft delete sepihak.
  Future<void> delete(int id) async {
    await _dio.delete(ApiConstants.conversation(id));
  }
}

final conversationsApiProvider = Provider<ConversationsApi>(
  (ref) => ConversationsApi(ref.watch(dioProvider)),
);
