// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messages_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MessagesPage _$MessagesPageFromJson(Map<String, dynamic> json) =>
    _MessagesPage(
      data: (json['data'] as List<dynamic>)
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: PageMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MessagesPageToJson(_MessagesPage instance) =>
    <String, dynamic>{'data': instance.data, 'meta': instance.meta};

_PageMeta _$PageMetaFromJson(Map<String, dynamic> json) => _PageMeta(
  currentPage: (json['current_page'] as num).toInt(),
  lastPage: (json['last_page'] as num).toInt(),
  perPage: (json['per_page'] as num).toInt(),
);

Map<String, dynamic> _$PageMetaToJson(_PageMeta instance) => <String, dynamic>{
  'current_page': instance.currentPage,
  'last_page': instance.lastPage,
  'per_page': instance.perPage,
};
