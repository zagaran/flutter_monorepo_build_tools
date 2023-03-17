import 'package:flutter_monorepo_build_tools/src/circle_ci/models/workflow_model.dart';

class ProjectYamlConfigModel {
  Map<String, dynamic>? params;
  List<WorkflowModel>? workflows;

  ProjectYamlConfigModel({this.params, this.workflows});

  ProjectYamlConfigModel.fromJson(Map<String, dynamic> json) {
    workflows = (json['workflows'] != null)
        ? json['workflows']
            .keys
            .map<WorkflowModel>(
                (k) => WorkflowModel.fromJson(json['workflows'][k])..name = k)
            .toList()
        : null;
    json.remove('workflows');
    params = json;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = params ?? {};
    if (workflows != null) {
      data['workflows'] = {for (var w in workflows!) w.name: w.toJson()};
    }
    return data;
  }
}
