import 'dart:async';

import 'package:serverpod/protocol.dart' show FutureCallEntry;
import 'package:serverpod/serverpod.dart';
import 'package:serverpod/src/generated/future_call_claim_entry.dart';
import 'package:serverpod_test_server/src/generated/simple_data.dart';
import 'package:test/test.dart';
import '../test_tools/serverpod_test_tools.dart';
import '../utils/future_call_manager_builder.dart';

class _CounterFutureCall extends FutureCall<SimpleData> {
  int counter = 0;

  @override
  Future<void> invoke(Session session, SimpleData? object) async {
    counter++;
  }
}

class _CompleterFutureCall extends FutureCall<SimpleData> {
  final Completer<SimpleData?> completer = Completer<SimpleData?>();
  int counter = 0;

  @override
  Future<void> invoke(Session session, SimpleData? object) async {
    await completer.future;
    counter++;
  }
}

void main() {
  withServerpod(
    'Given FutureCallManager with scheduled FutureCall that is due',
    (sessionBuilder, _) {
      late FutureCallManager futureCallManager;
      late Session session;
      late _CompleterFutureCall testCall;
      final testCallName = 'claim-insertion-call';

      setUp(() async {
        session = sessionBuilder.build();

        futureCallManager = FutureCallManagerBuilder.fromTestSessionBuilder(
          sessionBuilder,
        ).build();

        testCall = _CompleterFutureCall();
        futureCallManager.registerFutureCall(testCall, testCallName);

        await futureCallManager.scheduleFutureCall(
          testCallName,
          SimpleData(num: 4),
          DateTime.now().subtract(const Duration(seconds: 1)),
          '1',
          '',
        );
      });

      tearDown(() async {
        await FutureCallEntry.db.deleteWhere(
          session,
          where: (entry) => entry.name.equals(testCallName),
        );

        await session.close();
      });

      group('when start is called', () {
        setUp(() async {
          await futureCallManager.start();
          // Wait for future call execution to be scheduled
          await Future.delayed(const Duration(milliseconds: 500));
        });

        tearDown(() async {
          await futureCallManager.stop();
        });

        test('then a claim is inserted for the FutureCall', () async {
          final claims = await FutureCallClaimEntry.db.find(session);
          expect(claims, hasLength(1));
          testCall.completer.complete();
        });

        test('then the FutureCall is executed', () async {
          testCall.completer.complete();
          await testCall.completer.future;
          expect(testCall.counter, equals(1));
        });

        test(
          'then the claim is deleted after the FutureCall is executed',
          () async {
            testCall.completer.complete();
            await testCall.completer.future;

            // Wait for cleanup to run
            await Future.delayed(const Duration(milliseconds: 500));
            final claims = await FutureCallClaimEntry.db.find(session);
            expect(claims, isEmpty);
          },
        );
      });
    },
    rollbackDatabase: RollbackDatabase.disabled,
  );

  withServerpod(
    'Given FutureCallManager with scheduled FutureCall that is due '
    'and existing valid claim in the database for the FutureCall',
    (sessionBuilder, _) {
      late FutureCallManager futureCallManager;
      late Session session;
      late _CounterFutureCall testCall;
      final testCallName = 'existing-claimtest-call';

      setUp(() async {
        session = sessionBuilder.build();

        futureCallManager = FutureCallManagerBuilder.fromTestSessionBuilder(
          sessionBuilder,
        ).build();

        testCall = _CounterFutureCall();
        futureCallManager.registerFutureCall(testCall, testCallName);

        // Insert a future call entry that is due
        var entry = FutureCallEntry(
          name: testCallName,
          serializedObject: SimpleData(num: 4).toString(),
          time: DateTime.now().subtract(const Duration(seconds: 1)),
          serverId: '1',
        );

        entry = await FutureCallEntry.db.insertRow(session, entry);

        // Insert an existing claim for this future call
        final claim = FutureCallClaimEntry(
          futureCallId: entry.id,
          lastHeartbeatTime: DateTime.now().toUtc(),
        );
        await FutureCallClaimEntry.db.insert(session, [claim]);
      });

      tearDown(() async {
        await FutureCallEntry.db.deleteWhere(
          session,
          where: (entry) => entry.name.equals(testCallName),
        );
        await session.close();
      });

      group('when running scheduled FutureCalls', () {
        setUp(() async {
          await futureCallManager.runScheduledFutureCalls();
        });

        test('then the FutureCall is not executed', () async {
          expect(testCall.counter, equals(0));
        });

        test('then the claim is not deleted', () async {
          final claims = await FutureCallClaimEntry.db.find(session);
          expect(claims, hasLength(1));
        });
      });
    },
  );

  withServerpod(
    'Given FutureCallManager with scheduled FutureCall that is due '
    'and existing stale claim in the database for the FutureCall',
    (sessionBuilder, _) {
      late FutureCallManager futureCallManager;
      late Session session;
      late _CompleterFutureCall testCall;
      final testCallName = 'stale-claim-test-call';
      late FutureCallClaimEntry staleClaim;

      setUp(() async {
        session = sessionBuilder.build();

        futureCallManager = FutureCallManagerBuilder.fromTestSessionBuilder(
          sessionBuilder,
        ).build();

        testCall = _CompleterFutureCall();
        futureCallManager.registerFutureCall(testCall, testCallName);

        // Insert a future call entry that is due
        var entry = FutureCallEntry(
          name: testCallName,
          serializedObject: SimpleData(num: 4).toString(),
          time: DateTime.now().subtract(const Duration(seconds: 1)),
          serverId: '1',
          identifier: '',
        );

        entry = await FutureCallEntry.db.insertRow(session, entry);

        // Insert a stale claim for this future call
        staleClaim = FutureCallClaimEntry(
          futureCallId: entry.id,
          lastHeartbeatTime: DateTime.now().toUtc().subtract(
            const Duration(minutes: 5),
          ),
        );

        staleClaim = await FutureCallClaimEntry.db.insertRow(
          session,
          staleClaim,
        );
      });

      tearDown(() async {
        await FutureCallEntry.db.deleteWhere(
          session,
          where: (entry) => entry.name.equals(testCallName),
        );
        await session.close();
      });

      group('when running scheduled FutureCalls', () {
        setUp(() async {
          testCall.completer.complete();
          await futureCallManager.runScheduledFutureCalls();
        });

        test('then the FutureCall is executed', () async {
          await testCall.completer.future;
          expect(testCall.counter, equals(1));
        });

        test('then the claim is deleted', () async {
          final claims = await FutureCallClaimEntry.db.find(session);
          expect(claims, isEmpty);
        });
      });

      group('when start is called', () {
        setUp(() async {
          await futureCallManager.start();
        });

        tearDown(() async {
          await futureCallManager.stop();
        });

        test('then the stale claim is replaced', () async {
          // Wait for the call to be scheduled
          await Future.delayed(const Duration(milliseconds: 500));

          final claims = await FutureCallClaimEntry.db.find(session);
          expect(claims, hasLength(1));
          expect(staleClaim, isNot(claims.first));

          testCall.completer.complete();
          await testCall.completer.future;
        });
      });
    },
  );

  withServerpod(
    'Given FutureCallManager with scheduled long running FutureCall that is due',
    (sessionBuilder, _) {
      late FutureCallManager futureCallManager;
      late Session session;
      late _CompleterFutureCall testCall;
      final testCallName = 'long-running-test-call';
      const heartbeatInterval = Duration(milliseconds: 500);

      setUp(() async {
        session = sessionBuilder.build();

        futureCallManager = FutureCallManagerBuilder.fromTestSessionBuilder(
          sessionBuilder,
        ).withHeartbeatInterval(heartbeatInterval).build();

        testCall = _CompleterFutureCall();
        futureCallManager.registerFutureCall(testCall, testCallName);

        await futureCallManager.scheduleFutureCall(
          testCallName,
          SimpleData(num: 4),
          DateTime.now().subtract(const Duration(seconds: 1)),
          '1',
          '',
        );
      });

      tearDown(() async {
        await FutureCallEntry.db.deleteWhere(
          session,
          where: (entry) => entry.name.equals(testCallName),
        );
        await session.close();
      });

      group('when start is called', () {
        setUp(() async {
          await futureCallManager.start();
        });

        tearDown(() async {
          await futureCallManager.stop();
        });

        test('then heartbeat timestamp is updated periodically', () async {
          // Wait for future call execution to be scheduled
          await Future.delayed(const Duration(seconds: 1));

          final initialClaims = await FutureCallClaimEntry.db.find(session);
          expect(initialClaims, hasLength(1));

          await Future.delayed(heartbeatInterval * 2);

          final updatedClaims = await FutureCallClaimEntry.db.find(session);
          expect(updatedClaims, hasLength(1));

          final updatedClaim = updatedClaims.first;
          final initialClaim = initialClaims.first;

          expect(updatedClaim.id, equals(initialClaim.id));
          expect(
            updatedClaim.lastHeartbeatTime.isAfter(
              initialClaim.lastHeartbeatTime,
            ),
            isTrue,
          );

          testCall.completer.complete();
        });
      });
    },
    rollbackDatabase: RollbackDatabase.disabled,
  );
}
