import 'package:freezed_annotation/freezed_annotation.dart';

import 'message.dart';

part 'messages_page.freezed.dart';
part 'messages_page.g.dart';

/// Wrapper Laravel pagination (data + meta).
/// Dipakai untuk GET /api/conversations/{id}/messages.
@freezed
abstract class MessagesPage with _$MessagesPage {
  const factory MessagesPage({
    required List<Message> data,
    required PageMeta meta,
  }) = _MessagesPage;

  factory MessagesPage.fromJson(Map<String, dynamic> json) =>
      _$MessagesPageFromJson(json);
}

@freezed
abstract class PageMeta with _$PageMeta {
  const factory PageMeta({
    @JsonKey(name: 'current_page') required int currentPage,
    @JsonKey(name: 'last_page') required int lastPage,
    @JsonKey(name: 'per_page') required int perPage,
  }) = _PageMeta;

  factory PageMeta.fromJson(Map<String, dynamic> json) =>
      _$PageMetaFromJson(json);
}
