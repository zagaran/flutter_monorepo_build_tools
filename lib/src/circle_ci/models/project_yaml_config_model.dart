import 'package:flutter_monorepo_build_tools/src/circle_ci/models/orbs_model.dart';
import 'package:flutter_monorepo_build_tools/src/circle_ci/models/worflows_model.dart';

class ProjectYamlConfigModel {
  double? version;
  bool? setup;
  OrbsModel? orbs;
  WorkflowsModel? workflows;

  ProjectYamlConfigModel({this.version, this.setup, this.orbs, this.workflows});

  ProjectYamlConfigModel.fromJson(Map<String, dynamic> json) {
    version = json['version'];
    setup = json['setup'];
    orbs = json['orbs'] != null ? OrbsModel.fromJson(json['orbs']) : null;
    workflows = json['workflows'] != null
        ? WorkflowsModel.fromJson(json['workflows'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['version'] = version;
    data['setup'] = setup;
    if (orbs != null) {
      data['orbs'] = orbs!.toJson();
    }
    if (workflows != null) {
      data['workflows'] = workflows!.toJson();
    }
    return data;
  }
}
