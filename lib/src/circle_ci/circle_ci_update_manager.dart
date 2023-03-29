import 'dart:io';

import 'package:flutter_monorepo_build_tools/src/circle_ci/circle_ci_update_mapping_model.dart';
import 'package:flutter_monorepo_build_tools/src/circle_ci/models/boolean_parameter_model.dart';
import 'package:flutter_monorepo_build_tools/src/circle_ci/models/job_model.dart';
import 'package:flutter_monorepo_build_tools/src/circle_ci/models/path_filtering_filter_model.dart';
import 'package:flutter_monorepo_build_tools/src/circle_ci/models/project_yaml_config_model.dart';
import 'package:flutter_monorepo_build_tools/src/circle_ci/models/workflow_model.dart';
import 'package:flutter_monorepo_build_tools/src/graph/graph.dart';
import 'package:flutter_monorepo_build_tools/src/graph/vertex.dart';
import 'package:flutter_monorepo_build_tools/src/json/json_to_yaml_converter.dart';
import 'package:flutter_monorepo_build_tools/src/update_manager/update_manager.dart';
import 'package:flutter_monorepo_build_tools/src/yaml/yaml_ext.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

final log = Logger('CircleCI Update Manager');

class CircleCiUpdateManager extends UpdateManager {
  late final File configFile;
  late final List<String> entrypointFileNames;
  late final File configOutputFile;
  late final String inputDirectory;
  final String originDirectoryPath;
  final String continueOutputFileDirectory;
  final bool dryRun;

  CircleCiUpdateManager({
    required this.originDirectoryPath,
    required this.inputDirectory,
    required this.continueOutputFileDirectory,
    this.dryRun = false,
    required List<String> projectNames,
  }) {
    configFile = File(p.join(
      originDirectoryPath,
      inputDirectory,
      'config.yml',
    ));
    entrypointFileNames = projectNames;
    configOutputFile = File(p.join(
      originDirectoryPath,
      continueOutputFileDirectory,
      'config.yml',
    ));
  }

