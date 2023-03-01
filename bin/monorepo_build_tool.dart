import 'dart:io';

import 'package:monorepo_build_tool/src/circle_ci/circle_ci_update_manager.dart';
import 'package:monorepo_build_tool/src/monorepo_build_tool.dart';
import 'package:monorepo_build_tool/src/update_manager/update_manager.dart';
import 'package:monorepo_build_tool/src/yaml/exceptions.dart';
import 'package:yaml/yaml.dart';

final String defaultConfigPath = 'monorepo.yaml';

// arguments[0] is an optional override path to the config
void main(List<String> arguments) async {
  final String configPath = arguments.isNotEmpty
      ? arguments.firstWhere((arg) => arg.contains('.yaml'),
          orElse: () => defaultConfigPath)
      : defaultConfigPath;
  final File configFile = File(configPath);
  if (!configFile.existsSync()) {
    throw ConfigException(
        "Could not find a config file at ${configFile.path}. Exiting...");
  }

  bool dryRun = arguments.contains('--dry');

  final String configString = configFile.readAsStringSync();
  YamlMap configContents = await loadYaml(
    configString,
    sourceUrl: configFile.uri,
  );
  final reader = Directory(configContents['entrypoint']);
  if (!reader.existsSync()) {
    throw ConfigException(
        "Could not find entrypoint directory at ${reader.path}. Exiting...");
  }

  final String packagesPath = configContents['packages_dir_name'] ?? 'packages';
  final String outputFileDirectory =
      configContents['output_file_directory'] ?? 'dist';
  final bool isSamePackagesDir =
      configContents['is_same_file_directory'] ?? false;
  final bool verbose = configContents['verbose_output'] ?? false;

  UpdateManager? updateManager;
  if (configContents.containsKey('circle_ci')) {
    if (configContents['circle_ci']['input_file_directory'] == null) {
      throw ConfigException(
          "You must provide a circle_ci input_file_directory input. Exiting...");
    }

    updateManager = CircleCiUpdateManager(
      originDirectory: reader,
      inputDirectory: configContents['circle_ci']['input_file_directory'],
      continueOutputFileDirectory: outputFileDirectory,
      dryRun: dryRun,
    );
  }

  if (updateManager == null) {
    throw ConfigException("You must configure a CI handler. Exiting...");
  }

  final MonorepoBuildTool tool = MonorepoBuildTool(
    origin: reader,
    packagesPath: packagesPath,
    isSamePackagesDir: isSamePackagesDir,
    updateManager: updateManager,
    verboseOutput: verbose,
  );

  await tool.init();
  if (dryRun) {
    print(
        'Dry run; generated files will not be written to disk.\n\nPrinting dependency graph:');
    print(tool.graph);
  } else {
    await tool.assignNewCircleCiDependencies();
  }
}
