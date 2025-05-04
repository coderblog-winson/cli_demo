import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:path/path.dart' as path;
import 'package:args/args.dart';
import 'dart:io';
import 'dart:convert';

void main(List<String> arguments) {
  final parser =
      ArgParser()
        ..addFlag(
          'help',
          abbr: 'h',
          help: 'Show usage information.',
          negatable: false,
        )
        ..addFlag(
          'version',
          abbr: 'v',
          help: 'Show version information.',
          negatable: false,
        );

  final results = parser.parse(arguments);

  if (results['help']) {
    printUsage(parser);
    exit(0);
  }

  if (results['version']) {
    printVersion();
    exit(0);
  }

  if (arguments.length < 2 || arguments.first != 'create') {
    printUsage(parser);
    exit(1);
  }

  final command = arguments.sublist(1).join(' ');

  if (!command.startsWith('page:')) {
    print('Invalid command format. Expected: create page:<pagename>');
    printUsage(parser);
    exit(1);
  }

  final pageName = command.split(':')[1];
  createPage(pageName);
}

void printUsage(ArgParser parser) {
  print('Usage:');
  print('  cli [options] create page:<pagename>');
  print('');
  print(parser.usage);
}

void printVersion() {
  print('cli version v1.0.0');
}

void createPage(String pageName) {
  final dirPath = path.join(Directory.current.path, 'pages', pageName);

  // Delete directory if it exists
  if (exists(dirPath)) {
    find(
      '*',
      workingDirectory: dirPath,
      recursive: true,
      types: [Find.file],
    ).forEach(delete);
    deleteDir(dirPath);
    print('Deleted existing directory $dirPath');
  }

  // Create directory
  createDir(dirPath, recursive: true);
  print('Created directory $dirPath');

  // PascalCase conversion for class names
  final className = toPascalCase(pageName);

  // Load templates from the package
  final templateDir = 'lib/templates/page';
  final controllerTemplatePath = path.join(templateDir, 'controller.template');
  final viewTemplatePath = path.join(templateDir, 'view.template');
  final indexTemplatePath = path.join(templateDir, 'index.template');

  final controllerTemplate = loadAsset(controllerTemplatePath);
  final viewTemplate = loadAsset(viewTemplatePath);
  final indexTemplate = loadAsset(indexTemplatePath);

  if (controllerTemplate == null ||
      viewTemplate == null ||
      indexTemplate == null) {
    print(
      'One or more template files are missing in the lib/templates/page directory.',
    );
    exit(1);
  }

  // Replace placeholders in templates
  final controllerContent = controllerTemplate
      .replaceAll('{{className}}', className)
      .replaceAll('{{pageName}}', pageName);
  final viewContent = viewTemplate.replaceAll('{{className}}', className);
  final indexContent = indexTemplate.replaceAll('{{pageName}}', pageName);

  // Create or overwrite controller.dart
  final controllerFilePath = path.join(dirPath, 'controller.dart');
  File(controllerFilePath).writeAsStringSync(controllerContent);
  print('Created or overwritten file $controllerFilePath');

  // Create or overwrite view.dart
  final viewFilePath = path.join(dirPath, 'view.dart');
  File(viewFilePath).writeAsStringSync(viewContent);
  print('Created or overwritten file $viewFilePath');

  // Create or overwrite index.dart
  final indexPath = path.join(dirPath, 'index.dart');
  File(indexPath).writeAsStringSync(indexContent);
  print('Created or overwritten file $indexPath');
}

String toPascalCase(String str) {
  return str
      .split('_')
      .map((word) => word.substring(0, 1).toUpperCase() + word.substring(1))
      .join('');
}

String? loadAsset1(String assetPath) {
  try {
    final bytes = File.fromUri(Uri.parse(assetPath)).readAsBytesSync();
    return utf8.decode(bytes);
  } catch (e) {
    print('Failed to load asset: $assetPath');
    return null;
  }
}

String? loadAsset(String assetPath) {
  final scriptFile = Platform.script.toFilePath();
  final scriptDir = path.dirname(scriptFile);
  final packageRoot = path.join(
    scriptDir,
    '..',
  ); // Assuming bin is one level below the root

  //final packageRoot = 'your_project_root_path'; //if cannot get the project root correctly, then set it manually
  final filePath = path.join(packageRoot, assetPath);
  // final filePath = path.join(scriptDir, assetPath);
  try {
    final content = File(filePath).readAsStringSync();
    return content;
  } catch (e) {
    print('Failed to load asset: $filePath');
    return null;
  }
}
