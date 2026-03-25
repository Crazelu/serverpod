# Design: Recurring Future Calls

## Summary

Serverpod currently supports scheduling future calls using `callWithDelay` or `callAtTime`. These calls are stored in the database and executed once when their scheduled time arrives.

Recurring jobs are currently implemented by manually scheduling the next future call from inside the executing future call itself. This approach works but is unintuitive and requires developers to manually manage scheduling logic.

This design introduces native recurring future calls using cron expressions while preserving full compatibility with the existing future call system. Developers will be able to schedule recurring tasks using cron expressions or a utility API for common cases that converts to cron expressions internally.

Recurring calls will reuse the existing execution pipeline by computing the next execution time after each run and updating the existing future call entry.

## Proposed Solution

Extend the future call system to support two types of entries:

- oneOff – existing behavior
- recurring – scheduled using cron expressions

Recurring call entries will store a cron expression. After execution, the cron expression will be parsed to compute the next execution time and the future call entry will be updated accordingly. This ensures that the existing query used to fetch due future calls remains unchanged.

### Database Schema

The `serverpod_future_call` table schema will be extended to include two new fields.

```yaml
class: FutureCallEntry
table: serverpod_future_call
fields:
  ### Type of future call
  type: FutureCallType

  ### Cron expression for recurring calls
  cron: String?
```

```yaml
### Represents different future call types.
enum: FutureCallType
serialized: byIndex
default: oneOff
values:
  - oneOff
  - recurring
```

### Scheduling API

A new `recurring` method will be added to `FutureCallDispatch`.

```dart
/// Calls a [FutureCall] at a recurring interval defined by [cronExpression],
/// optionally passing a [String] identifier.
T recurring(String cronExpression, {String? identifier}) {}
```

Developers can then schedule recurring calls using the generated type-safe API.

```dart
await pod.futureCalls.recurring("0 * * * *").example.runTask();
```

To simplify common use cases, `FutureCallSchedule` utility methods will be introduced such as:

```dart
FutureCallSchedule.everyMinute(15); // */15 * * * *
FutureCallSchedule.everyHour(12); // * 12 * * *
FutureCallSchedule.daily(); // 0 0 * * *
FutureCallSchedule.annually(); // * * 1 1 *
```

These utility methods will return valid cron expressions that interoperate with the `recurring` method.

```dart
await pod.futureCalls.recurring(FutureCallSchedule.daily()).example.runTask();
```

### Execution Flow

Existing logic for scanning and scheduling future calls will remain unchanged and only add a special case handling for running recurring future calls.

After running a recurring future call, the entry's `time` must be updated with the next run time derived from parsing the cron expression. The next run time is computed relative to the current time and not the last scheduled time for the `FutureCallEntry`. This is to ensure the next time is always in the future.

Unlike one-off calls, recurring future calls will not be deleted after the execution is completed.

A cron parser will be implemented to parse cron expressions and compute the next execution time. The parser will support 5-field and 6-field cron expressions.

In the future, the parser may be updated to support special named values such as `L` (for last day), `JAN`, `MON`, etc.

### Potential Issues

#### 1. Long running jobs

If a recurring job takes longer than the interval between runs, the next run time may already be in the past.
When computing the next run time, always compute the next valid future occurrence rather than using the previous scheduled time.

#### 2. Invalid cron expressions

Cron expressions will be validated when scheduling the future call to provide feedback to developers when invalid expressions are used.
Recurring future calls with invalid cron expressions will not be stored in the database.

## Backwards Compatibility

This implementation maintains full backwards compatibility.
Existing future calls continue to work unchanged because:

- the scan query remains unchanged
- existing entries default to type = oneOff
- new fields are optional

## Open Questions

1. Do we depend on the existing `cron` package? It has not been updated in 10 months and seems to have slow pace on maintenance. The alternative is to implement a cron parser internally at the cost of maintenance.
