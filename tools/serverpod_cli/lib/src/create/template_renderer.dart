import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:whiskers/whiskers.dart';

/// Responsible for rendering template files in a directory based on a provided context.
/// It processes both file contents and directory names,
/// allowing for dynamic project structures.
class TemplateRenderer {
  /// Creates a [TemplateRenderer].
  TemplateRenderer({
    required this.dir,
    required this.context,
  });

  /// The target directory containing the template files to be rendered.
  final Directory dir;

  /// The context used for rendering the templates, where keys are variable names
  final Map<String, Object?> context;

  /// Renders the templates in the target directory based on the provided context.
  Future<void> render() async {
    await _renderDirectory(dir);
  }

  /// Recursively renders all files and directories within the specified directory.
  Future<void> _renderDirectory(Directory dir) async {
    final entries = dir.listSync();

    for (final entry in entries) {
      if (entry is File) {
        await _renderFile(entry);
      } else if (entry is Directory) {
        final renderedName = _renderDirectoryName(p.basename(entry.path));
        final newPath = p.join(p.dirname(entry.path), renderedName);

        if (renderedName.isEmpty) {
          await _deleteDirectory(entry);
        } else if (newPath != entry.path) {
          try {
            await entry.rename(newPath);
            await _renderDirectory(Directory(newPath));
          } catch (_) {}
        } else {
          await _renderDirectory(entry);
        }
      }
    }
  }

  String _renderTemplate(String content) {
    try {
      var template = Template(content, lenient: true);
      return template.renderString(
        context,
        onMissingVariable: (name, context) {
          return '{{$name}}';
        },
      );
    } catch (_) {
      return content;
    }
  }

  /// Renders template directives in [file]'s content and
  /// rewrites [file] with the rendering result.
  /// If the [file] is empty after rewriting, the [file] is deleted.
  Future<void> _renderFile(File file) async {
    final content = await file.readAsString();
    final processedContent = _preprocessContent(content);
    final renderedContent = _renderTemplate(processedContent);

    if (renderedContent.trim().isEmpty) {
      await file.delete();
    } else if (renderedContent != content) {
      await file.writeAsString(renderedContent);
    }
  }

  /// Preprocesses the content by removing comment markers from template directives.
  /// The comment markers allow template directives to be included in the source
  /// files without affecting the syntax of the code.
  /// For example, `// {{#enableAuth}}` will be transformed to `{{#enableAuth}}`.
  String _preprocessContent(String content) {
    var result = content;

    result = result.replaceAllMapped(
      RegExp(r'//\s*(\{\{[^}]+\}\})'),
      (match) => match.group(1)!,
    );

    result = result.replaceAllMapped(
      RegExp(r'#\s*(\{\{[^}]+\}\})'),
      (match) => match.group(1)!,
    );

    return result;
  }

  /// Formats the directory name as a template and returns the rendered name.
  String _renderDirectoryName(String dirName) {
    final result = _formatDirectoryTemplate(dirName).replaceAll(r'{{\', '{{/');
    return _renderTemplate(result).replaceAll(RegExp(r'\{\{/ ?\}\}'), '');
  }

  /// Converts short hand template directive variables in directory name to
  /// fully formed variable names.
  /// For example, `{{#web}}web{{\web}}` will be transformed to
  /// `{{#SERVERPOD_ENABLE_WEB}}web{{\SERVERPOD_ENABLE_WEB}}`.
  String _formatDirectoryTemplate(String dirName) {
    return dirName.replaceAllMapped(
      RegExp(r'(\{\{[#\\])([a-z][a-zA-Z0-9]*)(\}\})'),
      (match) {
        final prefix = match.group(1)!;
        final variable = match.group(2)!;
        final suffix = match.group(3)!;

        final name = variable
            .replaceAllMapped(RegExp(r'([a-zA-Z0-9])'), (m) => '${m[1]}')
            .toUpperCase();

        return '${prefix}SERVERPOD_ENABLE_$name$suffix';
      },
    );
  }

  Future<void> _deleteDirectory(Directory dir) async {
    try {
      await dir.delete(recursive: true);
    } catch (_) {}
  }
}
