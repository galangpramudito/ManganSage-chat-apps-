import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/message.dart';
import '../../../shared/models/messages_page.dart';

/// HTTP wrapper untuk endpoint messages (technical-spec.md §2.4).
class MessagesApi {
  MessagesApi(this._dio);

  final Dio _dio;

  /// GET /api/conversations/{conversationId}/messages?page=&per_page=
  Future<MessagesPage> page(
    int conversationId, {
    int page = 1,
    int perPage = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiConstants.conversationMessages(conversationId),
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return MessagesPage.fromJson(res.data!);
  }

  /// POST /api/conversations/{conversationId}/messages
  Future<Message> send(int conversationId, String body) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiConstants.conversationMessages(conversationId),
      data: {'body': body},
    );
    return Message.fromJson(res.data!);
  }

  /// POST /api/conversations/{conversationId}/read
  Future<void> markAllRead(int conversationId) async {
    await _dio.post(ApiConstants.conversationRead(conversationId));
  }
}

final messagesApiProvider = Provider<MessagesApi>(
  (ref) => MessagesApi(ref.watch(dioProvider)),
);
