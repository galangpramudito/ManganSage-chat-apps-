// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Participant _$ParticipantFromJson(Map<String, dynamic> json) => _Participant(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  avatar: json['avatar'] as String?,
  isOnline: json['is_online'] as bool? ?? false,
  lastSeen: json['last_seen'] == null
      ? null
      : DateTime.parse(json['last_seen'] as String),
);

Map<String, dynamic> _$ParticipantToJson(_Participant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'avatar': instance.avatar,
      'is_online': instance.isOnline,
      'last_seen': instance.lastSeen?.toIso8601String(),
    };

_LastMessagePreview _$LastMessagePreviewFromJson(Map<String, dynamic> json) =>
    _LastMessagePreview(
      body: json['body'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
    );

Map<String, dynamic> _$LastMessagePreviewToJson(_LastMessagePreview instance) =>
    <String, dynamic>{
      'body': instance.body,
      'created_at': instance.createdAt.toIso8601String(),
      'is_read': instance.isRead,
    };

_Conversation _$ConversationFromJson(Map<String, dynamic> json) =>
    _Conversation(
      id: (json['id'] as num).toInt(),
      participant: Participant.fromJson(
        json['participant'] as Map<String, dynamic>,
      ),
      lastMessage: json['last_message'] == null
          ? null
          : LastMessagePreview.fromJson(
              json['last_message'] as Map<String, dynamic>,
            ),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ConversationToJson(_Conversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'participant': instance.participant,
      'last_message': instance.lastMessage,
      'unread_count': instance.unreadCount,
    };