  @override
  Future<void> runUpdate(Graph<Directory> dependencyGraph) async {
    Map<String, dynamic> circleCiConfigContentJson =
        await _circleCiConfigFileContent;
    ProjectYamlConfigModel circleCiConfigContent =
        ProjectYamlConfigModel.fromJson(
      circleCiConfigContentJson,
    );

    for (WorkflowModel workflow in circleCiConfigContent.workflows!) {
      if (workflow.name == 'always-run') {
        // find the path-filtering/filter job and update its 'mapping' value
        for (WorkflowJob job in workflow.jobs!) {
          if (job.key == 'path-filtering/filter') {
            PathFilteringFilterModel pathFilter =
                PathFilteringFilterModel.fromJob(job);
            List<CircleCiUpdateMappingModel> allParameters =
                mapCircleCiMappingsToDart(pathFilter.mapping ?? '');
            updateMappingNodeWithNewDataIfNeeded(
              dependencyGraph,
              allParameters,
              pathFilter,
            );
            if (pathFilter.configPath != null) {
              await _updateContinueConfigFile(
                pathFilter,
                allParameters,
                dependencyGraph,
              );
            }
            job.params!['mapping'] = pathFilter.mapping;
          }
        }
      }
      if (dryRun) {
        log.info("Dry run; logging generated mapping");
        log.info(convertToYaml(circleCiConfigContent.toJson()));
      } else {
        updateNewMapping(circleCiConfigContent);
      }
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  //                           Config.Yml stuff                               //
  //////////////////////////////////////////////////////////////////////////////
  void updateMappingNodeWithNewDataIfNeeded(
    Graph<Directory> dependencyGraph,
    List<CircleCiUpdateMappingModel> allMappings,
    PathFilteringFilterModel pathFilteringFilterModel,
  ) {
    for (Vertex<Directory> fileVertex in dependencyGraph.vertices) {
      if (!allMappings.any(
        (element) => fileVertex.data.path.contains(element.relativePackagePath),
      )) {
        // remove . from split path
        List<String> splitPath =
            p.split(fileVertex.data.path).where((e) => e != '.').toList();

        allMappings.add(
          CircleCiUpdateMappingModel(
            relativePackagePath: p.joinAll(splitPath),
            packageName: splitPath[splitPath.length - 1],
          ),
        );
      }
    }
    allMappings
        .sort((a, b) => a.relativePackagePath.compareTo(b.relativePackagePath));
    pathFilteringFilterModel.mapping = allMappings
        .map((e) => e.toString())
        .fold('', (previousValue, element) => '$previousValue\n$element');
  }

  List<CircleCiUpdateMappingModel> mapCircleCiMappingsToDart(
    String mappingString,
  ) {
    List<CircleCiUpdateMappingModel> allMappings = mappingString
        .split('\n')
        .where((element) => element.isNotEmpty)
        .map((e) => CircleCiUpdateMappingModel.createRaw(e))
        .toList();
    return allMappings;
  }

  void updateNewMapping(ProjectYamlConfigModel circleCiConfigContent) {
    configOutputFile.createSync();
    configOutputFile
        .writeAsStringSync(convertToYaml(circleCiConfigContent.toJson()));
  }

  //////////////////////////////////////////////////////////////////////////////
  //                       Continue-Config.Yml stuff                          //
  //////////////////////////////////////////////////////////////////////////////
  Future<void> _updateContinueConfigFile(
    PathFilteringFilterModel filteringFilterModel,
    List<CircleCiUpdateMappingModel> allParameters,
    Graph<Directory> graph,
  ) async {
    final File continueConfigFile = File(p.join(
      originDirectoryPath,
      inputDirectory,
      filteringFilterModel.configPath!.replaceAll('.circleci/', ''),
    ));
    final Map<String, dynamic> continueConfigJson =
        await _yamlFileToJson(continueConfigFile);

    // Parameter setup
    final List<String> allParameterNames =
        allParameters.map((e) => e.parameterName).toList();
    final Map<String, BooleanParameterModel> parametersMap =
        continueConfigJson['parameters'] != null
            ? (continueConfigJson['parameters'] as Map<String, dynamic>)
                .map((key, value) => MapEntry(
                      key,
                      BooleanParameterModel.fromJson(
                        value as Map<String, dynamic>,
                      ),
                    ))
            : {};
    parametersMap.removeWhere((key, value) =>
        // if there is an old key for e.g. a package which no longer exists, remove it
        key.endsWith('_updated') && !allParameterNames.contains(key));
    for (final String parameterName in allParameterNames) {
      if (parametersMap[parameterName] == null) {
        parametersMap[parameterName] = BooleanParameterModel();
      }
    }
    continueConfigJson['parameters'] =
        parametersMap.map((key, value) => MapEntry(
              key,
              value.toJson(),
            ));

    // go through workflows and find relevant workflows to update
    Map<String, dynamic> workflowsMap =
        continueConfigJson['workflows'] ??= <String, dynamic>{};
    Map<String, WorkflowModel> workflows = workflowsMap.map((key, value) =>
        MapEntry(key, WorkflowModel.fromJson(value)..name = key));
    workflows.forEach((key, value) {
      final WhenModel whenModel;
      if (value.when is WhenModel) {
        whenModel = value.when as WhenModel;
      } else if (value.when is String) {
        value.when = WhenModel(or: [value.when as String]);
        whenModel = value.when as WhenModel;
      } else {
        return;
      }
      for (String entrypointFileName in entrypointFileNames) {
        final List<String> entrypointPermutations = [
          '$entrypointFileName-build',
          '${entrypointFileName}_build',
          'build_$entrypointFileName',
          'build-$entrypointFileName',
          '$entrypointFileName-commit',
          '${entrypointFileName}_commit',
          'commit_$entrypointFileName',
          'commit-$entrypointFileName',
          '$entrypointFileName-deploy',
          '${entrypointFileName}_deploy',
          'deploy_$entrypointFileName',
          'deploy-$entrypointFileName',
        ];
        Vertex<Directory> origin;
        if (entrypointPermutations.contains(key)) {
          origin = graph.vertices.firstWhere(
              (vertex) => p.split(vertex.data.path).last == entrypointFileName);
        } else {
          continue;
        }
        List<Vertex<Directory>> directDependencies =
            graph.edges(origin).map((e) => e.destination).toList();
        List<String> directDependenciesParameters = allParameterNames
            .where((parameter) =>
                directDependencies.any((element) {
                  List<String> splitPath = p.split(element.data.path);
                  return splitPath[splitPath.length - 1] ==
                      parameter.substring(0, parameter.indexOf('_updated'));
                }) ||
                parameter == '${entrypointFileName}_updated')
            .toList();
        whenModel.setOrParameters(directDependenciesParameters);
      }
      continueConfigJson['workflows'] =
          workflows.map((key, value) => MapEntry(key, value.toJson()));
      String yamlResult = convertToYaml(continueConfigJson);
      File outputContinueConfigFile = File(p.join(
        originDirectoryPath,
        continueOutputFileDirectory,
        filteringFilterModel.configPath!.replaceAll('.circleci/', ''),
      ));
      outputContinueConfigFile.createSync();
      outputContinueConfigFile.writeAsStringSync(yamlResult);
    });
  }
  //////////////////////////////////////////////////////////////////////////////
  //                              Initializer                                 //
  //////////////////////////////////////////////////////////////////////////////

  Future<Map<String, dynamic>> get _circleCiConfigFileContent async {
    File circleCiConfigFile = configFile;
    Map<String, dynamic> circleCiConfigContent =
        await _yamlFileToJson(circleCiConfigFile);
    return circleCiConfigContent;
  }

  Future<Map<String, dynamic>> _yamlFileToJson(File circleCiConfigFile) async {
    return ((await loadYaml(circleCiConfigFile.readAsStringSync(),
            sourceUrl: circleCiConfigFile.uri)) as YamlMap)
        .toJson();
  }
}
