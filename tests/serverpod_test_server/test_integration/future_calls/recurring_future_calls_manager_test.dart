import 'dart:async';

import 'package:serverpod/protocol.dart' show FutureCallEntry;
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_test_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import '../test_tools/serverpod_test_tools.dart';
import '../utils/future_call_manager_builder.dart';

class CompleterTestCall extends FutureCall<SimpleData> {
  final Completer<SimpleData?> completer = Completer<SimpleData?>();

  @override
  Future<void> invoke(Session session, SimpleData? object) async {
    completer.complete(object);
  }
}

void main() async {
  withServerpod(
    'Given FutureCallManager with registered recurring cron FutureCall that is due',
    (sessionBuilder, _) {
      late FutureCallManager futureCallManager;
      late CompleterTestCall testCall;
      late Session session;
      var testCallName = 'test-recurring-cron-execution-call';
      var identifier = 'recurring-cron-execution-id';
      var cronExpression = '*/5 * * * *';

      setUp(() async {
        session = sessionBuilder.build();

        futureCallManager =
            FutureCallManagerBuilder.fromTestSessionBuilder(sessionBuilder)
                .withConfig(
                  FutureCallConfig(scanInterval: Duration(milliseconds: 10)),
                )
                .build();

        testCall = CompleterTestCall();

        futureCallManager.registerFutureCall(testCall, testCallName);

        await futureCallManager.scheduleFutureCall(
          testCallName,
          SimpleData(num: 4),
          DateTime.now().subtract(const Duration(seconds: 1)),
          '1',
          identifier,
          scheduling: CronFutureCallScheduling(cron: cronExpression),
        );
      });

      group('when running scheduled FutureCalls', () {
        late List<FutureCallEntry> oldFutureCallEntries;
        late List<FutureCallEntry> futureCallEntries;

        setUp(() async {
          oldFutureCallEntries = await FutureCallEntry.db.find(
            session,
            where: (entry) => entry.name.equals(testCallName),
          );

          await futureCallManager.runScheduledFutureCalls();

          futureCallEntries = await FutureCallEntry.db.find(
            session,
            where: (entry) => entry.name.equals(testCallName),
          );
        });

        tearDown(() {
          if (!testCall.completer.isCompleted) {
            testCall.completer.complete();
          }
        });

        test('then the FutureCall is executed', () async {
          await expectLater(testCall.completer.future, completes);
        });

        test('then a new FutureCallEntry is scheduled for next run', () {
          expect(futureCallEntries, hasLength(1));
        });

        test('then the new entry has a different id', () {
          expect(
            futureCallEntries.first.id,
            isNot(oldFutureCallEntries.first.id),
          );
        });

        test('then the new entry has the same name', () {
          expect(futureCallEntries.first.name, equals(testCallName));
        });

        test('then the new entry has the same serializedObject', () {
          expect(
            futureCallEntries.first.serializedObject,
            equals('{"num":4}'),
          );
        });

        test('then the new entry has the same serverId', () {
          expect(futureCallEntries.first.serverId, equals('1'));
        });

        test('then the new entry has the same identifier', () {
          expect(futureCallEntries.first.identifier, equals(identifier));
        });

        test('then the new entry has the same cron scheduling', () {
          var scheduling =
              futureCallEntries.first.scheduling as CronFutureCallScheduling;
          expect(scheduling.cron, equals(cronExpression));
        });

        test('then the new entry has time in the future', () {
          expect(
            futureCallEntries.first.time.isAfter(DateTime.now()),
            isTrue,
          );
        });
      });

      group(
        'when start is called',
        () {
          setUp(() async {
            await futureCallManager.start();
          });

          tearDown(() async {
            if (!testCall.completer.isCompleted) {
              testCall.completer.complete();
            }
            await futureCallManager.stop();
          });

          test('then the FutureCall is executed', () async {
            await expectLater(testCall.completer.future, completes);
          });

          test(
            'then a new FutureCallEntry is scheduled for next run',
            () async {
              await testCall.completer.future;
              await Future.delayed(Duration(milliseconds: 100));

              final futureCallEntries = await FutureCallEntry.db.find(
                session,
                where: (entry) => entry.name.equals(testCallName),
              );

              expect(futureCallEntries, hasLength(1));
              expect(
                (futureCallEntries.first.scheduling as CronFutureCallScheduling)
                    .cron,
                equals(cronExpression),
              );
              expect(
                futureCallEntries.first.time.isAfter(DateTime.now()),
                isTrue,
              );
            },
          );
        },
      );
    },
  );

  withServerpod(
    'Given FutureCallManager with registered recurring interval FutureCall that is due',
    (sessionBuilder, _) {
      late FutureCallManager futureCallManager;
      late CompleterTestCall testCall;
      late Session session;
      var testCallName = 'test-recurring-interval-execution-call';
      var identifier = 'recurring-interval-execution-id';
      var interval = Duration(minutes: 5);

      setUp(() async {
        session = sessionBuilder.build();

        futureCallManager =
            FutureCallManagerBuilder.fromTestSessionBuilder(sessionBuilder)
                .withConfig(
                  FutureCallConfig(scanInterval: Duration(milliseconds: 10)),
                )
                .build();

        testCall = CompleterTestCall();

        futureCallManager.registerFutureCall(testCall, testCallName);

        await futureCallManager.scheduleFutureCall(
          testCallName,
          SimpleData(num: 4),
          DateTime.now().subtract(const Duration(seconds: 1)),
          '1',
          identifier,
          scheduling: IntervalFutureCallScheduling(interval: interval),
        );
      });

      group('when running scheduled FutureCalls', () {
        late List<FutureCallEntry> oldFutureCallEntries;
        late List<FutureCallEntry> futureCallEntries;

        setUp(() async {
          oldFutureCallEntries = await FutureCallEntry.db.find(
            session,
            where: (entry) => entry.name.equals(testCallName),
          );

          await futureCallManager.runScheduledFutureCalls();

          futureCallEntries = await FutureCallEntry.db.find(
            session,
            where: (entry) => entry.name.equals(testCallName),
          );
        });

        tearDown(() {
          if (!testCall.completer.isCompleted) {
            testCall.completer.complete();
          }
        });

        test('then the FutureCall is executed', () async {
          await expectLater(testCall.completer.future, completes);
        });

        test('then the new entry has a different id', () {
          expect(
            futureCallEntries.first.id,
            isNot(oldFutureCallEntries.first.id),
          );
        });

        test('then a new FutureCallEntry is scheduled for next run', () {
          expect(futureCallEntries, hasLength(1));
        });

        test('then the new entry has the same name', () {
          expect(futureCallEntries.first.name, equals(testCallName));
        });

        test('then the new entry has the same serializedObject', () {
          expect(
            futureCallEntries.first.serializedObject,
            equals('{"num":4}'),
          );
        });

        test('then the new entry has the same serverId', () {
          expect(futureCallEntries.first.serverId, equals('1'));
        });

        test('then the new entry has the same identifier', () {
          expect(futureCallEntries.first.identifier, equals(identifier));
        });

        test('then the new entry has the same interval scheduling', () {
          var scheduling =
              futureCallEntries.first.scheduling
                  as IntervalFutureCallScheduling;
          expect(scheduling.interval, equals(interval));
        });

        test('then the new entry has time in the future', () {
          expect(
            futureCallEntries.first.time.isAfter(DateTime.now()),
            isTrue,
          );
        });

        test('then the new entry scheduling has start set to null', () {
          var scheduling =
              futureCallEntries.first.scheduling
                  as IntervalFutureCallScheduling;
          expect(scheduling.start, isNull);
        });
      });

      group(
        'when start is called',
        () {
          setUp(() async {
            await futureCallManager.start();
          });

          tearDown(() async {
            if (!testCall.completer.isCompleted) {
              testCall.completer.complete();
            }
            await futureCallManager.stop();
          });

          test('then the FutureCall is executed', () async {
            await expectLater(testCall.completer.future, completes);
          });

          test(
            'then a new FutureCallEntry is scheduled for next run',
            () async {
              await testCall.completer.future;
              await Future.delayed(Duration(milliseconds: 100));

              final futureCallEntries = await FutureCallEntry.db.find(
                session,
                where: (entry) => entry.name.equals(testCallName),
              );

              expect(futureCallEntries, hasLength(1));
              expect(
                (futureCallEntries.first.scheduling
                        as IntervalFutureCallScheduling)
                    .interval
                    .inMinutes,
                equals(5),
              );
              expect(
                futureCallEntries.first.time.isAfter(DateTime.now()),
                isTrue,
              );
            },
          );
        },
      );
    },
  );

  withServerpod(
    'Given FutureCallManager with non-recurring FutureCall',
    (sessionBuilder, _) {
      late FutureCallManager futureCallManager;
      late CompleterTestCall testCall;
      late Session session;
      var testCallName = 'test-non-recurring-call';

      setUp(() async {
        session = sessionBuilder.build();

        futureCallManager =
            FutureCallManagerBuilder.fromTestSessionBuilder(sessionBuilder)
                .withConfig(
                  FutureCallConfig(scanInterval: Duration(milliseconds: 10)),
                )
                .build();

        testCall = CompleterTestCall();

        futureCallManager.registerFutureCall(testCall, testCallName);

        await futureCallManager.scheduleFutureCall(
          testCallName,
          SimpleData(num: 4),
          DateTime.now().subtract(const Duration(seconds: 1)),
          '1',
          '',
        );
      });

      group('when running scheduled FutureCalls', () {
        late List<FutureCallEntry> futureCallEntries;

        setUp(() async {
          await futureCallManager.runScheduledFutureCalls();

          futureCallEntries = await FutureCallEntry.db.find(
            session,
            where: (entry) => entry.name.equals(testCallName),
          );
        });

        tearDown(() {
          if (!testCall.completer.isCompleted) {
            testCall.completer.complete();
          }
        });

        test('then the FutureCall is executed', () async {
          await expectLater(testCall.completer.future, completes);
        });

        test('then no new FutureCallEntry is scheduled', () {
          expect(futureCallEntries, isEmpty);
        });
      });

      group(
        'when start is called',
        () {
          setUp(() async {
            await futureCallManager.start();
          });

          tearDown(() async {
            if (!testCall.completer.isCompleted) {
              testCall.completer.complete();
            }
            await futureCallManager.stop();
          });

          test('then the FutureCall is executed', () async {
            await expectLater(testCall.completer.future, completes);
          });

          test('then no new FutureCallEntry is scheduled', () async {
            await testCall.completer.future;
            await Future.delayed(Duration(milliseconds: 100));

            final futureCallEntries = await FutureCallEntry.db.find(
              session,
              where: (entry) => entry.name.equals(testCallName),
            );

            expect(futureCallEntries, isEmpty);
          });
        },
      );
    },
  );
}
