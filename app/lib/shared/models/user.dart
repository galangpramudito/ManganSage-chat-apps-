import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// Representasi user yang dipakai di seluruh aplikasi.
/// Mengikuti shape dari API Laravel (`UserResource`).
@freezed
abstract class User with _$User {
  const factory User({
    required int id,
    required String name,
    required String email,
    String? avatar,
    @JsonKey(name: 'is_online') @Default(false) bool isOnline,
    @JsonKey(name: 'last_seen') DateTime? lastSeen,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
