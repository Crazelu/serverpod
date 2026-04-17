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
    'Given a TemplateContext with web enabled, '
    'when performCreate is called with the context and a server template type',
    () {
      late Directory webDir;

      setUp(() async {
        await performCreate(
          projectName,
          ServerpodTemplateType.server,
          false,
          interactive: false,
          context: TemplateContext(web: true),
        );

        webDir = Directory(p.join(serverDir.path, 'web'));
      });

      test(
        'then the server contains a web directory',
        () async {
          await expectLater(webDir.exists(), completion(true));
        },
      );

      test(
        'then the server web directory contains web templates',
        () async {
          final templatesDir = Directory(p.join(webDir.path, 'templates'));
          await expectLater(templatesDir.exists(), completion(true));

          final html = File(
            p.join(templatesDir.path, 'built_with_serverpod.html'),
          );
          await expectLater(html.exists(), completion(true));
        },
      );

      test(
        'then the server server.dart contains web imports',
        () async {
          final serverFile = File(p.join(serverDir.path, 'lib', 'server.dart'));
          final content = await serverFile.readAsString();
          expect(content, contains('src/web/routes/app_config_route.dart'));
          expect(content, contains('src/web/routes/root.dart'));
        },
      );

      test(
        'then the server server.dart contains web configurations',
        () async {
          final serverFile = File(p.join(serverDir.path, 'lib', 'server.dart'));
          final content = await serverFile.readAsString();
          expect(content, contains('pod.webServer.addRoute('));
          expect(
            content,
            contains('AppConfigRoute(apiConfig: pod.config.apiServer)'),
          );
        },
      );

      test(
        'then the server config for development contains webserver configurations',
        () async {
          final config = File(
            p.join(serverDir.path, 'config', 'development.yaml'),
          );
          final content = await config.readAsString();
          expect(content, contains('webServer:'));
        },
      );

      test(
        'then the server config for staging contains webserver configurations',
        () async {
          final config = File(
            p.join(serverDir.path, 'config', 'staging.yaml'),
          );
          final content = await config.readAsString();
          expect(content, contains('webServer:'));
        },
      );

      test(
        'then the server config for production contains webserver configurations',
        () async {
          final config = File(
            p.join(serverDir.path, 'config', 'production.yaml'),
          );
          final content = await config.readAsString();
          expect(content, contains('webServer:'));
        },
      );

      test(
        'then the server config for test contains webserver configurations',
        () async {
          final config = File(
            p.join(serverDir.path, 'config', 'test.yaml'),
          );
          final content = await config.readAsString();
          expect(content, contains('webServer:'));
        },
      );
    },
  );

  group(
    'Given a TemplateContext with web disabled, '
    'when performCreate is called with the context and a server template type',
    () {
      late Directory webDir;

      setUp(() async {
        await performCreate(
          projectName,
          ServerpodTemplateType.server,
          false,
          interactive: false,
          context: TemplateContext(web: false),
        );

        webDir = Directory(p.join(serverDir.path, 'web'));
      });

      test(
        'then the server does not contain a web directory',
        () async {
          await expectLater(webDir.exists(), completion(false));
        },
      );

      test(
        'then the server server.dart does not contain web imports',
        () async {
          final serverFile = File(p.join(serverDir.path, 'lib', 'server.dart'));
          final content = await serverFile.readAsString();
          expect(
            content,
            isNot(contains('src/web/routes/app_config_route.dart')),
          );
          expect(content, isNot(contains('src/web/routes/root.dart')));
        },
      );

      test(
        'then the server server.dart does not contain web configurations',
        () async {
          final serverFile = File(p.join(serverDir.path, 'lib', 'server.dart'));
          final content = await serverFile.readAsString();
          expect(content, isNot(contains('pod.webServer.addRoute(')));
          expect(
            content,
            isNot(contains('AppConfigRoute(apiConfig: pod.config.apiServer)')),
          );
        },
      );

      test(
        'then the server config for development does not contain webserver configurations',
        () async {
          final config = File(
            p.join(serverDir.path, 'config', 'development.yaml'),
          );
          final content = await config.readAsString();
          expect(content, isNot(contains('webServer:')));
        },
      );

      test(
        'then the server config for staging does not contain webserver configurations',
        () async {
          final config = File(
            p.join(serverDir.path, 'config', 'staging.yaml'),
          );
          final content = await config.readAsString();
          expect(content, isNot(contains('webServer:')));
        },
      );

      test(
        'then the server config for production does not contain webserver configurations',
        () async {
          final config = File(
            p.join(serverDir.path, 'config', 'production.yaml'),
          );
          final content = await config.readAsString();
          expect(content, isNot(contains('webServer:')));
        },
      );

      test(
        'then the server config for test does not contain webserver configurations',
        () async {
          final config = File(
            p.join(serverDir.path, 'config', 'test.yaml'),
          );
          final content = await config.readAsString();
          expect(content, isNot(contains('webServer:')));
        },
      );
    },
  );

  test(
    'Given a TemplateContext with web enabled, '
    'when performCreate is called with the context and a module template type, '
    'then the server test config contains webserver configuration',
    () async {
      await performCreate(
        projectName,
        ServerpodTemplateType.module,
        false,
        interactive: false,
        context: TemplateContext(web: true),
      );

      final file = File(p.join(serverDir.path, 'config', 'test.yaml'));
      final content = await file.readAsString();
      expect(content, contains('webServer:'));
    },
  );

  test(
    'Given a TemplateContext with web disabled, '
    'when performCreate is called with the context and a module template type, '
    'then the server test config does not contain webserver configuration',
    () async {
      await performCreate(
        projectName,
        ServerpodTemplateType.module,
        false,
        interactive: false,
        context: TemplateContext(web: false),
      );

      final file = File(p.join(serverDir.path, 'config', 'test.yaml'));
      final content = await file.readAsString();
      expect(content, isNot(contains('webServer:')));
    },
  );
}
