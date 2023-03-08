import 'dart:io';

import 'package:flutter_monorepo_build_tools/src/circle_ci/circle_ci_update_mapping_model.dart';
import 'package:flutter_monorepo_build_tools/src/circle_ci/models/always_run_model.dart';
import 'package:flutter_monorepo_build_tools/src/circle_ci/models/boolean_parameter_model.dart';
import 'package:flutter_monorepo_build_tools/src/circle_ci/models/continue_workflow_model.dart';
import 'package:flutter_monorepo_build_tools/src/circle_ci/models/job_model.dart';
import 'package:flutter_monorepo_build_tools/src/circle_ci/models/path_filtering_filter_model.dart';
import 'package:flutter_monorepo_build_tools/src/circle_ci/models/project_yaml_config_model.dart';
import 'package:flutter_monorepo_build_tools/src/circle_ci/models/worflows_model.dart';
import 'package:flutter_monorepo_build_tools/src/graph/graph.dart';
import 'package:flutter_monorepo_build_tools/src/graph/vertex.dart';
import 'package:flutter_monorepo_build_tools/src/json/json_to_yaml_converter.dart';
import 'package:flutter_monorepo_build_tools/src/update_manager/update_manager.dart';
import 'package:flutter_monorepo_build_tools/src/yaml/yaml_ext.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

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
    configFile =
        File(p.join(originDirectoryPath, inputDirectory, 'config.yml'));
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
    final List<JobModel> allJobs = _getAllJobs(circleCiConfigContent);
    final List<JobModel> allJobsWithPathFiltering = allJobs
        .where((element) => element.pathFilteringFilter != null)
        .toList();
    for (JobModel jobModel in allJobsWithPathFiltering) {
      List<CircleCiUpdateMappingModel> allParameters =
          mapCircleCiMappingsToDart(
              jobModel.pathFilteringFilter!.mapping ?? '');
      updateMappingNodeWithNewDataIfNeeded(
        dependencyGraph,
        allParameters,
        jobModel.pathFilteringFilter!,
      );
      if (jobModel.pathFilteringFilter!.configPath != null) {
        await _updateContinueConfigFile(
          jobModel.pathFilteringFilter!,
          allParameters,
          dependencyGraph,
        );
      }
      (circleCiConfigContent.workflows?.alwaysRun?.jobs)
          ?.firstWhere((element) => element.pathFilteringFilter != null)
          .pathFilteringFilter = jobModel.pathFilteringFilter!;
    }
    if (dryRun) {
      print("Dry run; printing generated mapping");
      print(convertToYaml(circleCiConfigContent.toJson()));
    } else {
      updateNewMapping(
        circleCiConfigContent,
      );
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

  List<JobModel> _getAllJobs(ProjectYamlConfigModel circleCiConfigContent) {
    WorkflowsModel workflowsModel =
        circleCiConfigContent.workflows ?? WorkflowsModel(alwaysRun: null);
    workflowsModel.alwaysRun ??= AlwaysRunModel();
    AlwaysRunModel alwaysRunModel = workflowsModel.alwaysRun!;
    alwaysRunModel.jobs ??= [];
    return alwaysRunModel.jobs!;
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
                          value as Map<String, dynamic>),
                    ))
            : {};
    parametersMap.removeWhere((key, value) => !allParameterNames.contains(key));
    for (final String parameterName in allParameterNames) {
      if (parametersMap[parameterName] == null) {
        parametersMap[parameterName] = BooleanParameterModel();
      }
    }

    // go through workflows and find relevant workflows to update
    Map<String, dynamic> workflowsMap =
        continueConfigJson['workflows'] ??= <String, dynamic>{};
    Map<String, WorkflowModel> workflows = workflowsMap
        .map((key, value) => MapEntry(key, WorkflowModel.fromJson(value)));
    const List<String> defaultJobs = [
      'build_android',
      'build_ios',
    ];
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
        } else if (defaultJobs.contains(key)) {
          origin = graph.vertices.first;
        } else {
          continue;
        }
        List<Vertex<Directory>> directDependencies =
            graph.edges(origin).map((e) => e.destination).toList();
        List<String> directDependenciesParameters = allParameterNames
            .where((parameter) => directDependencies.any((element) {
                  List<String> splitPath = p.split(element.data.path);
                  return splitPath[splitPath.length - 1] ==
                      parameter.substring(0, parameter.indexOf('_updated'));
                }))
            .toList();
        whenModel.setOrParameters(directDependenciesParameters);
      }
      ;
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
