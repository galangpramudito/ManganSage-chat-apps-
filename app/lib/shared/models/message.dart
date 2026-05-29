import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

/// Satu pesan dalam conversation.
/// Mengikuti technical-spec.md §2.4.
@freezed
abstract class Message with _$Message {
  const factory Message({
    required int id,
    @JsonKey(name: 'sender_id') required int senderId,
    required String body,
    @JsonKey(name: 'is_read') @Default(false) bool isRead,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
}
