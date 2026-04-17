import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:serverpod_cli/src/config/experimental_feature.dart';
import 'package:serverpod_cli/src/shared/environment.dart' as env;

Directory _getRootDirectory() {
  var current = Directory.current;
  for (var i = 0; i < 4; i++) {
    final candidate = Directory(current.path);
    final templatesDir = Directory(
      p.join(candidate.path, 'templates', 'serverpod_templates'),
    );
    if (templatesDir.existsSync()) {
      return candidate;
    }
    current = current.parent;
  }
  throw StateError('Could not locate repository root with templates.');
}

void setupForPerformCreateTest() {
  final rootDir = _getRootDirectory();
  env.serverpodHome = rootDir.path;
  CommandLineExperimentalFeatures.initialize(ExperimentalFeature.values);
}
