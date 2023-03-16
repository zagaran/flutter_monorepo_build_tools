import 'package:flutter_monorepo_build_tools/src/circle_ci/models/job_model.dart';

class PathFilteringFilterModel {
  String? name;
  String? mapping;
  String? baseRevision;
  String? configPath;

  PathFilteringFilterModel(
      {this.name, this.mapping, this.baseRevision, this.configPath});

  PathFilteringFilterModel.fromJob(WorkflowJob job) {
    name = job.params!['name'];
    mapping = job.params!['mapping'];
    baseRevision = job.params!['base-revision'];
    configPath = job.params!['config-path'];
  }

  PathFilteringFilterModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    mapping = json['mapping'];
    baseRevision = json['base-revision'];
    configPath = json['config-path'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['mapping'] = mapping;
    data['base-revision'] = baseRevision;
    data['config-path'] = configPath;
    return data;
  }
}
