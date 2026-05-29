import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

/// Lawan bicara di sebuah conversation 1-on-1.
/// Backend mengirim id/name/avatar + presence (is_online/last_seen).
@freezed
abstract class Participant with _$Participant {
  const factory Participant({
    required int id,
    required String name,
    String? avatar,
    @JsonKey(name: 'is_online') @Default(false) bool isOnline,
    @JsonKey(name: 'last_seen') DateTime? lastSeen,
  }) = _Participant;

  factory Participant.fromJson(Map<String, dynamic> json) =>
      _$ParticipantFromJson(json);
}

/// Preview pesan terakhir untuk Inbox (subset dari Message).
@freezed
abstract class LastMessagePreview with _$LastMessagePreview {
  const factory LastMessagePreview({
    required String body,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'is_read') @Default(false) bool isRead,
  }) = _LastMessagePreview;

  factory LastMessagePreview.fromJson(Map<String, dynamic> json) =>
      _$LastMessagePreviewFromJson(json);
}

/// Conversation seperti dirender di Inbox.
/// Mengikuti technical-spec.md §2.3.
@freezed
abstract class Conversation with _$Conversation {
  const factory Conversation({
    required int id,
    required Participant participant,
    @JsonKey(name: 'last_message') LastMessagePreview? lastMessage,
    @JsonKey(name: 'unread_count') @Default(0) int unreadCount,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);
}
