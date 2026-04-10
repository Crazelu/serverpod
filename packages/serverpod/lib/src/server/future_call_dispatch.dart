import 'package:serverpod/serverpod.dart';

/// Provides type-safe access to future calls on the server.
/// Typically, this class is overriden by a FutureCalls class that is generated.
abstract class FutureCallDispatch<T> {
  /// Initializes the future calls.
  void initialize(FutureCallManager futureCallManager, String serverId);

  /// Calls a [FutureCall] at the specified time, optionally passing a [String] identifier.
  T callAtTime(DateTime time, {String? identifier});

  /// Calls a [FutureCall] after the specified [delay], optionally passing a [String] identifier.
  T callWithDelay(Duration delay, {String? identifier});

  /// Calls a [FutureCall] at a recurring interval, optionally passing a [String] identifier.
  RecurringFutureCallDispatch<T> callRecurring({String? identifier});

  /// Cancels a [FutureCall] with the specified identifier. If no future call
  /// with the specified identifier is found, this call will have no effect.
  Future<void> cancel(String identifier);
}

/// Provides type-safe access to recurring future calls on the server.
/// Typically, this class is overriden by a generated class.
abstract class RecurringFutureCallDispatch<T> {
  /// Calls a [FutureCall] at a recurring interval defined by [cronExpression].
  T cron(String cronExpression);

  /// Calls a [FutureCall] at a recurring interval defined by [interval],
  /// optionally passing a [start] time.
  /// If [start] is in the past, the [FutureCall] is first called immediately
  /// and then subsequently called recurrently every [interval].
  T every(Duration interval, {DateTime? start});
}
