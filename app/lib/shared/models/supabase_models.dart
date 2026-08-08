import 'package:freezed_annotation/freezed_annotation.dart';

part 'supabase_models.freezed.dart';
part 'supabase_models.g.dart';

@freezed
abstract class SquadMember with _$SquadMember {
  const SquadMember._();
  const factory SquadMember({
    required String id,
    required String nama,
    required String role,
    @JsonKey(name: 'user_id') String? userId,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _SquadMember;

  factory SquadMember.fromJson(Map<String, dynamic> json) =>
      _$SquadMemberFromJson(json);
}

@freezed
abstract class Absensi with _$Absensi {
  const Absensi._();
  const factory Absensi({
    required String id,
    required String nama,
    @JsonKey(name: 'image_url') required String imageUrl,
    @JsonKey(name: 'schedule_id') String? scheduleId,
    String? status,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Absensi;

  factory Absensi.fromJson(Map<String, dynamic> json) =>
      _$AbsensiFromJson(json);
}

@freezed
abstract class ScheduleModel with _$ScheduleModel {
  const ScheduleModel._();
  const factory ScheduleModel({
    required String id,
    required String title,
    @JsonKey(name: 'start_time') required DateTime startTime,
    @JsonKey(name: 'end_time') required DateTime endTime,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _ScheduleModel;

  factory ScheduleModel.fromJson(Map<String, dynamic> json) =>
      _$ScheduleModelFromJson(json);
}

@freezed
abstract class Announcement with _$Announcement {
  const Announcement._();
  const factory Announcement({
    required String id,
    required String message,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Announcement;

  factory Announcement.fromJson(Map<String, dynamic> json) =>
      _$AnnouncementFromJson(json);
}

@freezed
abstract class Mvp with _$Mvp {
  const Mvp._();
  const factory Mvp({
    required String id,
    required int rank,
    required String nama,
    @Default(0) int pts,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Mvp;

  factory Mvp.fromJson(Map<String, dynamic> json) => _$MvpFromJson(json);
}
