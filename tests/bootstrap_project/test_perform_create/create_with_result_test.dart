import 'dart:io';

import 'package:bootstrap_project/src/util.dart';
import 'package:path/path.dart' as p;
import 'package:serverpod_cli/src/create/create.dart';
import 'package:serverpod_cli/src/create/template_context.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'util.dart';

void main() {
  final rootPath = p.join(Directory.current.path, '..', '..');
  final cliProjectPath = getServerpodCliProjectPath(rootPath: rootPath);

  setUpAll(() async {
    final pubGetProcess = await startProcess('dart', [
      'pub',
      'get',
    ], workingDirectory: cliProjectPath);
    assert(await pubGetProcess.exitCode == 0);
  });

  group(
    'Given a valid context and server template type, '
    'when performCreateWithResult is called with an invalid project name',
    () {
      const projectName = 'invalid-name!';
      late CreateResult result;

      setUpAll(() async {
        setupForPerformCreateTest();
        result = await performCreateWithResult(
          projectName,
          ServerpodTemplateType.server,
          false,
          interactive: false,
          context: TemplateContext(),
        );
      });

      test('then returns success as false', () {
        expect(result.success, false);
      });

      test('then returns empty relativeServerPath', () {
        expect(result.relativeServerPath, isEmpty);
      });
    },
  );

  group(
    'Given a valid context and server template type, '
    'when performCreateWithResult is called with a project name that already exists',
    () {
      late CreateResult result;

      final projectName =
          'test_${const Uuid().v4().replaceAll('-', '_').toLowerCase()}';

      setUpAll(() async {
        setupForPerformCreateTest();
        final context = TemplateContext();

        await performCreate(
          projectName,
          ServerpodTemplateType.server,
          false,
          interactive: false,
          context: context,
        );

        result = await performCreateWithResult(
          projectName,
          ServerpodTemplateType.server,
          false,
          interactive: false,
          context: context,
        );
      });

      tearDownAll(() {
        final dir = Directory(projectName);
        try {
          dir.delete(recursive: true);
        } on FileSystemException {
          // Gone.
        }
      });

      test('then returns success as false', () {
        expect(result.success, false);
      });

      test('then returns empty relativeServerPath', () {
        expect(result.relativeServerPath, isEmpty);
      });
    },
  );

  group(
    'Given a valid context and server template type, '
    'when performCreateWithResult is called with a valid project name',
    () {
      late CreateResult result;

      final projectName =
          'test_${const Uuid().v4().replaceAll('-', '_').toLowerCase()}';

      setUpAll(() async {
        setupForPerformCreateTest();
        result = await performCreateWithResult(
          projectName,
          ServerpodTemplateType.server,
          false,
          interactive: false,
          context: TemplateContext(),
        );
      });

      tearDownAll(() {
        final dir = Directory(projectName);
        try {
          dir.delete(recursive: true);
        } on FileSystemException {
          // Gone.
        }
      });

      test('then returns success as true', () {
        expect(result.success, true);
      });

      test('then returns correct relativeServerPath', () {
        expect(result.relativeServerPath, '${projectName}_server');
      });
    },
  );

  group(
    'Given a name of "." with a server directory in current directory, '
    'when performCreateWithResult is called with non-server template type',
    () {
      late CreateResult result;

      setUpAll(() async {
        setupForPerformCreateTest();

        result = await performCreateWithResult(
          '.',
          ServerpodTemplateType.module,
          false,
          interactive: false,
          context: TemplateContext(),
        );
      });

      test('then returns success as false', () {
        expect(result.success, false);
      });

      test('then returns empty relativeServerPath', () {
        expect(result.relativeServerPath, isEmpty);
      });
    },
  );

  group(
    'Given a module template type, '
    'when performCreateWithResult is called with a valid project name',
    () {
      late CreateResult result;

      final projectName =
          'test_${const Uuid().v4().replaceAll('-', '_').toLowerCase()}';

      setUpAll(() async {
        setupForPerformCreateTest();

        result = await performCreateWithResult(
          projectName,
          ServerpodTemplateType.module,
          false,
          interactive: false,
          context: TemplateContext(),
        );
      });

      tearDownAll(() {
        final dir = Directory(projectName);
        try {
          dir.delete(recursive: true);
        } on FileSystemException {
          // Gone.
        }
      });

      test('then returns success as true', () {
        expect(result.success, true);
      });

      test('then returns correct relativeServerPath', () {
        expect(result.relativeServerPath, '${projectName}_server');
      });
    },
  );

  group(
    'Given a mini template type, '
    'when performCreateWithResult is called with a valid project name',
    () {
      late CreateResult result;

      final projectName =
          'test_${const Uuid().v4().replaceAll('-', '_').toLowerCase()}';

      setUpAll(() async {
        setupForPerformCreateTest();
        result = await performCreateWithResult(
          projectName,
          ServerpodTemplateType.mini,
          false,
          interactive: false,
          context: TemplateContext(),
        );
      });

      tearDownAll(() {
        final dir = Directory(projectName);
        try {
          dir.delete(recursive: true);
        } on FileSystemException {
          // Gone.
        }
      });

      test('then returns success as true', () {
        expect(result.success, true);
      });

      test('then returns correct relativeServerPath', () {
        expect(result.relativeServerPath, '${projectName}_server');
      });
    },
  );
}
