import 'package:monorepo_build_tool/src/circle_ci/models/always_run_model.dart';

class WorkflowsModel {
  AlwaysRunModel? alwaysRun;

  WorkflowsModel({this.alwaysRun});

  WorkflowsModel.fromJson(Map<String, dynamic> json) {
    alwaysRun = json['always-run'] != null
        ? AlwaysRunModel.fromJson(json['always-run'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (alwaysRun != null) {
      data['always-run'] = alwaysRun!.toJson();
    }
    return data;
  }
}
