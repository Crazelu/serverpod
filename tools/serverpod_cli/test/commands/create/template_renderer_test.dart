import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:serverpod_cli/src/create/template_renderer.dart';
import 'package:test/test.dart';

void main() {
  group('Given a TemplateRenderer', () {
    late Directory testDir;
    late TemplateRenderer templateRenderer;

    setUp(() async {
      testDir = await Directory.systemTemp.createTemp('template_test_');
      templateRenderer = TemplateRenderer(dir: testDir);
    });

    tearDown(() async {
      await testDir.delete(recursive: true);
    });

    test(
      'when rendering a directory with conditional naming, '
      'and a true context value, '
      'then the directory name is formatted to remove the template directive',
      () async {
        final webDir = Directory(
          p.join(
            testDir.path,
            '{{#web}}web{{!web}}',
          ),
        );
        await webDir.create(recursive: true);
        await templateRenderer.render({'web': true});

        await expectLater(
          Directory(p.join(testDir.path, '{{#web}}web{{!web}}')).exists(),
          completion(false),
        );
        await expectLater(
          Directory(p.join(testDir.path, 'web')).exists(),
          completion(true),
        );
      },
    );

    test(
      'when rendering a directory with conditional naming, '
      'and a false context value, '
      'then the directory is deleted',
      () async {
        final webDir = Directory(
          p.join(
            testDir.path,
            '{{#web}}web{{!web}}',
          ),
        );
        await webDir.create(recursive: true);
        await templateRenderer.render({'web': false});

        await expectLater(
          Directory(p.join(testDir.path, '{{#web}}web{{!web}}')).exists(),
          completion(false),
        );
        await expectLater(
          Directory(p.join(testDir.path, 'web')).exists(),
          completion(false),
        );
      },
    );

    test(
      'when rendering directories with a mix of true and false context values, '
      'then the directories with false conditional directives are deleted',
      () async {
        final webDir = Directory(
          p.join(
            testDir.path,
            '{{#web}}web{{!web}}',
          ),
        );
        await webDir.create(recursive: true);

        final authDir = Directory(
          p.join(
            testDir.path,
            '{{#auth}}auth{{!auth}}',
          ),
        );
        await authDir.create(recursive: true);

        await templateRenderer.render({'auth': true, 'web': false});

        await expectLater(
          Directory(p.join(testDir.path, 'web')).exists(),
          completion(false),
        );

        await expectLater(
          Directory(p.join(testDir.path, 'auth')).exists(),
          completion(true),
        );
      },
    );

    test(
      'when rendering a directory with conditional naming and empty context, '
      'then the directory is deleted',
      () async {
        final authDir = Directory(
          p.join(testDir.path, '{{#auth}}auth{{!auth}}'),
        );
        await authDir.create(recursive: true);

        await templateRenderer.render({});

        await expectLater(
          Directory(p.join(testDir.path, 'auth')).exists(),
          completion(false),
        );
      },
    );

    test(
      'when rendering a directory with invalid conditional naming, '
      'and a true context value, '
      'then the directory name is not formatted to remove the template directive',
      () async {
        final webDir = Directory(
          p.join(
            testDir.path,
            '{{#web}}web{{*web}}',
          ),
        );
        await webDir.create(recursive: true);
        await templateRenderer.render({'web': true});

        await expectLater(
          Directory(p.join(testDir.path, '{{#web}}web{{*web}}')).exists(),
          completion(true),
        );
        await expectLater(
          Directory(p.join(testDir.path, 'web')).exists(),
          completion(false),
        );
      },
    );

    test(
      'when rendering a file with true context values'
      'then all the sections with conditional directives are retained in the file',
      () async {
        final testFile = File(p.join(testDir.path, 'test.dart'));
        await testFile.writeAsString('''
import 'dart:io';
// {{#auth}}
import 'auth.dart';
// {{/auth}}
// {{#web}}
import 'web.dart';
// {{/web}}

void main() {
  // {{#auth}}
  print('auth enabled');
  // {{/auth}}
  // {{#web}}
  print('web enabled');
  // {{/web}}
}
''');

        await templateRenderer.render({
          'auth': true,
          'web': true,
        });
        final content = await testFile.readAsString();
        expect(
          content,
          matches(
            r"import \'dart:io\';\n"
            r"import \'auth.dart\';\n"
            r"import \'web.dart\';\n"
            r'\n'
            r'void main\(\) \{\n'
            r"  print\(\'auth enabled\'\);\n"
            r"  print\(\'web enabled\'\);\n"
            r'\}\n',
          ),
        );
      },
    );

    test(
      'when rendering a file with a mix of true and false context values'
      'then only the sections with true conditional directives are retained in the file',
      () async {
        final testFile = File(p.join(testDir.path, 'test.dart'));
        await testFile.writeAsString('''
import 'dart:io';
// {{#auth}}
import 'auth.dart';
// {{/auth}}
// {{#web}}
import 'web.dart';
// {{/web}}

void main() {
  // {{#auth}}
  print('auth enabled');
  // {{/auth}}
  // {{#web}}
  print('web enabled');
  // {{/web}}
}
''');

        await templateRenderer.render({
          'auth': true,
          'web': false,
        });
        final content = await testFile.readAsString();
        expect(
          content,
          matches(
            r"import \'dart:io\';\n"
            r"import \'auth.dart\';\n"
            r'\n'
            r'void main\(\) \{\n'
            r"  print\(\'auth enabled\'\);\n"
            r'\}\n',
          ),
        );
      },
    );

    test(
      'when rendering a file with conditional sections and empty context, '
      'then all conditional sections are removed from the file',
      () async {
        final testFile = File(p.join(testDir.path, 'test.dart'));
        await testFile.writeAsString('''
import 'dart:io';
// {{#auth}}
import 'auth.dart';
// {{/auth}}
// {{#web}}
import 'web.dart';
// {{/web}}

void main() {
  // {{#auth}}
  print('auth enabled');
  // {{/auth}}
  // {{#web}}
  print('web enabled');
  // {{/web}}
}
''');

        await templateRenderer.render({});

        final content = await testFile.readAsString();
        expect(
          content,
          matches(
            r"import \'dart:io\';\n"
            r'\n'
            r'void main\(\) \{\n'
            r'\}\n',
          ),
        );
      },
    );

    test(
      'when rendering a file with all its contents in conditional sections and empty context, '
      'then the file is deleted',
      () async {
        final testFile = File(p.join(testDir.path, 'only_conditionals.dart'));
        await testFile.writeAsString('''
// {{#auth}}
import 'auth.dart';
// {{/auth}}
// {{#web}}
import 'auth.web';
// {{/web}}
''');

        await templateRenderer.render({});
        await expectLater(testFile.exists(), completion(false));
      },
    );

    test(
      'when rendering a YAML file with conditional template directive, '
      'and context contains true value, '
      'then the conditional directive is processed correctly',
      () async {
        final testFile = File(p.join(testDir.path, 'config.yaml'));
        await testFile.writeAsString('''
development:
  # {{#redis}}
  redis: 'REDIS_PASSWORD'
  # {{/redis}}
  database: 'DB_PASSWORD'
''');

        await templateRenderer.render({'redis': true});

        final content = await testFile.readAsString();
        expect(
          content,
          matches(
            r'development:\n'
            r"  redis: \'REDIS_PASSWORD\'\n"
            r"  database: \'DB_PASSWORD\'\n",
          ),
        );
      },
    );

    test(
      'when rendering YAML file with conditional template directive, '
      'and context contains false value, '
      'then the conditional directive is processed correctly',
      () async {
        final testFile = File(p.join(testDir.path, 'config.yaml'));
        await testFile.writeAsString('''
development:
  # {{#redis}}
  redis: 'REDIS_PASSWORD'
  # {{/redis}}
  database: 'DB_PASSWORD'
''');

        await templateRenderer.render({'redis': false});

        final content = await testFile.readAsString();
        expect(
          content,
          matches(
            r'development:\n'
            r"  database: \'DB_PASSWORD\'\n",
          ),
        );
      },
    );

    test(
      'when rendering nested directories with true context values, '
      'then they are processed correctly',
      () async {
        final nestedDir = Directory(
          p.join(
            testDir.path,
            '{{#web}}web{{!web}}',
            '{{#auth}}auth{{!auth}}',
          ),
        );
        await nestedDir.create(recursive: true);

        await templateRenderer.render({
          'auth': true,
          'web': true,
        });

        await expectLater(
          Directory(p.join(testDir.path, 'web', 'auth')).exists(),
          completion(true),
        );
      },
    );

    test(
      'when rendering nested directories '
      'and the parent directory has a name with false condition, '
      'then the nested directories are deleted',
      () async {
        final nestedDir = Directory(
          p.join(
            testDir.path,
            '{{#web}}web{{!web}}',
            '{{#auth}}auth{{!auth}}',
          ),
        );
        await nestedDir.create(recursive: true);

        await templateRenderer.render({
          'auth': true,
          'web': false,
        });

        await expectLater(
          Directory(p.join(testDir.path, 'web', 'auth')).exists(),
          completion(false),
        );
      },
    );

    test(
      'when rendering nested directories '
      'and the nested directory has a name with false condition, '
      'then only the nested directory is deleted',
      () async {
        final nestedDir = Directory(
          p.join(
            testDir.path,
            '{{#web}}web{{!web}}',
            '{{#auth}}auth{{!auth}}',
          ),
        );
        await nestedDir.create(recursive: true);

        await templateRenderer.render({
          'auth': false,
          'web': true,
        });

        await expectLater(
          Directory(p.join(testDir.path, 'web')).exists(),
          completion(true),
        );

        await expectLater(
          Directory(p.join(testDir.path, 'web', 'auth')).exists(),
          completion(false),
        );
      },
    );
  });
}
