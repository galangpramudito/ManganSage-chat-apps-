import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationPreferences {
  const NotificationPreferences({
    this.matchReminderEnabled = true,
    this.closingReminderEnabled = true,
    this.announcementsEnabled = true,
  });

  final bool matchReminderEnabled;
  final bool closingReminderEnabled;
  final bool announcementsEnabled;

  NotificationPreferences copyWith({
    bool? matchReminderEnabled,
    bool? closingReminderEnabled,
    bool? announcementsEnabled,
  }) {
    return NotificationPreferences(
      matchReminderEnabled: matchReminderEnabled ?? this.matchReminderEnabled,
      closingReminderEnabled:
          closingReminderEnabled ?? this.closingReminderEnabled,
      announcementsEnabled: announcementsEnabled ?? this.announcementsEnabled,
    );
  }
}

class NotificationPreferencesNotifier
    extends Notifier<NotificationPreferences> {
  @override
  NotificationPreferences build() {
    return const NotificationPreferences();
  }

  void toggleMatchReminder(bool val) {
    state = state.copyWith(matchReminderEnabled: val);
  }

  void toggleClosingReminder(bool val) {
    state = state.copyWith(closingReminderEnabled: val);
  }

  void toggleAnnouncements(bool val) {
    state = state.copyWith(announcementsEnabled: val);
  }
}

final notificationPreferencesProvider =
    NotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>(
  NotificationPreferencesNotifier.new,
);
