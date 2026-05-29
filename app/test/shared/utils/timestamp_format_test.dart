import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mangansage/shared/utils/timestamp_format.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  group('TimestampFormat.inbox', () {
    test('returns HH.mm for today', () {
      final now = DateTime(2026, 5, 28, 14, 30);
      final time = DateTime(2026, 5, 28, 9, 5);
      expect(TimestampFormat.inbox(time, now: now), '09.05');
    });

    test('returns "Kemarin" for yesterday', () {
      final now = DateTime(2026, 5, 28, 14, 30);
      final time = DateTime(2026, 5, 27, 22, 0);
      expect(TimestampFormat.inbox(time, now: now), 'Kemarin');
    });

    test('returns short day name within last week', () {
      final now = DateTime(2026, 5, 28, 14, 30); // Thursday
      final time = DateTime(2026, 5, 25, 10, 0); // Monday
      expect(TimestampFormat.inbox(time, now: now), 'Sen');
    });

    test('returns dd MMM for older same year', () {
      final now = DateTime(2026, 5, 28, 14, 30);
      final time = DateTime(2026, 1, 10, 10, 0);
      expect(TimestampFormat.inbox(time, now: now), '10 Jan');
    });

    test('returns dd MMM yyyy for previous year', () {
      final now = DateTime(2026, 5, 28, 14, 30);
      final time = DateTime(2025, 12, 25, 10, 0);
      expect(TimestampFormat.inbox(time, now: now), '25 Des 2025');
    });
  });

  group('TimestampFormat.bubble', () {
    test('returns HH.mm', () {
      final time = DateTime(2026, 5, 28, 14, 7);
      expect(TimestampFormat.bubble(time), '14.07');
    });
  });
}
