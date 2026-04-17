import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:serverpod_cli/src/create/create.dart';
import 'package:serverpod_cli/src/create/template_context.dart';
import 'package:test/test.dart';

import 'util.dart';

void main() {
  const projectName = 'test_project';
  late Directory testDir;
  late Directory currentDir;
  late Directory serverDir;

  setUpAll(() {
    setupForPerformCreateTest();
  });

  setUp(() async {
    testDir = await Directory.systemTemp.createTemp('perform_create_test');
    serverDir = Directory(
      p.join(testDir.path, projectName, '${projectName}_server'),
    );
    currentDir = Directory.current;
    Directory.current = testDir;
  });

  tearDown(() async {
    await testDir.delete(recursive: true);
    Directory.current = currentDir;
  });

  group(
    'Given a TemplateContext with redis or any database option enabled, '
    'when performCreate is called with the context and a server template type, ',
    () {
      setUp(() async {
        await performCreate(
          projectName,
          ServerpodTemplateType.server,
          false,
          interactive: false,
          context: TemplateContext(redis: true),
        );
      });

      test(
        'then the server passwords config file is created',
        () async {
          final file = File(p.join(serverDir.path, 'config', 'passwords.yaml'));
          await expectLater(file.exists(), completion(true));
        },
      );

      test(
        'then the server docker-compose file is created',
        () async {
          final file = File(p.join(serverDir.path, 'docker-compose.yaml'));
          await expectLater(file.exists(), completion(true));
        },
      );

      test(
        'then the server Dockerfile file is created',
        () async {
          final file = File(p.join(serverDir.path, 'Dockerfile'));
          await expectLater(file.exists(), completion(true));
        },
      );
    },
  );

  group(
    'Given a TemplateContext with neither redis nor any database option enabled, '
    'when performCreate is called with the context and a server template type, ',
    () {
      setUp(() async {
        final context = TemplateContext(
          redis: false,
          sqlite: false,
          postgres: false,
        );

        await performCreate(
          projectName,
          ServerpodTemplateType.server,
          false,
          interactive: false,
          context: context,
        );
      });

      test(
        'then the server passwords config file is not created',
        () async {
          final file = File(p.join(serverDir.path, 'config', 'passwords.yaml'));
          await expectLater(file.exists(), completion(false));
        },
      );

      test(
        'then the server docker-compose file is not created',
        () async {
          final file = File(p.join(serverDir.path, 'docker-compose.yaml'));
          await expectLater(file.exists(), completion(false));
        },
      );

      test(
        'then the server Dockerfile file is not created',
        () async {
          final file = File(p.join(serverDir.path, 'Dockerfile'));
          await expectLater(file.exists(), completion(false));
        },
      );
    },
  );

  group(
    'Given a TemplateContext with redis or any database option enabled, '
    'when performCreate is called with the context and a module template type, ',
    () {
      setUp(() async {
        await performCreate(
          projectName,
          ServerpodTemplateType.module,
          false,
          interactive: false,
          context: TemplateContext(postgres: true),
        );
      });

      test(
        'then the server passwords config file is created',
        () async {
          final file = File(p.join(serverDir.path, 'config', 'passwords.yaml'));
          await expectLater(file.exists(), completion(true));
        },
      );

      test(
        'then the server docker-compose file is created',
        () async {
          final file = File(p.join(serverDir.path, 'docker-compose.yaml'));
          await expectLater(file.exists(), completion(true));
        },
      );
    },
  );

  group(
    'Given a TemplateContext with neither redis nor any database option enabled, '
    'when performCreate is called with the context and a module template type, ',
    () {
      setUp(() async {
        final context = TemplateContext(
          redis: false,
          sqlite: false,
          postgres: false,
        );

        await performCreate(
          projectName,
          ServerpodTemplateType.module,
          false,
          interactive: false,
          context: context,
        );
      });

      test(
        'then the server passwords config file is not created',
        () async {
          final file = File(p.join(serverDir.path, 'config', 'passwords.yaml'));
          await expectLater(file.exists(), completion(false));
        },
      );

      test(
        'then the server docker-compose file is not created',
        () async {
          final file = File(p.join(serverDir.path, 'docker-compose.yaml'));
          await expectLater(file.exists(), completion(false));
        },
      );
    },
  );
}
