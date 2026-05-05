import 'dart:async';

import 'package:nocterm/nocterm.dart';

typedef ExitCall = Future<void> Function();

/// A terminal backend for nocterm that allows executing
/// callbacks before exiting the Dart process.
/// Callbacks are and added using [onExit].
class ServerpodTerminalBackend extends StdioBackend {
  ServerpodTerminalBackend();

  final List<ExitCall> _onExitCalls = [];

  void onExit(ExitCall callback) {
    _onExitCalls.add(callback);
  }

  @override
  void requestExit([int exitCode = 0]) {
    Future.wait<void>([for (final future in _onExitCalls) future.call()])
        .then((_) {
          super.requestExit(exitCode);
        })
        .catchError((_) {
          super.requestExit(exitCode);
        });
  }
}
