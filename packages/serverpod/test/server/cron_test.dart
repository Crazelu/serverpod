import 'package:serverpod/src/server/future_call_manager/cron.dart';
import 'package:test/test.dart';

void main() {
  test(
    'Given an invalid cron expression, '
    'when parsing, '
    'then a CronFormatException is thrown',
    () {
      expect(
        () => Cron.parse('invalid'),
        throwsA(isA<CronFormatException>()),
      );

      expect(
        () => Cron.parse('* * *'),
        throwsA(isA<CronFormatException>()),
      );
    },
  );

  test(
    'Given a valid 5-field cron expression, '
    'when parsing, '
    'then all fields are parsed correctly',
    () {
      final schedule = Cron.parse('1 13 */2 3-6 *');
      expect(schedule.seconds, isNull);
      expect(schedule.minutes, [1]);
      expect(schedule.hours, [13]);
      expect(schedule.days, [
        2,
        4,
        6,
        8,
        10,
        12,
        14,
        16,
        18,
        20,
        22,
        24,
        26,
        28,
        30,
      ]);
      expect(schedule.months, [3, 4, 5, 6]);
      expect(schedule.weekdays, [7, 1, 2, 3, 4, 5, 6]);
    },
  );

  test(
    'Given a valid 5-field cron expression, '
    'when parsing, '
    'then all fields are parsed correctly',
    () {
      final schedule = Cron.parse('0,1 0 * * * ');
      expect(schedule.seconds, isNull);
      expect(schedule.minutes, [0, 1]);
      expect(schedule.hours, [0]);
      expect(schedule.days, List.generate(31, (i) => i + 1));
      expect(schedule.months, List.generate(12, (i) => i + 1));
      expect(schedule.weekdays, [7, 1, 2, 3, 4, 5, 6]);
    },
  );

  test(
    'Given a valid 6-field cron expression, '
    'when parsing, '
    'then all fields are parsed correctly',
    () {
      final schedule = Cron.parse('1,30-31 1 13 */2 3-6 2,4');
      expect(schedule.seconds, [1, 30, 31]);
      expect(schedule.minutes, [1]);
      expect(schedule.hours, [13]);
      expect(schedule.days, [
        2,
        4,
        6,
        8,
        10,
        12,
        14,
        16,
        18,
        20,
        22,
        24,
        26,
        28,
        30,
      ]);
      expect(schedule.months, [3, 4, 5, 6]);
      expect(schedule.weekdays, [2, 4]);
    },
  );
}
