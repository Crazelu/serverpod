import 'dart:io';

import 'package:nocterm/nocterm.dart';
import 'package:serverpod_cli/src/commands/tui/terminal_backend.dart';

bool _terminalStateCaptured = false;
bool _terminalStateRestored = false;

late bool _originalEchoMode;
late bool _originalLineMode;

void _captureTerminalState() {
  _originalEchoMode = stdin.echoMode;
  _originalLineMode = stdin.lineMode;
  _terminalStateCaptured = true;
  _terminalStateRestored = false;
}

/// Restores stdin terminal modes captured by [runServerpodApp].
///
/// Safe to call multiple times.
void restoreServerpodTerminal() {
  if (!_terminalStateCaptured || _terminalStateRestored) return;
  stdin.echoMode = _originalEchoMode;
  stdin.lineMode = _originalLineMode;
  _terminalStateRestored = true;
}

/// Run a TUI app with terminal settings restoration.
///
/// When [onShutdownSignal] is null (the default), SIGINT/SIGTERM trigger an
/// immediate `shutdownApp()` and the app exits without running any user
/// cleanup.
///
/// When [onShutdownSignal] is provided, signals invoke that callback instead.
/// The caller is then responsible for running cleanup and eventually calling
/// `shutdownApp(...)` to tear down the nocterm renderer.
Future<void> runServerpodApp(
  Component app, {
  bool enableHotReload = true,
  ServerpodTerminalBackend? backend,
  void Function()? onShutdownSignal,
}) async {
  _captureTerminalState();

  // final effectiveBackend = backend ?? ServerpodTerminalBackend();
  // effectiveBackend.onExit(() => restoreServerpodTerminal());

  void onShutDownSignalDefault(ProcessSignal _) {
    restoreServerpodTerminal();
    shutdownApp();
  }

  void onShutDownSignalDelegated(ProcessSignal _) {
    restoreServerpodTerminal();
    onShutdownSignal!.call();
  }

  final handler = onShutdownSignal == null
      ? onShutDownSignalDefault
      : onShutDownSignalDelegated;

  ProcessSignal.sigint.watch().listen(handler);
  if (!Platform.isWindows) {
    ProcessSignal.sigterm.watch().listen(handler);
  }

  try {
    await runApp(
      app,
      enableHotReload: enableHotReload,
      backend: backend,
    );
  } finally {
    restoreServerpodTerminal();
  }
}
