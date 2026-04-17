import 'dart:io';

import 'package:serverpod_cli/src/config/experimental_feature.dart';
import 'package:serverpod_cli/src/shared/environment.dart' as env;

void setupForPerformCreateTest() {
  env.serverpodHome = Directory('../..').absolute.path;
  CommandLineExperimentalFeatures.initialize(ExperimentalFeature.values);
}

void teardownForPerformCreateTest() {
  env.serverpodHome = '';
}
