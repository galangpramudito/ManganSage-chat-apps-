import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../shared/models/supabase_models.dart';

/// Menjadwalkan alarm/notifikasi lokal di tiap device saat deadline jadwal tiba.
/// Independen dari FCM — pakai flutter_local_notifications + zonedSchedule.
class AlarmService {
  AlarmService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channel = AndroidNotificationChannel(
    'schedule_alarms',
    'Alarm Jadwal',
    description: 'Pengingat deadline jadwal bareng',
    importance: Importance.max,
  );

  Future<void> _ensureInit() async {
    if (_ready) return;
    tz.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (_) {
      // Fallback ke UTC kalau gagal — alarm tetap jalan, hanya offset risiko.
    }
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
    // Izin (Android 13+ / iOS).
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
    _ready = true;
  }

  Future<void> scheduleCustom({
    required String scheduleId,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final when = scheduledTime.toLocal();
    if (when.isBefore(DateTime.now())) return;

    await _ensureInit();
    try {
      await _plugin.zonedSchedule(
        id: scheduleId.hashCode,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(when, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'schedule_alarms',
            'Alarm Jadwal',
            channelDescription: 'Pengingat deadline jadwal bareng',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('[Alarm] schedule failed: $e');
    }
  }

  /// Tampilkan notifikasi langsung saat ada jadwal baru atau pengumuman
  Future<void> showInstantNotification({
    required String title,
    required String body,
    int? id,
  }) async {
    await _ensureInit();
    try {
      await _plugin.show(
        id: id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'schedule_alarms',
            'Alarm Jadwal',
            channelDescription: 'Pengingat deadline jadwal bareng',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('[Alarm] instant notification failed: $e');
    }
  }

  /// Jadwalkan pengingat 15 menit sebelum match dimulai
  Future<void> scheduleFor(ScheduleModel s) async {
    await scheduleCustom(
      scheduleId: s.id,
      title: '⏰ MATCH REMINDER: ${s.title}',
      body: 'Match MNG akan dimulai dalam 15 menit! Segera kumpul in-game.',
      scheduledTime: s.startTime.subtract(const Duration(minutes: 15)),
    );
  }

  /// Jadwalkan pengingat 15 menit SEBELUM ABSEN DITUTUP (endTime - 15 menit)
  Future<void> scheduleClosingReminder(ScheduleModel s) async {
    final closingAlertTime = s.endTime.subtract(const Duration(minutes: 15));
    await scheduleCustom(
      scheduleId: '${s.id}_closing',
      title: '⚠️ ABSEN HENDAK DITUTUP!',
      body: 'Absen untuk match "${s.title}" akan ditutup dalam 15 menit! Segera kirim presensi.',
      scheduledTime: closingAlertTime,
    );
  }

  Future<void> cancel(String scheduleId) async {
    await _plugin.cancel(id: scheduleId.hashCode);
    await _plugin.cancel(id: '${scheduleId}_closing'.hashCode);
  }
}

final alarmServiceProvider = Provider<AlarmService>((ref) => AlarmService());
