// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Message _$MessageFromJson(Map<String, dynamic> json) => _Message(
  id: (json['id'] as num).toInt(),
  senderId: (json['sender_id'] as num).toInt(),
  body: json['body'] as String,
  isRead: json['is_read'] as bool? ?? false,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$MessageToJson(_Message instance) => <String, dynamic>{
  'id': instance.id,
  'sender_id': instance.senderId,
  'body': instance.body,
  'is_read': instance.isRead,
  'created_at': instance.createdAt.toIso8601String(),
};
