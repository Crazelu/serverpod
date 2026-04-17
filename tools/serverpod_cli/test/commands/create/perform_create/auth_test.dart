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
    'Given a TemplateContext with auth and a database option enabled, '
    'when performCreate is called with the context and a server template type',
    () {
      late File serverFile;

      setUp(() async {
        final context = TemplateContext(auth: true, postgres: true);

        await performCreate(
          projectName,
          ServerpodTemplateType.server,
          false,
          interactive: false,
          context: context,
        );

        serverFile = File(p.join(serverDir.path, 'lib', 'server.dart'));
      });
      test(
        'then the email idp endpoint file is created',
        () async {
          final file = File(
            p.join(
              serverDir.path,
              'lib',
              'src',
              'auth',
              'email_idp_endpoint.dart',
            ),
          );

          await expectLater(file.exists(), completion(true));
        },
      );

      test(
        'then the jwt refresh endpoint file is created',
        () async {
          final file = File(
            p.join(
              serverDir.path,
              'lib',
              'src',
              'auth',
              'jwt_refresh_endpoint.dart',
            ),
          );

          await expectLater(file.exists(), completion(true));
        },
      );

      test(
        'then the server server.dart file contains auth imports',
        () async {
          final content = await serverFile.readAsString();

          expect(
            content,
            contains('package:serverpod_auth_idp_server/core.dart'),
          );

          expect(
            content,
            contains('package:serverpod_auth_idp_server/providers/email.dart'),
          );
        },
      );

      test(
        'then the server server.dart contains auth configuration',
        () async {
          final content = await serverFile.readAsString();
          expect(content, contains('initializeAuthServices'));
          expect(content, contains('EmailIdpConfigFromPasswords'));
          expect(content, contains('JwtConfigFromPasswords'));
        },
      );

      test(
        'then the server pubspec contains auth depedencies',
        () async {
          final file = File(p.join(serverDir.path, 'pubspec.yaml'));
          final content = await file.readAsString();
          expect(content, contains('serverpod_auth_idp_server'));
        },
      );

      test(
        'then the server passwords config contains auth secret keys',
        () async {
          final file = File(p.join(serverDir.path, 'config', 'passwords.yaml'));
          final content = await file.readAsString();
          expect(content, contains('emailSecretHashPepper:'));
          expect(content, contains('jwtHmacSha512PrivateKey:'));
          expect(content, contains('jwtRefreshTokenHashPepper:'));
        },
      );
    },
  );

  group(
    'Given a TemplateContext with auth disabled, '
    'when performCreate is called with the context and a server template type',
    () {
      late File serverFile;

      setUp(() async {
        await performCreate(
          projectName,
          ServerpodTemplateType.server,
          false,
          interactive: false,
          context: TemplateContext(auth: false),
        );

        serverFile = File(p.join(serverDir.path, 'lib', 'server.dart'));
      });
      test(
        'then the email idp endpoint file is not created',
        () async {
          final file = File(
            p.join(
              serverDir.path,
              'lib',
              'src',
              'auth',
              'email_idp_endpoint.dart',
            ),
          );

          await expectLater(file.exists(), completion(false));
        },
      );

      test(
        'then the jwt refresh endpoint file is not created',
        () async {
          final file = File(
            p.join(
              serverDir.path,
              'lib',
              'src',
              'auth',
              'jwt_refresh_endpoint.dart',
            ),
          );

          await expectLater(file.exists(), completion(false));
        },
      );

      test(
        'then the server server.dart file does not contain auth imports',
        () async {
          final content = await serverFile.readAsString();

          expect(
            content,
            isNot(contains('package:serverpod_auth_idp_server/core.dart')),
          );

          expect(
            content,
            isNot(
              contains(
                'package:serverpod_auth_idp_server/providers/email.dart',
              ),
            ),
          );
        },
      );

      test(
        'then the server server.dart does not contain auth configuration',
        () async {
          final content = await serverFile.readAsString();
          expect(content, isNot(contains('initializeAuthServices')));
          expect(content, isNot(contains('EmailIdpConfigFromPasswords')));
          expect(content, isNot(contains('JwtConfigFromPasswords')));
        },
      );

      test(
        'then the server pubspec does not contain auth depedencies',
        () async {
          final file = File(p.join(serverDir.path, 'pubspec.yaml'));
          final content = await file.readAsString();
          expect(content, isNot(contains('serverpod_auth_idp_server')));
        },
      );
    },
  );

  test(
    'Given a TemplateContext with auth disabled and a database option enabled, '
    'when performCreate is called with the context and a server template type, '
    'then the server passwords config does not contain auth secret keys',
    () async {
      final context = TemplateContext(auth: false, postgres: true);

      await performCreate(
        projectName,
        ServerpodTemplateType.server,
        false,
        interactive: false,
        context: context,
      );

      final file = File(p.join(serverDir.path, 'config', 'passwords.yaml'));
      final content = await file.readAsString();
      expect(content, isNot(contains('emailSecretHashPepper:')));
      expect(content, isNot(contains('jwtHmacSha512PrivateKey:')));
      expect(content, isNot(contains('jwtRefreshTokenHashPepper:')));
    },
  );
}
