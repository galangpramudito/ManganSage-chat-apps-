// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supabase_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SquadMember _$SquadMemberFromJson(Map<String, dynamic> json) => _SquadMember(
  id: json['id'] as String,
  nama: json['nama'] as String,
  role: json['role'] as String,
  userId: json['user_id'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$SquadMemberToJson(_SquadMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nama': instance.nama,
      'role': instance.role,
      'user_id': instance.userId,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

_Absensi _$AbsensiFromJson(Map<String, dynamic> json) => _Absensi(
  id: json['id'] as String,
  nama: json['nama'] as String,
  imageUrl: json['image_url'] as String,
  scheduleId: json['schedule_id'] as String?,
  status: json['status'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$AbsensiToJson(_Absensi instance) => <String, dynamic>{
  'id': instance.id,
  'nama': instance.nama,
  'image_url': instance.imageUrl,
  'schedule_id': instance.scheduleId,
  'status': instance.status,
  'created_at': instance.createdAt?.toIso8601String(),
};

_ScheduleModel _$ScheduleModelFromJson(Map<String, dynamic> json) =>
    _ScheduleModel(
      id: json['id'] as String,
      title: json['title'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ScheduleModelToJson(_ScheduleModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'start_time': instance.startTime.toIso8601String(),
      'end_time': instance.endTime.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
    };

_Announcement _$AnnouncementFromJson(Map<String, dynamic> json) =>
    _Announcement(
      id: json['id'] as String,
      message: json['message'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$AnnouncementToJson(_Announcement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'message': instance.message,
      'is_active': instance.isActive,
      'created_at': instance.createdAt?.toIso8601String(),
    };

_Mvp _$MvpFromJson(Map<String, dynamic> json) => _Mvp(
  id: json['id'] as String,
  rank: (json['rank'] as num).toInt(),
  nama: json['nama'] as String,
  pts: (json['pts'] as num?)?.toInt() ?? 0,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$MvpToJson(_Mvp instance) => <String, dynamic>{
  'id': instance.id,
  'rank': instance.rank,
  'nama': instance.nama,
  'pts': instance.pts,
  'created_at': instance.createdAt?.toIso8601String(),
};
