import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:whiskers/whiskers.dart';

/// Responsible for rendering template files in a directory using provided context.
/// It processes both file contents and directory names,
/// allowing for dynamic project structures.
class TemplateRenderer {
  /// Creates a [TemplateRenderer].
  TemplateRenderer({required this.dir});

  /// The target directory containing the template files to be rendered.
  final Directory dir;

  /// Renders the templates in the target directory using [context].
  Future<void> render(Map<String, Object?> context) async {
    await _renderDirectory(dir, context);
  }

  /// Recursively renders all files and directories within the specified directory.
  Future<void> _renderDirectory(
    Directory dir,
    Map<String, Object?> context,
  ) async {
    final entries = dir.listSync();

    for (final entry in entries) {
      if (entry is File) {
        await _renderFile(entry, context);
      } else if (entry is Directory) {
        final renderedName = _renderDirectoryName(
          p.basename(entry.path),
          context,
        );
        final newPath = p.join(p.dirname(entry.path), renderedName);

        if (renderedName.isEmpty) {
          await _deleteDirectory(entry);
        } else if (newPath != entry.path) {
          try {
            await entry.rename(newPath);
            await _renderDirectory(Directory(newPath), context);
          } on FileSystemException {
            // Directory gone.
          }
        } else {
          await _renderDirectory(entry, context);
        }
      }
    }
  }

  String _renderTemplate(String content, Map<String, Object?> context) {
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
  Future<void> _renderFile(File file, Map<String, Object?> context) async {
    try {
      final content = await file.readAsString();
      final processedContent = _preprocessContent(content);
      final renderedContent = _renderTemplate(processedContent, context);

      if (renderedContent.trim().isEmpty) {
        await file.delete();
      } else if (renderedContent != content) {
        await file.writeAsString(renderedContent);
      }
    } on FileSystemException {
      // File gone or not decodable.
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
  String _renderDirectoryName(String dirName, Map<String, Object?> context) {
    return _renderTemplate(
      dirName.replaceAll(r'{{!', '{{/'),
      context,
    ).replaceAll(RegExp(r'\{\{/ ?\}\}'), '');
  }

  Future<void> _deleteDirectory(Directory dir) async {
    try {
      await dir.delete(recursive: true);
    } on FileSystemException {
      // Directory gone.
    }
  }
}
