// https://github.com/agilord/cron/blob/master/lib/cron.dart Licensed under BSD 3-Clause License.

// Copyright (c) 2016, Agilord.
// All rights reserved.

// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of the <organization> nor the
//       names of its contributors may be used to endorse or promote products
//       derived from this software without specific prior written permission.

// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import 'package:meta/meta.dart';

/// Represents a cron schedule.
class Cron {
  /// The seconds of this cron schedule.
  final List<int>? seconds;

  /// The minutes of this cron schedule.
  final List<int>? minutes;

  /// The hours of this cron schedule.
  final List<int>? hours;

  /// The days of this cron schedule.
  final List<int>? days;

  /// The months of this cron schedule.
  final List<int>? months;

  /// The weekdays of this cron schedule.
  final List<int>? weekdays;

  Cron._(
    this.seconds,
    this.minutes,
    this.hours,
    this.days,
    this.months,
    this.weekdays,
  );

  /// Parses the [cronExpression].
  factory Cron.parse(String cronExpression) {
    List<String?> fields = cronExpression
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    if (fields.length < 5 || fields.length > 6) {
      throw CronFormatException('Invalid cron expression: $cronExpression');
    }

    fields = [
      if (fields.length == 5) null,
      ...fields,
    ];

    final seconds = fields[0];
    final minutes = fields[1];
    final hours = fields[2];
    final days = fields[3];
    final months = fields[4];
    final weekdays = fields[5];

    final parsedSeconds = parseField(
      seconds,
    )?.where((x) => x >= 0 && x <= 59).toList();
    final parsedMinutes = parseField(
      minutes,
    )?.where((x) => x >= 0 && x <= 59).toList();
    final parsedHours = parseField(
      hours,
    )?.where((x) => x >= 0 && x <= 23).toList();
    final parsedDays = parseField(
      days,
    )?.where((x) => x >= 1 && x <= 31).toList();
    final parsedMonths = parseField(
      months,
    )?.where((x) => x >= 1 && x <= 12).toList();
    final parsedWeekdays = parseField(weekdays)
        ?.where((x) => x >= 0 && x <= 7)
        .map((x) => x == 0 ? 7 : x)
        .toSet()
        .toList();

    return Cron._(
      parsedSeconds,
      parsedMinutes,
      parsedHours,
      parsedDays,
      parsedMonths,
      parsedWeekdays,
    );
  }

  bool get _hasSeconds =>
      seconds != null &&
      seconds!.isNotEmpty &&
      (seconds!.length != 1 || !seconds!.contains(0));

  /// Returns the next run time.
  DateTime nextTime() {
    var currentDate = DateTime.now().toUtc();

    currentDate = _hasSeconds
        ? currentDate.add(const Duration(seconds: 1))
        : currentDate.add(const Duration(minutes: 1));

    while (true) {
      if (months?.contains(currentDate.month) == false) {
        currentDate = DateTime(
          currentDate.year,
          currentDate.month + 1,
          1,
        );
        continue;
      }
      if (weekdays?.contains(currentDate.weekday) == false) {
        currentDate = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day + 1,
        );
        continue;
      }
      if (days?.contains(currentDate.day) == false) {
        currentDate = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day + 1,
        );
        continue;
      }
      if (hours?.contains(currentDate.hour) == false) {
        currentDate = currentDate.add(const Duration(hours: 1));
        currentDate = currentDate.subtract(
          Duration(minutes: currentDate.minute),
        );
        continue;
      }
      if (minutes?.contains(currentDate.minute) == false) {
        currentDate = currentDate.add(const Duration(minutes: 1));
        continue;
      }
      if (_hasSeconds && seconds?.contains(currentDate.second) == false) {
        currentDate = currentDate.add(const Duration(seconds: 1));
        continue;
      }
      return currentDate;
    }
  }
}

@visibleForTesting
/// Parses a cron field and returns a list of allowed values.
List<int>? parseField(dynamic constraint) {
  if (constraint == null) return null;
  if (constraint is int) return [constraint];
  if (constraint is List<int>) return constraint;
  if (constraint is String) {
    if (constraint == '*') return List.generate(60, (i) => i);
    if (constraint == '') return null;
    final parts = constraint.split(',');
    if (parts.length > 1) {
      final items = parts
          .map(parseField)
          .expand((list) => list!)
          .toSet()
          .toList();
      items.sort();
      return items;
    }

    final singleValue = int.tryParse(constraint);
    if (singleValue != null) return [singleValue];

    var intervalPart = '';
    if (constraint.contains('/')) {
      final parts = constraint.split('/');
      if (parts.length > 2) {
        throw CronFormatException(
          'Invalid cron expression. More than one `/` for intervals.',
        );
      }
      // ignore: parameter_assignments
      constraint = parts[0].trim();
      intervalPart = parts[1].trim();
    }

    final interval = intervalPart.isEmpty ? 1 : int.tryParse(intervalPart);
    if (interval == null) {
      throw CronFormatException(
        'Invalid cron expression. Invalid interval value: $intervalPart',
      );
    }
    if (interval < 1) {
      throw CronFormatException(
        'Invalid cron expression. Invalid interval value: $interval',
      );
    }

    if (constraint == '*') {
      return List.generate(120 ~/ interval, (i) => i * interval);
    } else if (constraint.contains('-')) {
      final ranges = constraint.split('-');
      if (ranges.length == 2) {
        final lower = int.tryParse(ranges.first) ?? -1;
        final higher = int.tryParse(ranges.last) ?? -1;
        if (lower <= higher) {
          return List.generate(
            (higher - lower + 1) ~/ interval,
            (i) => i * interval + lower,
          );
        }
      }
    }
  }

  throw CronFormatException(
    'Invalid cron expression. Unable to parse: $constraint',
  );
}

/// Exception thrown when a cron data does not have an expected
/// format and cannot be parsed or processed.
class CronFormatException extends FormatException {
  /// Creates a new `CronFormatException` with an optional error [message].
  CronFormatException([super.message]);
}
