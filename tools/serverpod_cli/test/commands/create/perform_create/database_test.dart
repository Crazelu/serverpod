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
    'Given a TemplateContext with postgres enabled and redis disabled, '
    'when performCreate is called with the context and a server template type',
    () {
      setUp(() async {
        await performCreate(
          projectName,
          ServerpodTemplateType.server,
          false,
          interactive: false,
          context: TemplateContext(postgres: true, redis: false),
        );
      });

      test(
        'then the server Dockerfile file is created',
        () async {
          final file = File(p.join(serverDir.path, 'Dockerfile'));
          await expectLater(file.exists(), completion(true));
        },
      );

      group(
        'then the server docker-compose file',
        () {
          late File dockerComposeFile;

          setUp(() {
            dockerComposeFile = File(
              p.join(serverDir.path, 'docker-compose.yaml'),
            );
          });

          test(
            'is created',
            () async {
              await expectLater(dockerComposeFile.exists(), completion(true));
            },
          );

          test(
            'contains postgres configurations',
            () async {
              final content = await dockerComposeFile.readAsString();
              expect(content, contains('postgres:'));
              expect(content, contains('postgres_test:'));
              expect(content, contains('volumes:'));
            },
          );

          test(
            'does not contain redis configurations',
            () async {
              final content = await dockerComposeFile.readAsString();
              expect(content, isNot(contains('redis:')));
              expect(content, isNot(contains('redis_test:')));
            },
          );
        },
      );

      group(
        'then the server passwords config file',
        () {
          late File config;

          setUp(() {
            config = File(
              p.join(serverDir.path, 'config', 'passwords.yaml'),
            );
          });

          test(
            'is created',
            () async {
              await expectLater(config.exists(), completion(true));
            },
          );

          test(
            'contains postgres configurations',
            () async {
              final content = await config.readAsString();
              expect(content, contains('database:'));
            },
          );

          test(
            'does not contain redis configurations',
            () async {
              final content = await config.readAsString();
              expect(content, isNot(contains('redis:')));
            },
          );
        },
      );
    },
  );

  group(
    'Given a TemplateContext with redis enabled and postgres disabled, '
    'when performCreate is called with the context and a server template type',
    () {
      setUp(() async {
        await performCreate(
          projectName,
          ServerpodTemplateType.server,
          false,
          interactive: false,
          context: TemplateContext(redis: true, postgres: false),
        );
      });

      test(
        'then the server Dockerfile file is created',
        () async {
          final file = File(p.join(serverDir.path, 'Dockerfile'));
          await expectLater(file.exists(), completion(true));
        },
      );

      group(
        'then the server docker-compose file',
        () {
          late File dockerComposeFile;

          setUp(() {
            dockerComposeFile = File(
              p.join(serverDir.path, 'docker-compose.yaml'),
            );
          });

          test(
            'is created',
            () async {
              await expectLater(dockerComposeFile.exists(), completion(true));
            },
          );

          test(
            'contains redis configurations',
            () async {
              final content = await dockerComposeFile.readAsString();
              expect(content, contains('redis:'));
              expect(content, contains('redis_test:'));
            },
          );

          test(
            'does not contain postgres configurations',
            () async {
              final content = await dockerComposeFile.readAsString();
              expect(content, isNot(contains('postgres:')));
              expect(content, isNot(contains('postgres_test:')));
              expect(content, isNot(contains('volumes:')));
            },
          );
        },
      );

      group(
        'then the server passwords config file',
        () {
          late File config;

          setUp(() {
            config = File(
              p.join(serverDir.path, 'config', 'passwords.yaml'),
            );
          });

          test(
            'is created',
            () async {
              await expectLater(config.exists(), completion(true));
            },
          );

          test(
            'contains redis configurations',
            () async {
              final content = await config.readAsString();
              expect(content, contains('redis:'));
            },
          );

          test(
            'does not contain postgres configurations',
            () async {
              final content = await config.readAsString();
              expect(content, isNot(contains('database:')));
            },
          );
        },
      );
    },
  );

  group(
    'Given a TemplateContext with redis disabled and no database option enabled, '
    'when performCreate is called with the context and a server template type',
    () {
      setUp(() async {
        final context = TemplateContext(
          postgres: false,
          redis: false,
          sqlite: false,
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
        'then the server Dockerfile file is not created',
        () async {
          final file = File(p.join(serverDir.path, 'Dockerfile'));
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
        'then the server passwords config file is not created',
        () async {
          final file = File(
            p.join(
              serverDir.path,
              'config'
              'passwords.yaml',
            ),
          );
          await expectLater(file.exists(), completion(false));
        },
      );

      test(
        'then the server config for development does not contain database configurations',
        () async {
          final config = File(
            p.join(serverDir.path, 'config', 'development.yaml'),
          );
          final content = await config.readAsString();
          expect(content, isNot(contains('database:')));
        },
      );

      test(
        'then the server config for staging does not contain database configurations',
        () async {
          final config = File(
            p.join(serverDir.path, 'config', 'staging.yaml'),
          );
          final content = await config.readAsString();
          expect(content, isNot(contains('database:')));
        },
      );

      test(
        'then the server config for production does not contain database configurations',
        () async {
          final config = File(
            p.join(serverDir.path, 'config', 'production.yaml'),
          );
          final content = await config.readAsString();
          expect(content, isNot(contains('database:')));
        },
      );

      test(
        'then the server config for test does not contain database configurations',
        () async {
          final config = File(
            p.join(serverDir.path, 'config', 'test.yaml'),
          );
          final content = await config.readAsString();
          expect(content, isNot(contains('database:')));
        },
      );
    },
  );

  group(
    'Given a TemplateContext with postgres enabled and redis disabled, '
    'when performCreate is called with the context and a module template type',
    () {
      setUp(() async {
        await performCreate(
          projectName,
          ServerpodTemplateType.module,
          false,
          interactive: false,
          context: TemplateContext(postgres: true, redis: false),
        );
      });

      group(
        'then the server docker-compose file',
        () {
          late File dockerComposeFile;

          setUp(() {
            dockerComposeFile = File(
              p.join(serverDir.path, 'docker-compose.yaml'),
            );
          });

          test(
            'is created',
            () async {
              await expectLater(dockerComposeFile.exists(), completion(true));
            },
          );

          test(
            'contains postgres configurations',
            () async {
              final content = await dockerComposeFile.readAsString();
              expect(content, contains('postgres_test:'));
              expect(content, contains('volumes:'));
            },
          );

          test(
            'does not contain redis configurations',
            () async {
              final content = await dockerComposeFile.readAsString();
              expect(content, isNot(contains('redis_test:')));
            },
          );
        },
      );

      group(
        'then the server passwords config file',
        () {
          late File config;

          setUp(() {
            config = File(
              p.join(serverDir.path, 'config', 'passwords.yaml'),
            );
          });

          test(
            'is created',
            () async {
              await expectLater(config.exists(), completion(true));
            },
          );

          test(
            'contains postgres configurations',
            () async {
              final content = await config.readAsString();
              expect(content, contains('database:'));
            },
          );

          test(
            'does not contain redis configurations',
            () async {
              final content = await config.readAsString();
              expect(content, isNot(contains('redis:')));
            },
          );
        },
      );

      group(
        'then the server config for test',
        () {
          late File config;

          setUp(() {
            config = File(p.join(serverDir.path, 'config', 'test.yaml'));
          });

          test(
            'contains database configurations',
            () async {
              final content = await config.readAsString();
              expect(content, contains('database:'));
            },
          );

          test(
            'contains persistent session logging configuration',
            () async {
              final content = await config.readAsString();
              expect(content, contains('persistentEnabled: true'));
            },
          );

          test(
            'does not contain redis configurations',
            () async {
              final content = await config.readAsString();
              expect(content, isNot(contains('redis:')));
            },
          );
        },
      );
    },
  );

  group(
    'Given a TemplateContext with redis enabled and postgres disabled, '
    'when performCreate is called with the context and a module template type',
    () {
      setUp(() async {
        await performCreate(
          projectName,
          ServerpodTemplateType.module,
          false,
          interactive: false,
          context: TemplateContext(redis: true, postgres: false),
        );
      });

      group(
        'then the server docker-compose file',
        () {
          late File dockerComposeFile;

          setUp(() {
            dockerComposeFile = File(
              p.join(serverDir.path, 'docker-compose.yaml'),
            );
          });

          test(
            'is created',
            () async {
              await expectLater(dockerComposeFile.exists(), completion(true));
            },
          );

          test(
            'contains redis configurations',
            () async {
              final content = await dockerComposeFile.readAsString();
              expect(content, contains('redis_test:'));
            },
          );

          test(
            'does not contain postgres configurations',
            () async {
              final content = await dockerComposeFile.readAsString();
              expect(content, isNot(contains('postgres_test:')));
              expect(content, isNot(contains('volumes:')));
            },
          );
        },
      );

      group(
        'then the server passwords config file',
        () {
          late File config;

          setUp(() {
            config = File(
              p.join(serverDir.path, 'config', 'passwords.yaml'),
            );
          });

          test(
            'is created',
            () async {
              await expectLater(config.exists(), completion(true));
            },
          );

          test(
            'contains redis configurations',
            () async {
              final content = await config.readAsString();
              expect(content, contains('redis:'));
            },
          );

          test(
            'does not contain postgres configurations',
            () async {
              final content = await config.readAsString();
              expect(content, isNot(contains('database:')));
            },
          );
        },
      );

      test(
        'then the server config for test contains redis configurations',
        () async {
          final file = File(p.join(serverDir.path, 'config', 'test.yaml'));
          final content = await file.readAsString();
          expect(content, contains('redis:'));
        },
      );
    },
  );

  group(
    'Given a TemplateContext with redis disabled and no database option enabled, '
    'when performCreate is called with the context and a module template type',
    () {
      setUp(() async {
        final context = TemplateContext(
          postgres: false,
          redis: false,
          sqlite: false,
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
        'then the server docker-compose file is not created',
        () async {
          final file = File(p.join(serverDir.path, 'docker-compose.yaml'));
          await expectLater(file.exists(), completion(false));
        },
      );

      test(
        'then the server passwords config file is not created',
        () async {
          final file = File(
            p.join(
              serverDir.path,
              'config'
              'passwords.yaml',
            ),
          );
          await expectLater(file.exists(), completion(false));
        },
      );

      group(
        'then the server config for test',
        () {
          late File config;

          setUp(() {
            config = File(p.join(serverDir.path, 'config', 'test.yaml'));
          });

          test(
            'does not contain database configurations',
            () async {
              final content = await config.readAsString();
              expect(content, isNot(contains('database:')));
            },
          );

          test(
            'does not contain persistent session logging configuration',
            () async {
              final content = await config.readAsString();
              expect(content, isNot(contains('persistentEnabled: true')));
            },
          );
        },
      );
    },
  );
}
