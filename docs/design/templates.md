# Design: Serverpod Templates

This document proposes an enhancement to Serverpod templates to support conditional rendering.

## Current State

Templates currently only support placeholder replacements with a very verbose setup. The templates also contain valid dart files which are statically analyzed.

This design introduces a mustache-based template directives to enable conditional inclusion or removal of directories, files and sections within files for templates.

## Proposed Solution

Introduce mustache syntax for conditionals. In code files (dart and yaml), template directives will be embedded in single line comment blocks to preserve static analysis guarantees.

```dart
import 'dart:io';

import 'package:serverpod/serverpod.dart';
// {{#SERVERPOD_ENABLE_AUTH}}
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';
// {{/SERVERPOD_ENABLE_AUTH}}

import 'src/generated/endpoints.dart';
import 'src/generated/protocol.dart';
// {{#SERVERPOD_ENABLE_WEB}}
import 'src/web/routes/app_config_route.dart';
import 'src/web/routes/root.dart';
// {{/SERVERPOD_ENABLE_WEB}}

/// The starting point of the Serverpod server.
void run(List<String> args) async {
  // Initialize Serverpod and connect it with your generated code.
  final pod = Serverpod(args, Protocol(), Endpoints());

  // {{#SERVERPOD_ENABLE_AUTH}}
  // Initialize authentication services for the server.
  // Token managers will be used to validate and issue authentication keys,
  // and the identity providers will be the authentication options available for users.
  pod.initializeAuthServices(
    tokenManagerBuilders: [
      // Use JWT for authentication keys towards the server.
      JwtConfigFromPasswords(),
    ],
  );
  // {{/SERVERPOD_ENABLE_AUTH}}

  // Start the server.
  await pod.start();
}
```

```yaml
development:
  database: 'DB_PASSWORD'
  # {{#SERVERPOD_ENABLE_REDIS}}
  redis: 'REDIS_PASSWORD'
  # {{/SERVERPOD_ENABLE_REDIS}}
```

Directories may also have template directives in their names using a short-hand syntax to enable conditional rendering of entire directories based on enabled features.

For example:

- `project_name_server_upgrade/{{#web}}web{{\web}}` is processed as `project_name_server_upgrade/{{#SERVERPOD_ENABLE_WEB}}web{{\SERVERPOD_ENABLE_WEB}}`
- `project_name_server_upgrade/lib/src/{{#auth}}auth{{\auth}}` is processed as `project_name_server_upgrade/lib/src/{{#SERVERPOD_ENABLE_AUTH}}auth{{\SERVERPOD_ENABLE_AUTH}}`

NOTE: To prevent nested directories, `\` is used to mark the end of a conditional directive in directory names instead of `/`. However, in file contents, `/` is used.

After the current Serverpod create command runs, then all server files will be rendered to include or remove the conditional sections based on enabled parameters in the context. When rendering results in an empty directory name, then the directory is deleted along with all the files contained in it. Likewise, when rendering results in a file with empty content, then the file is deleted.
