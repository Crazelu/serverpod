import 'dart:async';

import 'package:nocterm/nocterm.dart';

/// A terminal backend for nocterm that allows executing
/// callbacks before exiting the Dart process.
/// Callbacks are and added using [onExit] and [preExit].
class ServerpodTerminalBackend extends StdioBackend {
  ServerpodTerminalBackend({this.preExit});

  final Future<void> Function()? preExit;

  final List<VoidCallback> _onExitCalls = [];

  void onExit(VoidCallback callback) {
    _onExitCalls.add(callback);
  }

  @override
  void requestExit([int exitCode = 0]) {
    for (final exitCall in _onExitCalls) {
      exitCall();
    }

    preExit
        ?.call()
        .then((_) => super.requestExit(exitCode))
        .catchError((_) => super.requestExit(exitCode));

    if (preExit == null) {
      super.requestExit(exitCode);
    }
  }
}
