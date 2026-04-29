import 'package:serverpod_cli/src/commands/tui/app.dart';
import 'package:serverpod_cli/src/commands/tui/state.dart';

/// Provides access to the shared [ServerpodState] and a way to trigger
/// rebuilds on the currently mounted [ServerpodAppState].
///
/// The backend mutates [state] directly, then calls [markDirty] to schedule
/// a rebuild. This avoids proxying every mutation method and survives
/// `NoctermApp` rebuilds that recreate the widget state.
abstract class ServerpodAppStateHolder<S extends ServerpodState> {
  S get state;

  void attach(covariant ServerpodAppState widgetState);

  void detach(covariant ServerpodAppState widgetState);

  /// Trigger a rebuild on the currently mounted state.
  void markDirty();
}
